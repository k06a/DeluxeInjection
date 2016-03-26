//
//  DIInject.m
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DIRuntimeRoutines.h"
#import "DIInject.h"

@implementation DeluxeInjection (DIInject)

+ (void)inject:(DIPropertyGetter)block {
    [self inject:^NSArray * (Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
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
    } conformingProtocol:@protocol(DIInject)];
}

+ (void)injectBlock:(DIPropertyGetterBlock)block {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return @[(id)block(targetClass, getter, propertyName, propertyClass, propertyProtocols) ?: (id)[DeluxeInjection doNotInject], [DeluxeInjection doNotInject]];
    } conformingProtocol:@protocol(DIInject)];
}

+ (void)reject:(DIPropertyFilter)block {
    [self reject:block conformingProtocol:@protocol(DIInject)];
}

+ (void)rejectAll {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DIInject)];
}

@end
