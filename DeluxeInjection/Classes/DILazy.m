//
//  DILazy.m
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
#import "DIInjectPlugin.h"
#import "DILazy.h"

@implementation DeluxeInjection (DILazy)

+ (void)load {
    [DIImperative registerPluginProtocol:@protocol(DILazy)];
}

+ (void)injectLazy {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        NSAssert(propertyClass, @"DILazy can not be applied to unknown class (id)");
        return @[DIGetterIfIvarIsNil(^id(id target) {
            return [[propertyClass alloc] init];
        }), [DeluxeInjection doNotInject]];
    } conformingProtocols:@[@protocol(DILazy)]];
}

+ (void)rejectLazy {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocols:@[@protocol(DILazy)]];
}

@end

//

@implementation DIImperative (DILazy)

- (void)injectLazy {
    [[[[self inject] byPropertyProtocol:@protocol(DILazy)] getterBlock:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, DIOriginalGetter originalGetter) {
        NSAssert(propertyClass, @"DILazy can not be applied to unknown class (id)");
        if (*ivar == nil) {
            *ivar = [[propertyClass alloc] init];
        }
        return *ivar;
    }] skipDIInjectProtocolFilter];
}

- (void)rejectLazy {
    [[[self reject] byPropertyProtocol:@protocol(DILazy)] skipDIInjectProtocolFilter];
}

@end

