//
//  DIInject.m
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

#import <RuntimeRoutines/RuntimeRoutines.h>

#import "DIDeluxeInjectionPlugin.h"
#import "DIImperativePlugin.h"

#import "DIInjectPlugin.h"

//

DIImperativeGetter DIImperativeGetterMake(DIImperativeGetter getter) {
    return getter;
}

DIImperativeSetter DIImperativeSetterMake(DIImperativeSetter setter) {
    return setter;
}

DIImperativeGetter DIImperativeGetterFromGetter(DIGetter di_getter) {
    return ^id _Nullable(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, DIOriginalGetter originalGetter) {
        return di_getter(target, getter, ivar, originalGetter);
    };
}

DIImperativeSetter DIImperativeSetterFromSetter(DISetter di_setter) {
    return ^(Class targetClass, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, id value, DIOriginalSetter originalSetter) {
        return di_setter(target, setter, ivar, value, originalSetter);
    };
}

//

@implementation DeluxeInjection (DIInject)

+ (void)load {
    [DIImperative registerPluginProtocol:@protocol(DIInject)];
}

+ (void)inject:(DIPropertyGetter)block {
    [self inject:^NSArray * (Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        id value = block(targetClass, getter, propertyName, propertyClass, propertyProtocols);
        if (value == [DeluxeInjection doNotInject]) {
            return nil;
        }
        
        objc_property_t property = RRClassGetPropertyByName(targetClass, propertyName);
        if (RRPropertyGetIsWeak(property)) {
            __weak id weakValue = value;
            return @[DIGetterIfIvarIsNil(^id(id target, SEL cmd) {
                return weakValue;
            }), [DeluxeInjection doNotInject]];
        } else {
            return @[DIGetterIfIvarIsNil(^id(id target, SEL cmd) {
                return value;
            }), [DeluxeInjection doNotInject]];
        }
    } conformingProtocols:@[@protocol(DIInject)]];
}

+ (void)injectBlock:(DIPropertyGetterBlock)block {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return @[(id)block(targetClass, getter, propertyName, propertyClass, propertyProtocols) ?: (id)[DeluxeInjection doNotInject], [DeluxeInjection doNotInject]];
    } conformingProtocols:@[@protocol(DIInject)]];
}

+ (void)reject:(DIPropertyFilter)block {
    [self reject:block conformingProtocols:@[@protocol(DIInject)]];
}

+ (void)rejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocols:@[@protocol(DIInject)]];
}

@end

//

@interface DIImperativeInjector ()

@property (assign, nonatomic) BOOL shouldSkipDIInjectProtocolFilter;
@property (assign, nonatomic) BOOL resolved;
@property (assign, nonatomic) BOOL injector;
@property (weak, nonatomic) DIImperative *lets;
@property (assign, nonatomic) Class savedPropertyClass;
@property (assign, nonatomic) Protocol *savedPropertyProtocol;
@property (copy, nonatomic) DIImperativeGetter savedGetterBlock;
@property (copy, nonatomic) DIImperativeSetter savedSetterBlock;
@property (copy, nonatomic) DIPropertyFilterBlock savedFilterBlock;

@end

@implementation DIImperativeInjector

- (instancetype)skipDIInjectProtocolFilter {
    self.shouldSkipDIInjectProtocolFilter = YES;
    return self;
}

- (instancetype)byPropertyClass:(Class)klass {
    NSAssert(self.savedPropertyClass == nil, @"You should call byPropertyClass: only once");
    NSAssert(self.savedPropertyProtocol == nil, @"You should not call byPropertyClass: after calling byPropertyProtocol:");
    self.savedPropertyClass = klass;
    return self;
}

- (instancetype)byPropertyProtocol:(Protocol *)protocol {
    NSAssert(self.savedPropertyProtocol == nil, @"You should call byPropertyProtocol: only once");
    NSAssert(self.savedPropertyClass == nil, @"You should not call byPropertyProtocol: after calling byPropertyClass:");
    self.savedPropertyProtocol = protocol;
    return self;
}

- (instancetype)getterValue:(id)getterValue {
    return [self getterBlock:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, DIOriginalGetter originalGetter) {
        if (*ivar == nil) {
            *ivar = getterValue;
        }
        return *ivar;
    }];
}

- (instancetype)getterValueLazy:(id(^)())lazyBlock {
    __block id(^lazyBlockCopy)() = [lazyBlock copy];
    __block id lazyValue = nil;
    __block dispatch_once_t onceToken = 0;
    [self getterBlock:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, DIOriginalGetter originalGetter) {
        if (*ivar == nil) {
            dispatch_once(&onceToken, ^{
                lazyValue = lazyBlockCopy();
                lazyBlockCopy = nil;
            });
            *ivar = lazyValue;
        }
        return *ivar;
    }];
    return self;
}

- (instancetype)getterValueLazyByClass:(Class)lazyClass {
    [self getterValueLazy:^id {
        return [[lazyClass alloc] init];
    }];
    return self;
}

- (instancetype)getterBlock:(DIImperativeGetter)getterBlock {
    NSAssert(self.savedGetterBlock == nil, @"You should call getterValue: or getterBlock: only once");
    self.savedGetterBlock = getterBlock;
    return self;
}

- (instancetype)setterBlock:(DIImperativeSetter)setterBlock {
    NSAssert(self.savedSetterBlock == nil, @"You should call setterBlock: only once");
    self.savedSetterBlock = setterBlock;
    return self;
}

- (instancetype)filterBlock:(DIPropertyFilterBlock)filterBlock {
    NSAssert(self.savedFilterBlock == nil, @"You should call filterContainerClass: or filterBlock: only once");
    self.savedFilterBlock = filterBlock;
    return self;
}

- (instancetype)filterContainerClass:(Class)filterContainerClass {
    return [self filterBlock:^BOOL(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return [targetClass isSubclassOfClass:filterContainerClass];
    }];
}

- (void)resolve {
    if (self.resolved) {
        return;
    }
    
    if (self.injector) {
        NSAssert(self.savedGetterBlock || self.savedSetterBlock, @"You should call getterValue: or getterBlock: or setterBlock:");
    } else {
        NSAssert(self.savedGetterBlock == nil && self.savedSetterBlock == nil, @"You should NOT call getterValue: or getterBlock: or setterBlock: when trying to reject");
    }
    
    NSValue *key = [NSValue valueWithPointer:(__bridge void *)(self.savedPropertyProtocol)];
    NSArray *holders = self.savedPropertyClass ? self.lets.byClass[self.savedPropertyClass] : self.lets.byProtocol[key];
    
    for (DIPropertyHolder *holder in holders) {
        if (!self.shouldSkipDIInjectProtocolFilter && ![holder.propertyProtocols containsObject:@protocol(DIInject)]) {
            continue;
        }
        if (self.savedFilterBlock && !self.savedFilterBlock(holder.targetClass, holder.getter, holder.propertyName, holder.propertyClass, holder.propertyProtocols)) {
            continue;
        }
        if (self.injector) {
            if (self.savedGetterBlock || self.savedSetterBlock) {
                if (self.savedGetterBlock && holder.wasInjectedGetter) {
                    NSLog(@"Warning: Reinjecting property getter [%@ %@]", holder.targetClass, NSStringFromSelector(holder.getter));
                }
                if (self.savedSetterBlock && holder.wasInjectedSetter) {
                    NSLog(@"Warning: Reinjecting property setter [%@ %@]", holder.targetClass, NSStringFromSelector(holder.setter));
                }
                DIImperativeGetter savedGetterBlock = [self.savedGetterBlock copy];
                DIImperativeSetter savedSetterBlock = [self.savedSetterBlock copy];
                objc_property_t property = RRClassGetPropertyByName(holder.targetClass, holder.propertyName);
                [DeluxeInjection inject:holder.targetClass property:property getterBlock:^id(id target, SEL cmd, id *ivar, DIOriginalGetter originalGetter) {
                    if (savedGetterBlock) {
                        return savedGetterBlock(holder.targetClass, holder.getter, holder.propertyName, holder.propertyClass, holder.propertyProtocols, target, ivar, originalGetter);
                    }
                    return originalGetter(target, holder.setter);
                } setterBlock:^void(id target, SEL cmd, id *ivar, id value, DIOriginalSetter originalSetter) {
                    if (savedSetterBlock) {
                        return savedSetterBlock(holder.targetClass, holder.setter, holder.propertyName, holder.propertyClass, holder.propertyProtocols, target, ivar, value, originalSetter);
                    }
                    return originalSetter(target, holder.setter, value);
                }];
                holder.wasInjectedGetter = (self.savedGetterBlock != nil);
                holder.wasInjectedSetter = (self.savedSetterBlock != nil);
            }
        }
        else {
            objc_property_t property = class_getProperty(holder.targetClass, holder.propertyName.UTF8String);
            [DeluxeInjection reject:holder.targetClass property:property];
            holder.wasInjectedGetter = NO;
            holder.wasInjectedSetter = NO;
        }
    }
    
    self.resolved = YES;
}

- (void)dealloc {
    [self resolve];
}

@end

//

@implementation DIImperative (DIInject)

- (DIImperativeInjector *)inject {
    DIImperativeInjector *injector = [[DIImperativeInjector alloc] init];
    injector.lets = self;
    injector.injector = YES;
    return injector;
}

- (DIImperativeInjector *)reject {
    DIImperativeInjector *rejector = [[DIImperativeInjector alloc] init];
    rejector.lets = self;
    rejector.injector = NO;
    return rejector;
}

- (void)rejectAll {
    [[self reject] byPropertyProtocol:@protocol(DIInject)];
}

@end
