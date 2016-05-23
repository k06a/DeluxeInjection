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
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSSet<Protocol *> *protocols;
@property (assign, nonatomic) SEL getter;
@property (assign, nonatomic) BOOL wasInjected;

@end

@implementation DIPropertyHolder

@end

//

@interface DIDeluxeInjectionImperativeInjector ()

@property (weak, nonatomic) DIDeluxeInjectionImperative *lets;
@property (assign, nonatomic) Class savedClass;
@property (assign, nonatomic) Protocol *savedProtocol;
@property (copy, nonatomic) DIGetter savedValueBlock;
@property (copy, nonatomic) DIPropertyFilterBlock savedFilterBlock;

@end

@interface DIDeluxeInjectionImperative ()

@property (strong, nonatomic) NSMutableDictionary<id,NSMutableArray<DIPropertyHolder *> *> *byClass;
@property (strong, nonatomic) NSMutableDictionary<NSValue *,NSMutableArray<DIPropertyHolder *> *> *byProtocol;

@end

//

@implementation DIDeluxeInjectionImperativeInjector

- (instancetype)valueObject:(id)valueObject {
    return [self valueBlock:DIGetterIfIvarIsNil(^id (id target) {
        return valueObject;
    })];
}

- (instancetype)valueBlock:(DIGetter)valueBlock {
    NSAssert(self.savedValueBlock == nil, @"You should call valueObject: or valueBlock: only once");
    self.savedValueBlock = valueBlock;
    return self;
}

- (instancetype)filterClass:(Class)filterClass {
    return [self filterBlock:^BOOL(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return [targetClass isSubclassOfClass:filterClass];
    }];
}

- (instancetype)filterBlock:(DIPropertyFilterBlock)filterBlock {
    NSAssert(self.savedFilterBlock == nil, @"You should call filterClass: or filterBlock: only once");
    self.savedFilterBlock = filterBlock;
    return self;
}

- (void)dealloc {
    NSAssert(!!self.savedClass != !!self.savedProtocol, @"You should not define both class and protocol to inject");
    NSAssert(self.savedValueBlock, @"You should call valueObject: or valueBlock: once");
    
    NSValue *key = [NSValue valueWithPointer:(__bridge void *)(self.savedProtocol)];
    NSArray *holders = self.savedClass ? self.lets.byClass[self.savedClass] : self.lets.byProtocol[key];
    
    for (DIPropertyHolder *holder in holders) {
        if (self.savedFilterBlock && !self.savedFilterBlock(holder.targetClass, holder.getter, holder.name, holder.klass, holder.protocols)) {
            continue;
        }
        if (holder.wasInjected) {
            NSLog(@"Warning: Reinjecting property [%@ %@]", holder.targetClass, NSStringFromSelector(holder.getter));
        }
        [DeluxeInjection inject:holder.targetClass getter:holder.getter getterBlock:self.savedValueBlock];
        holder.wasInjected = YES;
    }
}

@end

//

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
            holder.getter = getter;
            holder.name = propertyName;
            holder.klass = propertyClass;
            holder.protocols = propertyProtocols;
            
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

- (DIDeluxeInjectionImperativeInjector *)injectByPropertyClass:(Class)klass {
    DIDeluxeInjectionImperativeInjector *injector = [[DIDeluxeInjectionImperativeInjector alloc] init];
    injector.lets = self;
    injector.savedClass = klass;
    return injector;
}

- (DIDeluxeInjectionImperativeInjector *)injectByPropertyProtocol:(Protocol *)protocol {
    DIDeluxeInjectionImperativeInjector *injector = [[DIDeluxeInjectionImperativeInjector alloc] init];
    injector.lets = self;
    injector.savedProtocol = protocol;
    return injector;
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
