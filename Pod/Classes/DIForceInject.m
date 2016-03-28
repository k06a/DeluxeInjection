//
//  DIForceInject.m
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DIRuntimeRoutines.h"
#import "DIForceInject.h"

#import "DIInject.h"
#import "DILazy.h"
#import "DIDefaults.h"

static NSSet *excudeProtocols() {
    static NSSet *excudeProtocols;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excudeProtocols = [NSSet setWithArray:@[
            @protocol(DIInject),
            @protocol(DILazy),
            @protocol(DIDefaults),
            @protocol(DIDefaultsSync),
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
        
        objc_property_t property = DIRuntimeEnumerateClassGetProperty(targetClass, propertyName);
        if (DIRuntimeGetPropertyIsWeak(property)) {
            __weak id weakValue = value;
            return @[DIGetterIfIvarIsNil(^id(id target) {
                return weakValue;
            }), [DeluxeInjection doNotInject]];
        } else {
            return @[DIGetterIfIvarIsNil(^id(id target) {
                return value;
            }), [DeluxeInjection doNotInject]];
        }
    } conformingProtocol:nil];
}

+ (void)forceInjectBlock:(DIPropertyGetterBlock)block {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return nil;
        }
        return @[(id)block(targetClass, getter, propertyName, propertyClass, propertyProtocols) ?: (id)[DeluxeInjection doNotInject], [DeluxeInjection doNotInject]];
    } conformingProtocol:nil];
}

+ (void)forceReject:(DIPropertyFilter)block {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return NO;
        }
        return block(targetClass, propertyName, propertyClass, propertyProtocols);
    } conformingProtocol:nil];
}

+ (void)forceRejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols intersectsSet:excudeProtocols()]) {
            return NO;
        }
        return YES;
    } conformingProtocol:nil];
}

@end
