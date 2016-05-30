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
    } conformingProtocol:@protocol(DIDynamic)];
}

+ (void)rejectDynamic {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDynamic)];
}

@end

//

@implementation DIImperative (DIDynamic)

- (void)injectDynamic {
    [[[[self inject] byPropertyProtocol:@protocol(DIDynamic)] getterBlock:^id _Nullable(Class  _Nonnull __unsafe_unretained targetClass, SEL  _Nonnull getter, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols, id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar, DIOriginalGetter  _Nullable originalGetter) {
        return *ivar;
    }] setterBlock:^(Class  _Nonnull __unsafe_unretained targetClass, SEL  _Nonnull setter, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols, id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nullable value, DIOriginalSetter  _Nullable originalSetter) {
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
