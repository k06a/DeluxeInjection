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
#import "DILazy.h"

@implementation DeluxeInjection (DILazy)

+ (void)injectLazy {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        NSAssert(propertyClass, @"DILazy can not be applied to unknown class (id)");
        return @[DIGetterIfIvarIsNil(^id(id target) {
            return [[propertyClass alloc] init];
        }), [DeluxeInjection doNotInject]];
    } conformingProtocol:@protocol(DILazy)];
}

+ (void)rejectLazy {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DILazy)];
}

@end

//

@implementation DIImperative (DILazy)

- (void)injectLazy {
    [[[self inject] byPropertyProtocol:@protocol(DILazy)] getterBlock:^id _Nullable(Class  _Nonnull __unsafe_unretained targetClass, SEL  _Nonnull getter, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols, id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar, DIOriginalGetter  _Nullable originalGetter) {
        NSAssert(propertyClass, @"DILazy can not be applied to unknown class (id)");
        if (*ivar == nil) {
            *ivar = [[propertyClass alloc] init];
        }
        return *ivar;
    }];
}

- (void)rejectLazy {
    [[self reject] byPropertyProtocol:@protocol(DILazy)];
}

@end

