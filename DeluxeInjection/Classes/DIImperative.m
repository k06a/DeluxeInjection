//
//  DIImperative.m
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

#import "DIDeluxeInjectionPlugin.h"
#import "DIInject.h"

#import "DIImperative.h"

@interface DIPropertyHolder : NSObject

@property (assign, nonatomic) Class targetClass;
@property (assign, nonatomic) Class propertyClass;
@property (strong, nonatomic) NSString *propertyName;
@property (strong, nonatomic) NSSet<Protocol *> *propertyProtocols;
@property (assign, nonatomic) SEL getter;
@property (assign, nonatomic) SEL setter;
@property (assign, nonatomic) BOOL wasInjectedGetter;
@property (assign, nonatomic) BOOL wasInjectedSetter;

@end

@implementation DIPropertyHolder

@end

//

@interface DIImperative ()

@property (strong, nonatomic) NSMutableDictionary<id,NSMutableArray<DIPropertyHolder *> *> *byClass;
@property (strong, nonatomic) NSMutableDictionary<NSValue *,NSMutableArray<DIPropertyHolder *> *> *byProtocol;
@property (assign, nonatomic) BOOL shouldSkipAsserts;

@end

//

@interface DIImperativeInjector ()

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
                objc_property_t property = class_getProperty(holder.targetClass, holder.propertyName.UTF8String);
                [DeluxeInjection inject:holder.targetClass property:property getterBlock:^id(id target, id *ivar, DIOriginalGetter originalGetter) {
                    return savedGetterBlock(holder.targetClass, holder.getter, holder.propertyName, holder.propertyClass, holder.propertyProtocols, target, ivar, originalGetter);
                } setterBlock:^void(id target, id *ivar, id value, DIOriginalSetter originalSetter) {
                    return savedSetterBlock(holder.targetClass, holder.setter, holder.propertyName, holder.propertyClass, holder.propertyProtocols, target, ivar, value, originalSetter);
                }];
                holder.wasInjectedGetter = (self.savedGetterBlock != nil);
                holder.wasInjectedSetter = (self.savedSetterBlock != nil);
            }
        }
        else {
            [DeluxeInjection reject:holder.targetClass getter:holder.getter];
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

static NSMutableArray<Protocol *> *DIImperativeProtocols;

@implementation DIImperative

+ (void)registerPluginProtocol:(Protocol *)pluginProtocol {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DIImperativeProtocols = [NSMutableArray array];
    });
    [DIImperativeProtocols addObject:pluginProtocol];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _byClass = [NSMutableDictionary dictionary];
        _byProtocol = [NSMutableDictionary dictionary];
        
        [DeluxeInjection inject:^NSArray * (Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            
            DIPropertyHolder *holder = [[DIPropertyHolder alloc] init];
            holder.targetClass = targetClass;
            holder.getter = getter;
            holder.setter = setter;
            holder.propertyName = propertyName;
            holder.propertyClass = propertyClass;
            holder.propertyProtocols = propertyProtocols;
            
            if (propertyClass) {
                if (_byClass[(id)propertyClass] == nil) {
                    _byClass[(id)propertyClass] = [NSMutableArray array];
                }
                [_byClass[(id)propertyClass] addObject:holder];
            }
            
            for (Protocol *protocol in propertyProtocols) {
                NSValue *key = [NSValue valueWithPointer:(__bridge void *)(protocol)];
                if (_byProtocol[key] == nil) {
                    _byProtocol[key] = [NSMutableArray array];
                }
                [_byProtocol[key] addObject:holder];
            }
            
            return @[[DeluxeInjection doNotInject],
                     [DeluxeInjection doNotInject]];
        } conformingProtocols:DIImperativeProtocols];
    }
    return self;
}

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

- (void)skipAsserts {
    self.shouldSkipAsserts = YES;
}

- (void)checkAllInjected {
    if (self.shouldSkipAsserts) {
        return;
    }
    
    for (Class klass in self.byClass) {
        for (DIPropertyHolder *holder in self.byClass[klass]) {
            NSString *problemDescription = [NSString stringWithFormat:@"Missing injection by class to %@.%@", holder.targetClass, NSStringFromSelector(holder.getter)];
            NSAssert(holder.wasInjectedGetter || holder.wasInjectedSetter, problemDescription);
            if (!holder.wasInjectedGetter && !holder.wasInjectedSetter) {
                NSLog(@"Warning: %@", problemDescription);
            }
        }
    }
    
    for (NSValue *key in self.byProtocol) {
        for (DIPropertyHolder *holder in self.byProtocol[key]) {
            NSString *problemDescription = [NSString stringWithFormat:@"Missing injection by protocol to %@.%@", holder.targetClass, NSStringFromSelector(holder.getter)];
            NSAssert(holder.wasInjectedGetter || holder.wasInjectedSetter, problemDescription);
            if (!holder.wasInjectedGetter && !holder.wasInjectedSetter) {
                NSLog(@"Warning: %@", problemDescription);
            }
        }
    }
}

@end

//

@implementation DeluxeInjection (DIImperative)

+ (void)imperative:(void (^)(DIImperative *lets))block; {
    DIImperative *di = [[DIImperative alloc] init];
    @autoreleasepool {
        block(di);
    }
    [di checkAllInjected];
}

@end
