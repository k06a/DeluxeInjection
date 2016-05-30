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
    [self injectDefaultsWithKeyBlock:^NSString * _Nullable(Class  _Nonnull __unsafe_unretained targetClass, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols) {
        return propertyName;
    } defaultsBlock:defaultsBlock];
}

+ (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock defaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
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

//

@implementation DIImperative (DIDefaults)

- (void)injectDefaults {
    [self injectDefaultsWithKeyBlock:^NSString * _Nullable(Class  _Nonnull __unsafe_unretained targetClass, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols) {
        return propertyName;
    } defaultsBlock:^NSUserDefaults * _Nullable(Class  _Nonnull __unsafe_unretained targetClass, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols) {
        return [NSUserDefaults standardUserDefaults];
    }];
}

- (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock {
    [self injectDefaultsWithKeyBlock:keyBlock defaultsBlock:^NSUserDefaults * _Nullable(Class  _Nonnull __unsafe_unretained targetClass, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols) {
        return [NSUserDefaults standardUserDefaults];
    }];
}

- (void)injectDefaultsWithDefaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
    [self injectDefaultsWithKeyBlock:^NSString * _Nullable(Class  _Nonnull __unsafe_unretained targetClass, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols) {
        return propertyName;
    } defaultsBlock:defaultsBlock];
}


- (void)injectDefaultsWithKeyBlock:(DIDefaultsKeyBlock)keyBlock defaultsBlock:(DIUserDefaultsBlock)defaultsBlock {
    id(^getterBlock)(NSUserDefaults *,NSString *,BOOL,BOOL,id,SEL,id*,DIOriginalGetter) = ^id(NSUserDefaults *defaults, NSString *key, BOOL withSync, BOOL withArchive, id target, SEL getter, id *ivar, DIOriginalGetter originalGetter) {
        if (withSync) {
            [defaults synchronize];
        }
        id value = [defaults objectForKey:key];
        if (withArchive && value) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:value];
        }
        return value;
    };
    
    void(^setterBlock)(NSUserDefaults *,NSString *,BOOL,BOOL,id,SEL,id*,id,DIOriginalSetter) = ^void(NSUserDefaults *defaults, NSString *key, BOOL withSync, BOOL withArchive, id target, SEL setter, id *ivar, id value, DIOriginalSetter originalSetter) {
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
    };
    
    for (Protocol *protocol in @[ @protocol(DIDefaults),
                                  @protocol(DIDefaultsSync),
                                  @protocol(DIDefaultsArchived),
                                  @protocol(DIDefaultsArchivedSync) ]) {
        BOOL withSync = [@{
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaults)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsSync)] : @YES,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchived)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchivedSync)] : @YES,
        }[protocol] boolValue];
        
        BOOL withArchive = [@{
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaults)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsSync)] : @NO,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchived)] : @YES,
            [NSValue valueWithPointer:(__bridge void *)@protocol(DIDefaultsArchivedSync)] : @YES,
        }[protocol] boolValue];
        
        [[[[self inject] byPropertyProtocol:protocol] getterBlock:^id _Nullable(Class  _Nonnull __unsafe_unretained targetClass, SEL  _Nonnull getter, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols, id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar, DIOriginalGetter  _Nullable originalGetter) {
            NSUserDefaults *defaults = defaultsBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: [NSUserDefaults standardUserDefaults];
            NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
            return getterBlock(defaults, key, withSync, withArchive, target, getter, ivar, originalGetter);
        }] setterBlock:^(Class  _Nonnull __unsafe_unretained targetClass, SEL  _Nonnull setter, NSString * _Nonnull propertyName, Class  _Nullable __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols, id  _Nonnull target, id  _Nullable __autoreleasing * _Nonnull ivar, id  _Nullable value, DIOriginalSetter  _Nullable originalSetter) {
            NSUserDefaults *defaults = defaultsBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: [NSUserDefaults standardUserDefaults];
            NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
            return setterBlock(defaults, key, withSync, withArchive, target, setter, ivar, value, originalSetter);
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
