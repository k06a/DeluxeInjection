//
//  DeluxeInjection.m
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
//
//

#import "DIRuntimeRoutines.h"
#import "DeluxeInjection.h"

static void *DINothingToRestore = &DINothingToRestore;

//

static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *injectionsGettersBackup;
static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *injectionsSettersBackup;

static IMP DIInjectionsBackupRead(NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> * __strong * backup, Class class, SEL selector) {
    NSValue *value = (*backup)[class][NSStringFromSelector(selector)];
    return value.pointerValue;
}

static void DIInjectionsBackupWrite(NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> * __strong * backup, Class class, SEL selector, IMP imp) {
    if (*backup == nil) {
        *backup = [NSMutableDictionary dictionary];
    }
    
    if ((*backup)[class] == nil) {
        (*backup)[(id)class] = [NSMutableDictionary dictionary];
    }
    
    NSString *selectorKey = NSStringFromSelector(selector);
    if (!!(*backup)[class][selectorKey] != !!imp) {
        if (imp) {
            (*backup)[class][selectorKey] = [NSValue valueWithPointer:imp];
        } else {
            [(*backup)[class] removeObjectForKey:selectorKey];
            if ((*backup)[class].count == 0) {
                [(*backup) removeObjectForKey:class];
            }
        }
    }
}

static IMP DIInjectionsGettersBackupRead(Class class, SEL selector) {
    return DIInjectionsBackupRead(&injectionsGettersBackup, class, selector);
}

static void DIInjectionsGettersBackupWrite(Class class, SEL selector, IMP imp) {
    DIInjectionsBackupWrite(&injectionsGettersBackup, class, selector, imp);
}

static IMP DIInjectionsSettersBackupRead(Class class, SEL selector) {
    return DIInjectionsBackupRead(&injectionsSettersBackup, class, selector);
}

static void DIInjectionsSettersBackupWrite(Class class, SEL selector, IMP imp) {
    DIInjectionsBackupWrite(&injectionsSettersBackup, class, selector, imp);
}

//

static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSHashTable *> *> *associates;

static NSArray *DIAssociatesRead(Class class, SEL getter) {
    NSHashTable *hashTable = associates[class][NSStringFromSelector(getter)];
    return hashTable.allObjects;
}

static void DIAssociatesWrite(Class class, SEL getter, id object) {
    if (associates == nil) {
        associates = [NSMutableDictionary dictionary];
    }
    
    if (associates[class] == nil) {
        associates[(id)class] = [NSMutableDictionary dictionary];
    }
    
    NSString *selectorKey = NSStringFromSelector(getter);
    if (associates[class][selectorKey] == nil) {
        associates[class][selectorKey] = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsOpaquePersonality];
    }
    
    if (object) {
        [associates[class][selectorKey] addObject:object];
    }
}

static void DIAssociatesRemove(Class class, SEL getter) {
    NSString *selectorKey = NSStringFromSelector(getter);
    [associates[class] removeObjectForKey:selectorKey];
}

//

DIGetter DIGetterMake(DIGetter getter) {
    return getter;
}

DISetter DISetterMake(DISetter setter) {
    return setter;
}

DIGetter DIGetterIfIvarIsNil(DIGetterWithoutIvar getter) {
    return ^id(id target, id *ivar) {
        if (*ivar == nil) {
            *ivar = getter(target);
        }
        return *ivar;
    };
}

id DIGetterSuperCall(id target, Class class, SEL getter) {
    struct objc_super mySuper = {
        .receiver = target,
        .super_class = class_isMetaClass(object_getClass(target))
                     ? object_getClass([class superclass])
                     : [class superclass],
    };
    id (*objc_superAllocTyped)(struct objc_super *, SEL) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, getter);
}

void DISetterSuperCall(id target, Class class, SEL getter, id value) {
    struct objc_super mySuper = {
        .receiver = target,
        .super_class = class_isMetaClass(object_getClass(target))
                     ? object_getClass([class superclass])
                     : [class superclass],
    };
    void (*objc_superAllocTyped)(struct objc_super *, SEL, id) = (void *)&objc_msgSendSuper;
    (*objc_superAllocTyped)(&mySuper, getter, value);
}

//

@implementation DeluxeInjection

#pragma mark - Sample getter and setter

- (id)getterExample {
    return nil;
}

- (void)setterExample:(id)value {
    return;
}

#pragma mark - Private

+ (void)enumerateAllClassProperties:(void(^)(Class class, objc_property_t property))block conformingProtocol:(Protocol *)protocol {
    NSString *protocol_str = [NSString stringWithFormat:@"<%@>", NSStringFromProtocol(protocol)];
    DIRuntimeEnumerateClasses(^(Class class) {
        DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
            NSString *type = DIRuntimeGetPropertyAttribute(property, "T");
            if (!protocol || [type rangeOfString:protocol_str].location != NSNotFound) {
                block(class, property);
            }
        });
    });
}

+ (void)inject:(Class)class property:(objc_property_t)property getterBlock:(DIGetter)getterBlock setterBlock:(DISetter)setterBlock blockFactory:(DIPropertyBlock)blockFactory {
    __block DIGetter getterToInject = getterBlock;
    __block DISetter setterToInject = setterBlock;
    
    DIRuntimeGetPropertyType(property, ^(Class propertyClass, NSSet<Protocol *> * propertyProtocols) {
        SEL getter = DIRuntimeGetPropertyGetter(property);
        SEL setter = DIRuntimeGetPropertySetter(property);
        
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        if (blockFactory) {
            NSArray *blocks = blockFactory(class, getter, setter, propertyName, propertyClass, propertyProtocols);
            if (blocks.firstObject && blocks.firstObject != [DeluxeInjection doNotInject]) {
                getterToInject = blocks.firstObject;
            }
            if (blocks.lastObject && blocks.lastObject != [DeluxeInjection doNotInject]) {
                setterToInject = blocks.lastObject;
            }
            if (!getterToInject && !setterToInject) {
                return;
            }
        }
        
        NSString *propertyIvarStr = DIRuntimeGetPropertyAttribute(property, "V");
        Ivar propertyIvar = propertyIvarStr ? class_getInstanceVariable(class, propertyIvarStr.UTF8String) : nil;
        NSString *key = propertyIvar ? [NSString stringWithUTF8String:ivar_getName(propertyIvar)] : nil;
        
        BOOL associationNeeded = (key == nil);
        SEL associationKey = NSSelectorFromString([@"di_" stringByAppendingString:propertyName]);
        objc_AssociationPolicy associationPolicy = DIRuntimePropertyAssociationPolicy(property);
        
        id (^newGetterBlock)(id) = nil;
        if (getterToInject) {
            if (!associationNeeded) {
                newGetterBlock = ^id(id target){
                    id ivar = [target valueForKey:key];
                    __weak id oldIvar = ivar;
                    id result = getterToInject(target, &ivar);
                    if (ivar != oldIvar) {
                        [target setValue:ivar forKey:key];
                    }
                    return result;
                };
            } else {
                newGetterBlock = ^id(id target){
                    id ivar = objc_getAssociatedObject(target, associationKey);
                    BOOL ivarWasNil = (ivar == nil);
                    id result = getterToInject(target, &ivar);
                    if (ivar && ivarWasNil) {
                        DIAssociatesWrite(class, getter, target);
                    }
                    objc_setAssociatedObject(target, associationKey, ivar, associationPolicy);
                    return result;
                };
            }
        }
        
        void (^newSetterBlock)(id,id) = nil;
        if (setterToInject) {
            if (!associationNeeded) {
                newSetterBlock = ^void(id target, id newValue){
                    id ivar = [target valueForKey:key];
                    setterToInject(target, &ivar, newValue);
                    [target setValue:ivar forKey:key];
                };
            } else {
                newSetterBlock = ^void(id target, id newValue){
                    id ivar = objc_getAssociatedObject(target, associationKey);
                    BOOL ivarWasNil = (ivar == nil);
                    setterToInject(target, &ivar, newValue);
                    if (ivar && ivarWasNil) {
                        DIAssociatesWrite(class, getter, target);
                    }
                    objc_setAssociatedObject(target, associationKey, ivar, associationPolicy);
                };
            }
        }
        
        if (getterToInject) {
            IMP newGetterImp = imp_implementationWithBlock(newGetterBlock);
            Method getterMethod = class_getInstanceMethod(class, getter);
            const char *getterTypes = method_getTypeEncoding(getterMethod);
            IMP getterMethodImp = method_getImplementation(getterMethod);
            DIInjectionsGettersBackupWrite(class, getter, getterMethodImp ?: (IMP)DINothingToRestore);
            IMP replacedGetterImp = class_replaceMethod(class, getter, newGetterImp, getterTypes);
            if (associationNeeded) {
                imp_removeBlock(replacedGetterImp);
            }
        }
        
        // If need association and not have setter so we need implement simple setter
        if (associationNeeded && !newSetterBlock) {
            newSetterBlock = ^void(id target, id newValue) {
                objc_setAssociatedObject(target, associationKey, newValue, associationPolicy);
            };
        }
        
        if (newSetterBlock) {
            IMP newSetterImp = imp_implementationWithBlock(newSetterBlock);
            Method setterMethod = class_getInstanceMethod(self, setter);
            const char *setterTypes = method_getTypeEncoding(setterMethod);
            IMP setterMethodImp = method_getImplementation(setterMethod);
            DIInjectionsSettersBackupWrite(class, setter, setterMethodImp ?: (IMP)DINothingToRestore);
            IMP replacedSetterImp = class_replaceMethod(class, setter, newSetterImp, setterTypes);
            if (associationNeeded) {
                imp_removeBlock(replacedSetterImp);
            }
        }
    });
}

+ (void)inject:(DIPropertyBlock)block conformingProtocol:(Protocol *)protocol {
    [self enumerateAllClassProperties:^(Class class, objc_property_t property) {
        [self inject:class property:property getterBlock:nil setterBlock:nil blockFactory:block];
    } conformingProtocol:protocol];
}

+ (void)reject:(Class)class property:(objc_property_t)property {
    // Restore or remove getter
    SEL getter = DIRuntimeGetPropertyGetter(property);
    IMP getterImp = DIInjectionsGettersBackupRead(class, getter);
    if (getterImp && getterImp != DINothingToRestore) {
        Method method = class_getInstanceMethod(class, getter);
        const char *types = method_getTypeEncoding(method);
        IMP replacedImp = class_replaceMethod(class, getter, getterImp, types);
        imp_removeBlock(replacedImp);
    }
    else if (getterImp == DINothingToRestore) {
        id (^newGetterBlock)(id) = ^id(id target) {
            [target doesNotRecognizeSelector:getter];
            return nil;
        };
        
        IMP newGetterImp = imp_implementationWithBlock(newGetterBlock);
        Method getterMethod = class_getInstanceMethod(self, @selector(getterExample));
        const char *getterTypes = method_getTypeEncoding(getterMethod);
        IMP replacedImp = class_replaceMethod(class, getter, newGetterImp, getterTypes);
        imp_removeBlock(replacedImp);
    }
    DIInjectionsGettersBackupWrite(class, getter, nil);
    
    // Restore or remove setter
    SEL setter = DIRuntimeGetPropertySetter(property);
    IMP setterImp = DIInjectionsSettersBackupRead(class, setter);
    if (setterImp && setterImp != DINothingToRestore) {
        Method method = class_getInstanceMethod(class, setter);
        const char *types = method_getTypeEncoding(method);
        IMP replacedImp = class_replaceMethod(class, setter, getterImp, types);
        imp_removeBlock(replacedImp);
    }
    else if (setterImp == DINothingToRestore) {
        void (^newSetterBlock)(id,id) = ^void(id target, id newValue) {
            [target doesNotRecognizeSelector:setter];
        };
        
        IMP newSetterImp = imp_implementationWithBlock(newSetterBlock);
        Method setterMethod = class_getInstanceMethod(self, @selector(setterExample:));
        const char *setterTypes = method_getTypeEncoding(setterMethod);
        IMP replacedImp = class_replaceMethod(class, setter, newSetterImp, setterTypes);
        imp_removeBlock(replacedImp);
    }
    DIInjectionsSettersBackupWrite(class, setter, nil);
    
    // Remove association
    NSArray *associated = DIAssociatesRead(class, getter);
    if (associated) {
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        SEL associationKey = NSSelectorFromString([@"di_" stringByAppendingString:propertyName]);
        objc_AssociationPolicy associationPolicy = DIRuntimePropertyAssociationPolicy(property);
        for (id object in associated) {
            objc_setAssociatedObject(object, associationKey, nil, associationPolicy);
        }
        DIAssociatesRemove(class, getter);
    }
}

+ (void)reject:(DIPropertyFilter)block conformingProtocol:(Protocol *)protocol {
    [self enumerateAllClassProperties:^(Class class, objc_property_t property) {
        DIRuntimeGetPropertyType(property, ^(Class propertyClass, NSSet<Protocol *> * propertyProtocols) {
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            if (block(class, propertyName, propertyClass, propertyProtocols)) {
                SEL getter = DIRuntimeGetPropertyGetter(property);
                [self reject:class getter:getter];
            }
        });
    } conformingProtocol:protocol];
}

#pragma mark - Public

+ (id)doNotInject {
    static id doNotInject;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        doNotInject = [NSObject new];
    });
    return doNotInject;
}

+ (BOOL)checkInjected:(Class)class getter:(SEL)getter {
    return DIInjectionsGettersBackupRead(class, getter) != nil;
}

+ (void)inject:(Class)class getter:(SEL)getter getterBlock:(DIGetter)getterBlock {
    DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
        SEL propertyGetter = DIRuntimeGetPropertyGetter(property);
        if (getter == propertyGetter) {
            [self inject:class property:property getterBlock:getterBlock setterBlock:nil blockFactory:nil];
        }
    });
}

+ (void)inject:(Class)class setter:(SEL)setter setterBlock:(DISetter)setterBlock {
    DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
        SEL propertySetter = DIRuntimeGetPropertySetter(property);
        if (setter == propertySetter) {
            [self inject:class property:property getterBlock:nil setterBlock:setterBlock blockFactory:nil];
        }
    });
}

+ (void)reject:(Class)class getter:(SEL)getter {
    if (!DIInjectionsGettersBackupRead(class, getter)) {
        return;
    }
    
    DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
        if (getter == DIRuntimeGetPropertyGetter(property)) {
            [self reject:class property:property];
        }
    });
}

+ (NSString *)debugDescription {
    return [[super description] stringByAppendingString:^{
        NSMutableString *str = [NSMutableString stringWithString:@" injected:\n"];
        for (Class class in injectionsGettersBackup) {
            [str appendFormat:@"%@ properties to class %@:\n", @(injectionsGettersBackup[class].count), class];
            NSInteger i = 1;
            for (NSString *selStr in injectionsGettersBackup[class]) {
                NSArray *objects = DIAssociatesRead(class, NSSelectorFromString(selStr));
                if (objects) {
                    [str appendFormat:@"\t%@. @selector(%@) associated with %@ object(s)\n", @(i++), selStr, @(objects.count)];
                } else {
                    [str appendFormat:@"\t%@. @selector(%@)\n", @(i++), selStr];
                }
            }
        }
        return str;
    }()];
}

@end
