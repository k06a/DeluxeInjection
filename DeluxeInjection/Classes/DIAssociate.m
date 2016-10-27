//
//  DIAssociate.h
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

#import "DIAssociate.h"
#import "DIDeluxeInjectionPlugin.h"
#import "DIInjectPlugin.h"

@implementation DeluxeInjection (DIAssociate)

+ (void)load {
    [DIImperative registerPluginProtocol:@protocol(DIAssociate)];
}

+ (void)injectAssociate {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter,
                            NSString *propertyName, Class propertyClass,
                            NSSet<Protocol *> *propertyProtocols) {
        return @[
            DIGetterMake(^id(id target, SEL cmd, id *ivar) {
                return *ivar;
            }),
            DISetterWithOriginalMake(^(id target, SEL cmd, id *ivar, id value, DIOriginalSetter originalSetter) {
                *ivar = value;
                if (originalSetter) {
                    originalSetter(target, setter, value);
                }
            })
        ];
    } conformingProtocols:@[ @protocol(DIAssociate) ]];
}

+ (void)rejectAssociate {
    [self reject:^BOOL(Class targetClass, NSString *propertyName,
                       Class propertyClass,
                       NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocols:@[ @protocol(DIAssociate) ]];
}

@end

//

@implementation DIImperative (DIAssociate)

- (void)injectAssociate {
  [[[[[self inject] byPropertyProtocol:@protocol(DIAssociate)]
      getterBlock:^id(Class targetClass, SEL getter, NSString *propertyName,
                      Class propertyClass, NSSet<Protocol *> *propertyProtocols,
                      id target, id *ivar, DIOriginalGetter originalGetter) {
        return *ivar;
      }] setterBlock:^(Class targetClass, SEL setter, NSString *propertyName,
                       Class propertyClass,
                       NSSet<Protocol *> *propertyProtocols, id target,
                       id *ivar, id value, DIOriginalSetter originalSetter) {
    *ivar = value;
    if (originalSetter) {
      originalSetter(target, setter, value);
    }
  }] skipDIInjectProtocolFilter];
}

- (void)rejectAssociate {
  [[[self reject] byPropertyProtocol:@protocol(DIAssociate)]
      skipDIInjectProtocolFilter];
}

@end
