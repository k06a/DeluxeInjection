//
//  DeluxeInjection.m
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
//
//

#import "DIRuntimeRoutines.h"
#import "DeluxeInjection.h"

static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *injectionsBackup;

static IMP DIInjectionsBackupRead(Class class, SEL selector) {
    NSValue *value = injectionsBackup[class][NSStringFromSelector(selector)];
    return value.pointerValue;
}

static void DIInjectionsBackupWrite(Class class, SEL selector, IMP imp) {
    if (injectionsBackup == nil) {
        injectionsBackup = [NSMutableDictionary dictionary];
    }
    if (injectionsBackup[class] == nil) {
        injectionsBackup[(id)class] = [NSMutableDictionary dictionary];
    }
    
    NSString *selectorKey = NSStringFromSelector(selector);
    if (!!injectionsBackup[class][selectorKey] != !!imp) {
        if (imp) {
            injectionsBackup[class][selectorKey] = [NSValue valueWithPointer:imp];
        } else {
            [injectionsBackup[class] removeObjectForKey:selectorKey];
            if (injectionsBackup[class].count == 0) {
                [injectionsBackup removeObjectForKey:class];
            }
        }
    }
}

//

static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSHashTable *> *> *associates;

static NSArray *DIAssociatesRead(Class class, SEL selector) {
    NSHashTable *hashTable = associates[class][NSStringFromSelector(selector)];
    return hashTable.allObjects;
}

static void DIAssociatesWrite(Class class, SEL selector, id object) {
    if (associates == nil) {
        associates = [NSMutableDictionary dictionary];
    }
    if (associates[class] == nil) {
        associates[(id)class] = [NSMutableDictionary dictionary];
    }
    
    NSString *selectorKey = NSStringFromSelector(selector);
    if (associates[class][selectorKey] == nil) {
        associates[class][selectorKey] = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsOpaquePersonality];
    }
    
    if (object) {
        [associates[class][selectorKey] addObject:object];
    }
}

static void DIAssociatesRemove(Class class, SEL selector) {
    NSString *selectorKey = NSStringFromSelector(selector);
    [associates[class] removeObjectForKey:selectorKey];
}

//

DIGetter DIGetterIfIvarIsNil(DIGetterWithoutIvar getter) {
    return ^id(id self, SEL _cmd, id *ivar) {
        if (*ivar == nil) {
            *ivar = getter(self, _cmd);
        }
        return *ivar;
    };
}

//

@implementation DeluxeInjection

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

+ (void)inject:(Class)class property:(objc_property_t)property block:(DIGetter)block blockFactory:(DIPropertyGetterBlock)blockFactory {
    __block DIGetter blockToInject = block;
    
    DIRuntimeGetPropertyType(property, ^(Class propertyClass, NSSet<Protocol *> * propertyProtocols) {
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        if (blockFactory) {
            blockToInject = blockFactory(class, propertyName, propertyClass, propertyProtocols);
            if (!blockToInject) {
                return;
            }
        }
        
        SEL getter = DIRuntimeGetPropertyGetter(property);
        Method getterMethod = class_getInstanceMethod(class, getter);
        IMP getterMethodImp = method_getImplementation(getterMethod);
        
        NSString *propertyIvarStr = DIRuntimeGetPropertyAttribute(property, "V");
        Ivar propertyIvar = propertyIvarStr ? class_getInstanceVariable(class, propertyIvarStr.UTF8String) : nil;
        NSString *key = propertyIvar ? [NSString stringWithUTF8String:ivar_getName(propertyIvar)] : nil;
        
        SEL associationKey = NSSelectorFromString([@"di_" stringByAppendingString:propertyName]);
        objc_AssociationPolicy associationPolicy = DIRuntimePropertyAssociationPolicy(property);
        
        id (^newGetterBlock)(id,SEL) = ^id(id self, SEL _cmd){
            id ivar = nil;
            if (key) {
                ivar = [self valueForKey:key];
            } else {
                ivar = objc_getAssociatedObject(self, associationKey);
            }
            blockToInject(self, _cmd, &ivar);
            if (key) {
                [self setValue:ivar forKey:key];
            } else {
                DIAssociatesWrite(class, getter, self);
                objc_setAssociatedObject(self, associationKey, ivar, associationPolicy);
            }
            return ivar;
        };
        
        IMP newImp = imp_implementationWithBlock(newGetterBlock);
        const char *types = method_getTypeEncoding(getterMethod);
        DIInjectionsBackupWrite(class, getter, getterMethodImp);
        class_replaceMethod(class, getter, newImp, types);
    });
}

+ (void)inject:(DIPropertyGetterBlock)block conformingProtocol:(Protocol *)protocol {
    [self enumerateAllClassProperties:^(Class class, objc_property_t property) {
        [self inject:class property:property block:nil blockFactory:block];
    } conformingProtocol:protocol];
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

+ (BOOL)checkInjected:(Class)class getter:(SEL)getter {
    return DIInjectionsBackupRead(class, getter) != nil;
}

+ (void)inject:(Class)class getter:(SEL)getter block:(DIGetter)block {
    DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
        SEL propertyGetter = DIRuntimeGetPropertyGetter(property);
        if (getter == propertyGetter) {
            [self inject:class property:property block:block blockFactory:nil];
        }
    });
}

+ (void)reject:(Class)class getter:(SEL)getter {
    if (!DIInjectionsBackupRead(class, getter)) {
        return;
    }
    
    DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
        if (getter == DIRuntimeGetPropertyGetter(property)) {
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            SEL associationKey = NSSelectorFromString([@"di_" stringByAppendingString:propertyName]);
            objc_AssociationPolicy associationPolicy = DIRuntimePropertyAssociationPolicy(property);
            for (id object in DIAssociatesRead(class, getter)) {
                objc_setAssociatedObject(object, associationKey, nil, associationPolicy);
            }
            DIAssociatesRemove(class, getter);
        }
    });
    
    Method method = class_getInstanceMethod(class, getter);
    const char *types = method_getTypeEncoding(method);
    IMP oldImp = DIInjectionsBackupRead(class, getter);
    DIInjectionsBackupWrite(class, getter, nil);
    class_replaceMethod(class, getter, oldImp, types);
}


+ (void)inject:(DIPropertyGetter)block {
    [self inject:^DIGetter (Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return DIGetterIfIvarIsNil(^id(id self, SEL _cmd) {
            return block(targetClass, propertyName, propertyClass, propertyProtocols);
        });
    } conformingProtocol:@protocol(DIInject)];
}

+ (void)injectBlock:(DIPropertyGetterBlock)block {
    [self inject:block conformingProtocol:@protocol(DIInject)];
}

+ (void)forceInject:(DIPropertyGetter)block {
    [self inject:^DIGetter (Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return DIGetterIfIvarIsNil(^id(id self, SEL _cmd) {
            return block(targetClass, propertyName, propertyClass, propertyProtocols);
        });
    } conformingProtocol:nil];
}

+ (void)forceInjectBlock:(DIPropertyGetterBlock)block {
    [self inject:block conformingProtocol:nil];
}

+ (void)reject:(DIPropertyFilter)block {
    [self reject:block conformingProtocol:@protocol(DIInject)];
}

+ (void)rejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIInject)];
}

+ (void)forceReject:(DIPropertyFilter)block {
    [self reject:block conformingProtocol:nil];
}

+ (void)forceRejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:nil];
}

+ (void)lazyInject {
    [self inject:^DIGetter (id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return DIGetterIfIvarIsNil(^id(id self, SEL _cmd) {
            return [[propertyClass alloc] init];
        });
    } conformingProtocol:@protocol(DILazy)];
}

+ (void)lazyReject {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DILazy)];
}

+ (NSString *)debugDescription {
    return [[super description] stringByAppendingString:^{
        NSMutableString *str = [NSMutableString stringWithString:@" injected:\n"];
        for (Class class in injectionsBackup) {
            [str appendFormat:@"%@ properties to class %@:\n", @(injectionsBackup[class].count), class];
            NSInteger i = 0;
            for (NSString *selStr in injectionsBackup[class]) {
                [str appendFormat:@"\t#%@ @selector(%@)\n", @(i++), selStr];
            }
        }
        return str;
    }()];
}

@end
