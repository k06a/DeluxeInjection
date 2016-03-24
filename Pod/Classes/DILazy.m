//
//  DILazy.m
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DILazy.h"

@implementation DeluxeInjection (DILazy)

+ (void)injectLazy {
    [self inject:^NSArray *(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return @[DIGetterIfIvarIsNil(^id(id target) {
            return [[propertyClass alloc] init];
        }), [DeluxeInjection doNotInject]];
    } conformingProtocol:@protocol(DILazy)];
}

+ (void)rejectLazy {
    [self reject:^BOOL(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return YES;
    } conformingProtocol:@protocol(DILazy)];
}

@end
