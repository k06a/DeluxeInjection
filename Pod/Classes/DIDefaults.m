//
//  DIDefaults.m
//  Pods
//
//  Created by Anton Bukov on 27.03.16.
//
//

#import "DIDefaults.h"

@implementation DeluxeInjection (DIDefaults)

+ (void)injectDefaults {
    [self injectDefaultsSynchronized:^BOOL(Class  _Nonnull __unsafe_unretained targetClass, NSString * _Nonnull propertyName, Class  _Nonnull __unsafe_unretained propertyClass, NSSet<Protocol *> * _Nonnull propertyProtocols) {
        return NO;
    }];
}

+ (void)injectDefaultsSynchronized:(DIPropertyFilter)shouldSynchronize {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        BOOL isSynchronized = shouldSynchronize(targetClass, propertyName, propertyClass, propertyProtocols);
        return @[^id(id target, id *ivar) {
            if (isSynchronized) {
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            return [[NSUserDefaults standardUserDefaults] valueForKey:propertyName];
        }, ^(id target, id *ivar, id newValue) {
            if (newValue) {
                [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:propertyName];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:propertyName];
            }
            if (isSynchronized) {
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }];
    } conformingProtocol:@protocol(DIDefaults)];
}

+ (void)rejectDefaults {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIDefaults)];
}

@end
