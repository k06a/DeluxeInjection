//
//  DIDefaults.m
//  Pods
//
//  Created by Anton Bukov on 27.03.16.
//
//

#import "DeluxeInjectionPlugin.h"
#import "DIDefaults.h"

@implementation NSObject (DIDefaults)

@end

@implementation DeluxeInjection (DIDefaults)

#pragma mark - Private

+ (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock forProtocol:(Protocol *)protocol withSync:(BOOL)withSync {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        NSString *key = keyBlock(targetClass, propertyName, propertyClass, propertyProtocols) ?: propertyName;
        return @[^id(id target, id *ivar) {
            if (withSync) {
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            return [[NSUserDefaults standardUserDefaults] objectForKey:key];
        }, ^(id target, id *ivar, id newValue) {
            [[NSUserDefaults standardUserDefaults] setValue:newValue forKey:key];
            if (withSync) {
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }];
    } conformingProtocol:protocol];
}

#pragma mark - Public

+ (void)injectDefaults {
    [self injectDefaultsWithKey:^NSString *(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return propertyName;
    }];
}

+ (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock {
    [self injectDefaultsWithKey:keyBlock forProtocol:@protocol(DIDefaults) withSync:NO];
    [self injectDefaultsWithKey:keyBlock forProtocol:@protocol(DIDefaultsSync) withSync:YES];
}

+ (void)rejectDefaults {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaults)];
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaultsSync)];
}

@end
