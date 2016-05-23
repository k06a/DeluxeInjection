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

@implementation NSObject (DILazy)

@end

@implementation DeluxeInjection (DILazy)

+ (void)injectLazy {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
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
