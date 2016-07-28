//
//  Benchmarks.m
//  DeluxeInjection
//
//  Created by Антон Буков on 30.05.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import <DeluxeInjection/DeluxeInjection.h>

#import "AbstractTests.h"

@interface Benchmarks : AbstractTests

@end

@implementation Benchmarks

- (void)testInject {
    [self measureBlock:^{
        [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            return [DeluxeInjection doNotInject];
        }];
    }];
}

- (void)testForceInject {
    [self measureBlock:^{
        [DeluxeInjection forceInject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            return [DeluxeInjection doNotInject];
        }];
    }];
}

- (void)testImperative {
    [self measureBlock:^{
        [DeluxeInjection imperative:^(DIImperative *lets) {
            [lets skipAsserts];
        }];
    }];
}

@end
