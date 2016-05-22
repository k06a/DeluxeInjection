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

#import <assert.h>

#import "DIDeluxeInjectionPlugin.h"
#import "DIInject.h"
#import "DIImperative.h"

@interface DIPropertyHolder : NSObject

@property (assign, nonatomic) Class targetClass;
@property (assign, nonatomic) Class klass;
@property (strong, nonatomic) NSSet<Protocol *> *protocols;
@property (assign, nonatomic) SEL getter;
@property (assign, nonatomic) BOOL wasInjected;

@end

@implementation DIPropertyHolder

@end

//

@interface DIDeluxeInjectionImperative ()

@property (strong, nonatomic) NSMutableDictionary<id,NSMutableArray<DIPropertyHolder *> *> *byClass;
@property (strong, nonatomic) NSMutableDictionary<NSValue *,NSMutableArray<DIPropertyHolder *> *> *byProtocol;

@end

@implementation DIDeluxeInjectionImperative

- (instancetype)init
{
    self = [super init];
    if (self) {
        _byClass = [NSMutableDictionary dictionary];
        _byProtocol = [NSMutableDictionary dictionary];
        
        [DeluxeInjection inject:^NSArray * (Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            
            DIPropertyHolder *holder = [[DIPropertyHolder alloc] init];
            holder.targetClass = targetClass;
            holder.klass = propertyClass;
            holder.protocols = propertyProtocols;
            holder.getter = getter;
            
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
        } conformingProtocol:@protocol(DIInject)];
    }
    return self;
}

- (void)injectByPropertyClass:(Class)klass value:(id)value {
    [self injectByPropertyClass:klass getterBlock:DIGetterIfIvarIsNil(^(id target){
        return value;
    })];
}

- (void)injectByPropertyProtocol:(Protocol *)protocol value:(id)value {
    [self injectByPropertyProtocol:protocol getterBlock:DIGetterIfIvarIsNil(^(id target){
        return value;
    })];
}

- (void)injectByPropertyClass:(Class)klass getterBlock:(DIGetter)getterBlock {
    for (DIPropertyHolder *holder in self.byClass[klass]) {
        if (holder.wasInjected) {
            NSLog(@"Warning: Reinjecting property [%@ %@]", holder.targetClass, NSStringFromSelector(holder.getter));
        }
        [DeluxeInjection inject:holder.targetClass getter:holder.getter getterBlock:getterBlock];
        holder.wasInjected = YES;
    }
}

- (void)injectByPropertyProtocol:(Protocol *)protocol getterBlock:(DIGetter)getterBlock {
    NSValue *key = [NSValue valueWithPointer:(__bridge void *)(protocol)];
    for (DIPropertyHolder *holder in self.byProtocol[key]) {
        if (holder.wasInjected) {
            NSLog(@"Warning: Reinjecting property [%@ %@]", holder.targetClass, NSStringFromSelector(holder.getter));
        }
        [DeluxeInjection inject:holder.targetClass getter:holder.getter getterBlock:getterBlock];
        holder.wasInjected = YES;
    }
}

- (void)checkAllInjected {
    for (Class klass in self.byClass) {
        for (DIPropertyHolder *holder in self.byClass[klass]) {
            NSString *problemDescription = [NSString stringWithFormat:@"Missing injection by class to [%@ %@]", holder.targetClass, NSStringFromSelector(holder.getter)];
            NSAssert(holder.wasInjected, problemDescription);
            if (!holder.wasInjected) {
                NSLog(@"Warning: %@", problemDescription);
            }
        }
    }
    
    for (NSValue *key in self.byProtocol) {
        for (DIPropertyHolder *holder in self.byProtocol[key]) {
            NSString *problemDescription = [NSString stringWithFormat:@"Missing injection by protocol to [%@ %@]", holder.targetClass, NSStringFromSelector(holder.getter)];
            NSAssert(holder.wasInjected, problemDescription);
            if (!holder.wasInjected) {
                NSLog(@"Warning: %@", problemDescription);
            }
        }
    }
}

@end

//

@implementation DeluxeInjection (DIImperative)

+ (void)imperative:(void (^)(DIDeluxeInjectionImperative *lets))block; {
    DIDeluxeInjectionImperative *di = [[DIDeluxeInjectionImperative alloc] init];
    block(di);
    [di checkAllInjected];
}

@end
