//
//  DIForceInject.m
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DIForceInject.h"

@implementation DeluxeInjection (DIForceInject)

+ (void)forceInject:(DIPropertyGetter)block {
    [self inject:^NSArray* (Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        id value = block(targetClass, getter, propertyName, propertyClass, propertyProtocols);
        if (value == [DeluxeInjection doNotInject]) {
            return nil;
        }
        return @[DIGetterIfIvarIsNil(^id(id target) {
            return value;
        }), [DeluxeInjection doNotInject]];
    } conformingProtocol:nil];
}

+ (void)forceInjectBlock:(DIPropertyGetterBlock)block {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return @[(id)block(targetClass, getter, propertyName, propertyClass, propertyProtocols) ?: (id)[DeluxeInjection doNotInject], [DeluxeInjection doNotInject]];
    } conformingProtocol:nil];
}

+ (void)forceReject:(DIPropertyFilter)block {
    [self reject:block conformingProtocol:nil];
}

+ (void)forceRejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:nil];
}

@end
