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

+ (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock
                     defaults:(DIUserDefaultsBlock)defaultsBlock
                  forProtocol:(Protocol *)protocol
                     withSync:(BOOL)withSync
                  withArchive:(BOOL)withArchive {
    
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
        NSUserDefaults *defaults = defaultsBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: [NSUserDefaults standardUserDefaults];
        return @[DIGetterMake(^id _Nullable(id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar) {
            if (withSync) {
                [defaults synchronize];
            }
            id value = [defaults objectForKey:key];
            if (withArchive && value) {
                return [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
            return value;
        }), DISetterWithOriginalMake(^(id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nonnull value, void (* _Nullable originalSetter)(id  _Nonnull __strong, SEL _Nonnull, id  _Nullable __strong)) {
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
    } conformingProtocol:protocol];
}

#pragma mark - Public

+ (void)injectDefaults {
    [self injectDefaultsWithKey:^NSString *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return propertyName;
    }];
}

+ (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock {
    [self injectDefaultsWithKey:keyBlock defaults:^NSUserDefaults *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return nil;
    }];
}

+ (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock defaults:(DIUserDefaultsBlock)defaultsBlock {
    [self injectDefaultsWithKey:keyBlock defaults:defaultsBlock forProtocol:@protocol(DIDefaults) withSync:NO withArchive:NO];
    [self injectDefaultsWithKey:keyBlock defaults:defaultsBlock forProtocol:@protocol(DIDefaultsSync) withSync:YES withArchive:NO];
    [self injectDefaultsWithKey:keyBlock defaults:defaultsBlock forProtocol:@protocol(DIDefaultsArchived) withSync:NO withArchive:YES];
    [self injectDefaultsWithKey:keyBlock defaults:defaultsBlock forProtocol:@protocol(DIDefaultsArchivedSync) withSync:YES withArchive:YES];
}

+ (void)rejectDefaults {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaults)];
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaultsSync)];
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaultsArchived)];
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaultsArchivedSync)];
}

@end
