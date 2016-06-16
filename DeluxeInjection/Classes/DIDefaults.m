//
//  DIDefaults.m
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

#import <Foundation/Foundation.h>
#import "DIDeluxeInjectionPlugin.h"
#import "DIDefaults.h"

@implementation NSObject (DIDefaults)

@end

@implementation DeluxeInjection (DIDefaults)

#pragma mark - Private

+ (void)load {
    [DIImperative registerPluginProtocol:@protocol(DIDefaults)];
    [DIImperative registerPluginProtocol:@protocol(DIDefaultsSync)];
    [DIImperative registerPluginProtocol:@protocol(DIDefaultsArchived)];
    [DIImperative registerPluginProtocol:@protocol(DIDefaultsArchivedSync)];
}

#pragma mark - Public

+ (void)injectDefaults {
    [self injectDefaultsWithKeyBlock:^NSString *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return propertyName;
    }];
}

+ (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock {
    [self injectDefaultsWithKeyBlock:keyBlock defaultsBlock:^NSUserDefaults *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return [NSUserDefaults standardUserDefaults];
    }];
}

+ (void)injectDefaultsWithDefaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
    [self injectDefaultsWithKeyBlock:^NSString *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return propertyName;
    } defaultsBlock:defaultsBlock];
}

+ (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock defaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
    NSMutableSet *defaultsProtocols = [NSMutableSet setWithArray:@[
        @protocol(DIDefaults),
        @protocol(DIDefaultsSync),
        @protocol(DIDefaultsArchived),
        @protocol(DIDefaultsArchivedSync),
    ]];
    
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        
        NSMutableSet *protocolsCopy = [defaultsProtocols mutableCopy];
        [protocolsCopy intersectSet:propertyProtocols];
        Protocol *protocol = protocolsCopy.anyObject;
        NSValue *protocolKey = [NSValue valueWithPointer:(__bridge void *)protocol];
        
        BOOL withSync = [@{
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaults)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsSync)] : @YES,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchived)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchivedSync)] : @YES,
        }[protocolKey] boolValue];
        
        BOOL withArchive = [@{
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaults)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsSync)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchived)] : @YES,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchivedSync)] : @YES,
        }[protocolKey] boolValue];
        
        NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
        NSUserDefaults *defaults = defaultsBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: [NSUserDefaults standardUserDefaults];
        return @[DIGetterMake(^id _Nullable(id target, id *ivar) {
            if (withSync) {
                [defaults synchronize];
            }
            id value = [defaults objectForKey:key];
            if (withArchive && value) {
                return [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
            return value;
        }), DISetterWithOriginalMake(^(id target, id *ivar, id value, void (*originalSetter)(id, SEL, id)) {
            if (withArchive && value) {
                value = [NSKeyedArchiver archivedDataWithRootObject:value];
            }
            [defaults setObject:value forKey:key];
            if (withSync) {
                [defaults synchronize];
            }
            if (originalSetter) {
                originalSetter(target, setter, value);
            }
        })];
    } conformingProtocols:defaultsProtocols.allObjects];
}

+ (void)rejectDefaults {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocols:@[ @protocol(DIDefaults),
                             @protocol(DIDefaultsSync),
                             @protocol(DIDefaultsArchived),
                             @protocol(DIDefaultsArchivedSync) ]];
}

@end

//

@implementation DIImperative (DIDefaults)

- (void)injectDefaults {
    [self injectDefaultsWithKeyBlock:^NSString *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return propertyName;
    } defaultsBlock:^NSUserDefaults *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return [NSUserDefaults standardUserDefaults];
    }];
}

- (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock {
    [self injectDefaultsWithKeyBlock:keyBlock defaultsBlock:^NSUserDefaults *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return [NSUserDefaults standardUserDefaults];
    }];
}

- (void)injectDefaultsWithDefaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
    [self injectDefaultsWithKeyBlock:^NSString * _Nullable(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return propertyName;
    } defaultsBlock:defaultsBlock];
}


- (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock defaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
    for (Protocol *protocol in @[ @protocol(DIDefaults),
                                  @protocol(DIDefaultsSync),
                                  @protocol(DIDefaultsArchived),
                                  @protocol(DIDefaultsArchivedSync) ]) {
        NSValue *protocolKey = [NSValue valueWithPointer:(__bridge void *)protocol];
        
        BOOL withSync = [@{
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaults)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsSync)] : @YES,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchived)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchivedSync)] : @YES,
        }[protocolKey] boolValue];
        
        BOOL withArchive = [@{
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaults)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsSync)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchived)] : @YES,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchivedSync)] : @YES,
        }[protocolKey] boolValue];
        
        [[[[self inject] byPropertyProtocol:protocol] getterBlock:^id _Nullable(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, DIOriginalGetter originalGetter) {
            NSUserDefaults *defaults = defaultsBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: [NSUserDefaults standardUserDefaults];
            NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
            if (withSync) {
                [defaults synchronize];
            }
            id value = [defaults objectForKey:key];
            if (withArchive && value) {
                return [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
            return value;
        }] setterBlock:^(Class targetClass, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols, id target, id *ivar, id value, DIOriginalSetter originalSetter) {
            NSUserDefaults *defaults = defaultsBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: [NSUserDefaults standardUserDefaults];
            NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
            if (withArchive && value) {
                value = [NSKeyedArchiver archivedDataWithRootObject:value];
            }
            [defaults setObject:value forKey:key];
            if (withSync) {
                [defaults synchronize];
            }
            if (originalSetter) {
                originalSetter(target, setter, value);
            }
        }];
    }
}

- (void)rejectDefaults {
    for (Protocol *protocol in @[ @protocol(DIDefaults),
                                  @protocol(DIDefaultsSync),
                                  @protocol(DIDefaultsArchived),
                                  @protocol(DIDefaultsArchivedSync) ]) {
        [[self reject] byPropertyProtocol:protocol];
    }
}

@end
