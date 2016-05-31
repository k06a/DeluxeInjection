//
//  DIDynamic.h
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
#import "DIDynamic.h"

@implementation DeluxeInjection (DIDynamic)

+ (void)load {
    [DIImperative registerPluginProtocol:@protocol(DIDynamic)];
}

+ (void)injectDynamic {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return @[DIGetterMake(^id (id target, id *ivar) {
            return *ivar;
        }), DISetterWithOriginalMake(^(id target, id *ivar, id value, DIOriginalSetter originalSetter) {
            *ivar = value;
            if (originalSetter) {
                originalSetter(target, setter, value);
            }
        })];
    } conformingProtocols:@[@protocol(DIDynamic)]];
}

+ (void)rejectDynamic {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocols:@[@protocol(DIDynamic)]];
}

@end

//

@implementation DIImperative (DIDynamic)

- (void)injectDynamic {
    [[[[self inject] byPropertyProtocol:@protocol(DIDynamic)] getterBlock:^id(Class targetClass, SEL getter, NSString * propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, DIOriginalGetter originalGetter) {
        return *ivar;
    }] setterBlock:^(Class targetClass, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> * propertyProtocols, id target, id *ivar, id value, DIOriginalSetter originalSetter) {
        *ivar = value;
        if (originalSetter) {
            originalSetter(target, setter, value);
        }
    }];
}

- (void)rejectDynamic {
    [[self reject] byPropertyProtocol:@protocol(DIDynamic)];
}

@end
