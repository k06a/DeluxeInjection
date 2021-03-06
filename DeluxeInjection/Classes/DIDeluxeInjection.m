//
//  DeluxeInjection.m
//  DeluxeInjection
//
//  Copyright (c) 2016 Anton Bukov <k06aaa@gmail.com>
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <objc/message.h>

#import <RuntimeRoutines/RuntimeRoutines.h>

#import "DIDeluxeInjection.h"

//

static void *DINothingToRestore = &DINothingToRestore;

//

static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *injectionsGettersBackup;
static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *injectionsSettersBackup;

static IMP DIInjectionsBackupRead(NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *__strong *backup, Class class, SEL selector) {
    NSValue *value = (*backup)[class][NSStringFromSelector(selector)];
    return value.pointerValue;
}

static BOOL DIInjectionsBackupWrite(NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSValue *> *> *__strong *backup, Class class, SEL selector, IMP imp) {
    NSString *selectorKey = NSStringFromSelector(selector);
    if (!!(*backup)[class][selectorKey] != !!imp) {
        if (imp) {
            if (*backup == nil) {
                *backup = [NSMutableDictionary dictionary];
            }
            
            if ((*backup)[class] == nil) {
                (*backup)[(id) class] = [NSMutableDictionary dictionary];
            }

            (*backup)[class][selectorKey] = [NSValue valueWithPointer:imp];
        }
        else {
            [(*backup)[class] removeObjectForKey:selectorKey];
            if ((*backup)[class].count == 0) {
                [(*backup) removeObjectForKey:class];
            }
            if ((*backup).count == 0) {
                *backup = nil;
            }
        }
        return YES;
    }
    
    return NO;
}

static IMP DIInjectionsGettersBackupRead(Class class, SEL selector) {
    return DIInjectionsBackupRead(&injectionsGettersBackup, class, selector);
}

static BOOL DIInjectionsGettersBackupWrite(Class class, SEL selector, IMP imp) {
    return DIInjectionsBackupWrite(&injectionsGettersBackup, class, selector, imp);
}

static IMP DIInjectionsSettersBackupRead(Class class, SEL selector) {
    return DIInjectionsBackupRead(&injectionsSettersBackup, class, selector);
}

static BOOL DIInjectionsSettersBackupWrite(Class class, SEL selector, IMP imp) {
    return DIInjectionsBackupWrite(&injectionsSettersBackup, class, selector, imp);
}

//

static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSHashTable *> *> *associates;
static NSMutableDictionary<Class, NSMutableDictionary<NSString *, NSHashTable *> *> *associatesUnsafe;

static NSArray *DIAssociatesRead(Class class, SEL getter) {
    NSHashTable *hashTable = associates[class][NSStringFromSelector(getter)];
    return hashTable.allObjects;
}

static void DIAssociatesWrite(Class class, SEL getter, id object) {
    if (associates == nil) {
        associates = [NSMutableDictionary dictionary];
        associatesUnsafe = [NSMutableDictionary dictionary];
    }

    if (associates[(id) class] == nil) {
        associates[(id) class] = [NSMutableDictionary dictionary];
        associatesUnsafe[(id) class] = [NSMutableDictionary dictionary];
    }

    NSString *selectorKey = NSStringFromSelector(getter);
    if (associates[class][selectorKey] == nil) {
        associates[class][selectorKey] = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsOpaquePersonality];
        associatesUnsafe[class][selectorKey] = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality];
    }

    if (object) {
        if (![associatesUnsafe[class][selectorKey] containsObject:object]) {
            [associates[class][selectorKey] addObject:object];
            [associatesUnsafe[class][selectorKey] addObject:object];
        }
    }
}

static void DIAssociatesRemove(Class class, SEL getter) {
    NSString *selectorKey = NSStringFromSelector(getter);
    [associates[class] removeObjectForKey:selectorKey];
    [associatesUnsafe[class] removeObjectForKey:selectorKey];
}

//

DIGetter DIGetterMake(DIGetterWithoutOriginal getter) {
    return DIGetterWithOriginalMake(^id _Nullable(id  _Nonnull target, SEL cmd, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nullable (* _Nullable originalGetter)(id  _Nonnull __strong, SEL _Nonnull)) {
        return getter(target, cmd, ivar);
    });
}

DISetter DISetterMake(DISetterWithoutOriginal setter) {
    return DISetterWithOriginalMake(^(id  _Nonnull target, SEL cmd, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nonnull value, void (* _Nullable originalSetter)(id  _Nonnull __strong, SEL _Nonnull, id  _Nullable __strong)) {
        return setter(target, cmd, ivar, value);
    });
}

DIGetter DIGetterWithOriginalMake(DIGetter getter) {
    return [getter copy];
}

DISetter DISetterWithOriginalMake(DISetter setter) {
    return [setter copy];
}

DIGetter DIGetterIfIvarIsNil(DIGetterWithoutIvar getter) {
    return DIGetterWithOriginalMake(^id _Nullable(id  _Nonnull target, SEL cmd, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nullable (* _Nullable originalGetter)(id  _Nonnull __strong, SEL _Nonnull)) {
        if (*ivar == nil) {
            *ivar = getter(target, cmd);
        }
        return *ivar;
    });
}

DIGetter DIGetterIfIvarIsNilOnce(DIGetterWithoutIvar getter) {
    __block NSMapTable *targets = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality valueOptions:NSPointerFunctionsStrongMemory];
    return DIGetterWithOriginalMake(^id _Nullable(id  _Nonnull target, SEL cmd, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nullable (* _Nullable originalGetter)(id  _Nonnull __strong, SEL _Nonnull)) {
        if (*ivar == nil) {
            NSMutableSet *cmds = [targets objectForKey:target];
            if (cmds == nil) {
                cmds = [NSMutableSet set];
                [targets setObject:cmds forKey:target];
            }
            
            NSString *cmdStr = NSStringFromSelector(cmd);
            if (![cmds containsObject:cmdStr]) {
                *ivar = getter(target, cmd);
                [cmds addObject:cmdStr];
            }
        }
        return *ivar;
    });
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

void DISetterSuperCall(id target, Class class, SEL setter, id value) {
    struct objc_super mySuper = {
        .receiver = target,
        .super_class = class_isMetaClass(object_getClass(target))
                           ? object_getClass([class superclass])
                           : [class superclass],
    };
    void (*objc_superAllocTyped)(struct objc_super *, SEL, id) = (void *)&objc_msgSendSuper;
    (*objc_superAllocTyped)(&mySuper, setter, value);
}

//

@interface DIWeakWrapper : NSObject {
@public
    __weak id object;
}

@end

@implementation DIWeakWrapper

@end

//

@interface DeluxeInjection ()

@property (strong, nonatomic) id exampleProperty;

@end

@implementation DeluxeInjection

#pragma mark - Sample getter and setter

IMP EmptyMethodImp(){
    static IMP emptyGetterImp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emptyGetterImp = class_getMethodImplementation([NSObject class], NSSelectorFromString(@"bool"));
    });
    return emptyGetterImp;
}

#pragma mark - Private

+ (void)enumerateAllClassProperties:(void (^)(Class class, objc_property_t property))block conformingProtocols:(NSArray<Protocol *> *)protocols {
    NSMutableArray *protocolStrs = [NSMutableArray array];
    for (Protocol *protocol in protocols) {
        [protocolStrs addObject:[NSString stringWithFormat:@"<%@>", NSStringFromProtocol(protocol)]];
    }
    
    RRClassEnumerateAllClasses(YES, ^(Class klass) {
        RRClassEnumerateProperties(klass, ^(objc_property_t property) {
            const char *type = property_getAttributes(property);
            BOOL found = NO;
            if (strstr(type, "<DI")) {
                for (NSString *protoStr in protocolStrs) {
                    if (type && strstr(type, protoStr.UTF8String)) {
                        found = YES;
                        break;
                    }
                }
            }
            if (!protocols || found) {
                block(klass, property);
            }
        });
    });
}

+ (void)inject:(Class)klass property:(objc_property_t)property getterBlock:(DIGetter)getterBlock setterBlock:(DISetter)setterBlock blockFactory:(DIPropertyBlock)blockFactory {
    __block DIGetter getterToInject = getterBlock;
    __block DISetter setterToInject = setterBlock;

    RRPropertyGetClassAndProtocols(property, ^(Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        SEL getter = RRPropertyGetGetter(property);
        SEL setter = RRPropertyGetSetter(property);

        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        if (blockFactory) {
            NSArray *blocks = blockFactory(klass, getter, setter, propertyName, propertyClass, propertyProtocols);
            NSAssert(blocks == nil || blocks == [DeluxeInjection doNotInject] ||
                     ([blocks isKindOfClass:[NSArray class]] && blocks.count == 2),
                     @"Provide nil, [DeluxeInjection doNotInject] or array with getter and setter blocks");

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

        Method getterMethod = class_getInstanceMethod(klass, getter);
        if (getterMethod) {
            NSAssert(RRMethodGetArgumentsCount(getterMethod) == 0,
                     @"Getter should not have any arguments");
            NSAssert([RRMethodGetReturnType(getterMethod) isEqualToString:@"@"],
                     @"DeluxeInjection do not support non-object properties injections");
        }

        Method setterMethod = class_getInstanceMethod(klass, setter);
        if (setterMethod) {
            NSAssert([RRMethodGetReturnType(setterMethod) isEqualToString:@"v"],
                     @"Setter should return void");
            NSAssert(RRMethodGetArgumentsCount(setterMethod) == 1,
                     @"Setter should have exactly one argument");
            NSAssert([RRMethodGetArgumentType(setterMethod, 0) isEqualToString:@"@"],
                     @"DeluxeInjection do not support non-object properties injections");
        }
        
        DIOriginalGetter originalGetterIMP = (DIOriginalGetter)(DIInjectionsGettersBackupRead(klass, getter) ?: method_getImplementation(getterMethod));
        DIOriginalSetter originalSetterIMP = (DIOriginalSetter)(DIInjectionsSettersBackupRead(klass, setter) ?: method_getImplementation(setterMethod));
        if (originalGetterIMP == DINothingToRestore) {
            originalGetterIMP = nil;
        }
        if (originalSetterIMP == DINothingToRestore) {
            originalSetterIMP = nil;
        }
        
        NSString *propertyIvarStr = RRPropertyGetAttribute(property, "V");
        Ivar propertyIvar = propertyIvarStr ? class_getInstanceVariable(klass, propertyIvarStr.UTF8String) : nil;
        
        BOOL haveIvar = (propertyIvar != nil);
        BOOL originalGetterExist = class_getMethodImplementation(klass, getter) != EmptyMethodImp();
        BOOL originalSetterExist = class_getMethodImplementation(klass, setter) != EmptyMethodImp();
        BOOL useOriginalAccessors = (originalGetterExist && originalSetterExist);
        if (!originalGetterExist) {
            originalGetterIMP = nil;
        }
        if (!originalSetterExist) {
            originalSetterIMP = nil;
        }
        SEL associationKey = NSSelectorFromString([@"DI_" stringByAppendingString:propertyName]);
        objc_AssociationPolicy associationPolicy = RRPropertyGetAssociationPolicy(property);
        BOOL isWeak = RRPropertyGetIsWeak(property);

        id (^newGetterBlock)(id) = nil;
        if (getterToInject) {
            if (haveIvar) {
                newGetterBlock = ^id(id target) {
                    id ivar = object_getIvar(target, propertyIvar);
                    id ivar2 = ivar;
                    id result = getterToInject(target, getter, &ivar, originalGetterIMP);
                    if (ivar != ivar2) {
                        object_setIvar(target, propertyIvar, ivar);
                    }
                    return result;
                };
            }
            else {
                if (isWeak) {
                    newGetterBlock = ^id(id target) {
                        id ivar = nil;
                        DIWeakWrapper *wrapper = nil;
                        BOOL wrapperWasNil = NO;
                        if (useOriginalAccessors) {
                            ivar = originalGetterIMP(target, getter);
                        }
                        else {
                            wrapper = objc_getAssociatedObject(target, associationKey);
                            wrapperWasNil = (wrapper == nil);
                            if (wrapperWasNil) {
                                wrapper = [[DIWeakWrapper alloc] init];
                            }
                            ivar = ((DIWeakWrapper *)wrapper)->object;
                        }
                        
                        id ivar2 = ivar;
                        BOOL ivarWasNil = (ivar == nil);
                        id result = getterToInject(target, getter, &ivar, originalGetterIMP);
                        if (ivar && ivarWasNil) {
                            DIAssociatesWrite(klass, getter, target);
                        }
                        
                        if (ivar != ivar2) {
                            if (!useOriginalAccessors) {
                                wrapper->object = ivar;
                                if (wrapperWasNil) {
                                    objc_setAssociatedObject(target, associationKey, wrapper, associationPolicy);
                                }
                            }
                            if (originalSetterIMP) {
                                originalSetterIMP(target, setter, ivar);
                            }
                        }
                        return result;
                    };
                }
                else {
                    newGetterBlock = ^id(id target) {
                        id ivar = nil;
                        if (useOriginalAccessors) {
                            ivar = originalGetterIMP(target, getter);
                        }
                        else {
                            ivar = objc_getAssociatedObject(target, associationKey);
                        }
                        
                        id ivar2 = ivar;
                        BOOL ivarWasNil = (ivar == nil);
                        id result = getterToInject(target, getter, &ivar, originalGetterIMP);
                        if (ivar && ivarWasNil) {
                            DIAssociatesWrite(klass, getter, target);
                        }
                        
                        if (ivar != ivar2) {
                            if (!useOriginalAccessors) {
                                objc_setAssociatedObject(target, associationKey, ivar, associationPolicy);
                            }
                            if (originalSetterIMP) {
                                originalSetterIMP(target, setter, ivar);
                            }
                        }
                        return result;
                    };
                }
            }
        }

        void (^newSetterBlock)(id, id) = nil;
        if (setterToInject) {
            if (haveIvar) {
                newSetterBlock = ^void(id target, id newValue) {
                    id ivar = object_getIvar(target, propertyIvar);
                    setterToInject(target, setter, &ivar, newValue, originalSetterIMP);
                    object_setIvar(target, propertyIvar, ivar);
                };
            }
            else {
                if (isWeak) {
                    newSetterBlock = ^void(id target, id newValue) {
                        id ivar = nil;
                        DIWeakWrapper *wrapper = nil;
                        BOOL wrapperWasNil = NO;
                        if (useOriginalAccessors) {
                            ivar = originalGetterIMP(target, getter);
                        }
                        else {
                            wrapper = objc_getAssociatedObject(target, associationKey);
                            wrapperWasNil = (wrapper == nil);
                            if (wrapperWasNil) {
                                wrapper = [[DIWeakWrapper alloc] init];
                            }
                            ivar = wrapper->object;
                        }
                        
                        BOOL ivarWasNil = (ivar == nil);
                        setterToInject(target, setter, &ivar, newValue, originalSetterIMP);
                        if (ivar && ivarWasNil) {
                            DIAssociatesWrite(klass, getter, target);
                        }
                        
                        if (!useOriginalAccessors) {
                            wrapper->object = ivar;
                            if (wrapperWasNil) {
                                objc_setAssociatedObject(target, associationKey, wrapper, associationPolicy);
                            }
                        }
                        if (originalSetterIMP) {
                            originalSetterIMP(target, setter, ivar);
                        }
                    };
                }
                else {
                    newSetterBlock = ^void(id target, id newValue) {
                        id ivar = nil;
                        if (useOriginalAccessors) {
                            ivar = originalGetterIMP(target, getter);
                        }
                        else {
                            ivar = objc_getAssociatedObject(target, associationKey);
                        }
                        
                        BOOL ivarWasNil = (ivar == nil);
                        setterToInject(target, setter, &ivar, newValue, originalSetterIMP);
                        if (ivar && ivarWasNil) {
                            DIAssociatesWrite(klass, getter, target);
                        }
                        
                        if (!useOriginalAccessors) {
                            objc_setAssociatedObject(target, associationKey, ivar, associationPolicy);
                        }
                        if (originalSetterIMP) {
                            originalSetterIMP(target, setter, ivar);
                        }
                    };
                }
            }
        }

        if (getterToInject) {
            IMP newGetterImp = imp_implementationWithBlock(newGetterBlock);
            const char *getterTypes = method_getTypeEncoding(class_getInstanceMethod(self, @selector(exampleProperty)));
            IMP replacedGetterImp = class_replaceMethod(klass, getter, newGetterImp, getterTypes);
            if (!DIInjectionsGettersBackupWrite(klass, getter, replacedGetterImp ?: (IMP)DINothingToRestore)) {
                imp_removeBlock(replacedGetterImp);
            }
        }

        // If need association and not have setter and property is not ReadOnly so we need implement simple setter
        if (!haveIvar && !useOriginalAccessors &&
            !RRPropertyGetAttribute(property, "R")) {
            
            if (isWeak) {
                newSetterBlock = ^void(id target, id newValue) {
                    DIWeakWrapper *wrapper = objc_getAssociatedObject(target, associationKey) ?: [[DIWeakWrapper alloc] init];
                    wrapper->object = newValue;
                    objc_setAssociatedObject(target, associationKey, wrapper, associationPolicy);
                    if (originalSetterIMP) {
                        originalSetterIMP(target, setter, newValue);
                    }
                };
            }
            else {
                newSetterBlock = ^void(id target, id newValue) {
                    objc_setAssociatedObject(target, associationKey, newValue, associationPolicy);
                    if (originalSetterIMP) {
                        originalSetterIMP(target, setter, newValue);
                    }
                };
            }
        }

        if (newSetterBlock) {
            IMP newSetterImp = imp_implementationWithBlock(newSetterBlock);
            const char *setterTypes = method_getTypeEncoding(class_getInstanceMethod(self, @selector(setExampleProperty:)));
            IMP replacedSetterImp = class_replaceMethod(klass, setter, newSetterImp, setterTypes);
            if (!DIInjectionsSettersBackupWrite(klass, setter, replacedSetterImp ?: (IMP)DINothingToRestore)) {
                imp_removeBlock(replacedSetterImp);
            }
        }
    });
}

+ (void)inject:(DIPropertyBlock)block conformingProtocols:(NSArray<Protocol *> *)protocols {
    [self enumerateAllClassProperties:^(Class class, objc_property_t property) {
        [self inject:class property:property getterBlock:nil setterBlock:nil blockFactory:block];
    } conformingProtocols:protocols];
}

+ (void)reject:(Class)class property:(objc_property_t)property {
    // Restore or remove getter
    SEL getter = RRPropertyGetGetter(property);
    IMP getterImp = DIInjectionsGettersBackupRead(class, getter);
    if (getterImp && getterImp != DINothingToRestore) {
        const char *types = method_getTypeEncoding(class_getInstanceMethod(self, @selector(exampleProperty)));
        IMP replacedImp = class_replaceMethod(class, getter, getterImp, types);
        imp_removeBlock(replacedImp);
    }
    else if (getterImp == DINothingToRestore) {
        const char *getterTypes = method_getTypeEncoding(class_getInstanceMethod(self, @selector(exampleProperty)));
        IMP replacedImp = class_replaceMethod(class, getter, EmptyMethodImp(), getterTypes);
        imp_removeBlock(replacedImp);
    }
    DIInjectionsGettersBackupWrite(class, getter, nil);

    // Restore or remove setter
    SEL setter = RRPropertyGetSetter(property);
    IMP setterImp = DIInjectionsSettersBackupRead(class, setter);
    if (setterImp && setterImp != DINothingToRestore) {
        const char *types = method_getTypeEncoding(class_getInstanceMethod(self, @selector(setExampleProperty:)));
        IMP replacedImp = class_replaceMethod(class, setter, getterImp, types);
        imp_removeBlock(replacedImp);
    }
    else if (setterImp == DINothingToRestore) {
        const char *setterTypes = method_getTypeEncoding(class_getInstanceMethod(self, @selector(setExampleProperty:)));
        IMP replacedImp = class_replaceMethod(class, setter, EmptyMethodImp(), setterTypes);
        imp_removeBlock(replacedImp);
    }
    DIInjectionsSettersBackupWrite(class, setter, nil);

    // Remove association
    NSArray *associated = DIAssociatesRead(class, getter);
    if (associated) {
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        SEL associationKey = NSSelectorFromString([@"DI_" stringByAppendingString:propertyName]);
        objc_AssociationPolicy associationPolicy = RRPropertyGetAssociationPolicy(property);
        for (id object in associated) {
            objc_setAssociatedObject(object, associationKey, nil, associationPolicy);
        }
        DIAssociatesRemove(class, getter);
    }
}

+ (void)reject:(DIPropertyFilter)block conformingProtocols:(NSArray<Protocol *> *)protocols {
    [self enumerateAllClassProperties:^(Class klass, objc_property_t property) {
        RRPropertyGetClassAndProtocols(property, ^(Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            if (block(klass, propertyName, propertyClass, propertyProtocols)) {
                [self reject:klass property:property];
            }
        });
    } conformingProtocols:protocols];
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

+ (BOOL)checkInjected:(Class)klass selector:(SEL)selector {
    if ([NSStringFromSelector(selector) hasSuffix:@":"]) {
        return DIInjectionsSettersBackupRead(klass, selector) != nil;
    }
    return DIInjectionsGettersBackupRead(klass, selector) != nil;
}

+ (NSArray<Class> *)injectedClasses {
    NSMutableSet *set = [NSMutableSet setWithArray:injectionsGettersBackup.allKeys];
    [set unionSet:[NSSet setWithArray:injectionsSettersBackup.allKeys]];
    return set.allObjects;
}

+ (NSArray<NSString *> *)injectedSelectorsForClass:(Class)klass {
    return [[NSArray arrayWithArray:injectionsGettersBackup[klass].allKeys]
            arrayByAddingObjectsFromArray:injectionsSettersBackup[klass].allKeys];
}

+ (NSString *)debugDescription {
    return [[super description] stringByAppendingString:^{
        NSMutableString *str = [NSMutableString stringWithString:@" injected:\n"];

        if (injectionsGettersBackup == nil &&
            injectionsSettersBackup == nil) {
            [str appendString:@"Nothing"];
            return str;
        }

        for (Class class in injectionsGettersBackup) {
            [str appendFormat:@"%@ properties to class %@:\n", @(injectionsGettersBackup[class].count), class];
            NSInteger i = 1;
            for (NSString *selStr in injectionsGettersBackup[class]) {
                NSArray *objects = DIAssociatesRead(class, NSSelectorFromString(selStr));
                if (objects) {
                    [str appendFormat:@"\t%@. @selector(%@) associated with %@ object(s)\n", @(i++), selStr, @(objects.count)];
                }
                else {
                    [str appendFormat:@"\t%@. @selector(%@)\n", @(i++), selStr];
                }
            }
        }
        return str;
    }()];
}

#pragma mark - Plugin API

+ (void)inject:(Class)klass property:(objc_property_t)property getterBlock:(DIGetter)getterBlock setterBlock:(DISetter)setterBlock {
    [self inject:klass property:property getterBlock:getterBlock setterBlock:setterBlock blockFactory:nil];
}

@end
