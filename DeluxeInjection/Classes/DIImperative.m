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
#import "DIImperativePlugin.h"

//

@implementation DIPropertyHolder

@end

//

@interface DIImperative ()

@property (strong, nonatomic) NSMutableDictionary<id,NSMutableArray<DIPropertyHolder *> *> *byClass;
@property (strong, nonatomic) NSMutableDictionary<NSValue *,NSMutableArray<DIPropertyHolder *> *> *byProtocol;
@property (assign, nonatomic) BOOL shouldSkipAsserts;

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
                if (self->_byClass[(id)propertyClass] == nil) {
                    self->_byClass[(id)propertyClass] = [NSMutableArray array];
                }
                [self->_byClass[(id)propertyClass] addObject:holder];
            }
            
            for (Protocol *protocol in propertyProtocols) {
                NSValue *key = [NSValue valueWithPointer:(__bridge void *)(protocol)];
                if (self->_byProtocol[key] == nil) {
                    self->_byProtocol[key] = [NSMutableArray array];
                }
                [self->_byProtocol[key] addObject:holder];
            }
            
            return @[[DeluxeInjection doNotInject],
                     [DeluxeInjection doNotInject]];
        } conformingProtocols:DIImperativeProtocols];
    }
    return self;
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
