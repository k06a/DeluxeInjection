//
//  DIForceInject.m
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

#import <RuntimeRoutines/RuntimeRoutines.h>

#import "DIInject.h"
#import "DILazy.h"
#import "DIDefaults.h"
#import "DIDynamic.h"

#import "DIDeluxeInjectionPlugin.h"
#import "DIForceInject.h"

static NSSet *excudeProtocols() {
    static NSSet *excudeProtocols;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excudeProtocols = [NSSet setWithArray:@[
            @protocol(DIInject),
            @protocol(DILazy),
            @protocol(DIDynamic),
            @protocol(DIDefaults),
            @protocol(DIDefaultsSync),
            @protocol(DIDefaultsArchived),
            @protocol(DIDefaultsArchivedSync),
        ]];
    });
    return excudeProtocols;
}

@implementation DeluxeInjection (DIForceInject)

+ (void)forceInject:(DIPropertyGetter)block {
    [self inject:^NSArray* (Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return nil;
        }
        
        id value = block(targetClass, getter, propertyName, propertyClass, propertyProtocols);
        if (value == [DeluxeInjection doNotInject]) {
            return nil;
        }
        
        objc_property_t property = RRClassGetPropertyByName(targetClass, propertyName);
        if (RRPropertyGetIsWeak(property)) {
            __weak id weakValue = value;
            return @[DIGetterIfIvarIsNil(^id(id target) {
                return weakValue;
            }), [DeluxeInjection doNotInject]];
        } else {
            return @[DIGetterIfIvarIsNil(^id(id target) {
                return value;
            }), [DeluxeInjection doNotInject]];
        }
    } conformingProtocols:nil];
}

+ (void)forceInjectBlock:(DIPropertyGetterBlock)block {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return nil;
        }
        return @[(id)block(targetClass, getter, propertyName, propertyClass, propertyProtocols) ?: (id)[DeluxeInjection doNotInject], [DeluxeInjection doNotInject]];
    } conformingProtocols:nil];
}

+ (void)forceReject:(DIPropertyFilter)block {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return NO;
        }
        return block(targetClass, propertyName, propertyClass, propertyProtocols);
    } conformingProtocols:nil];
}

+ (void)forceRejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return NO;
        }
        return YES;
    } conformingProtocols:nil];
}

@end
