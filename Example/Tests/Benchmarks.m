//
//  Benchmarks.m
//  DeluxeInjection
//
//  Created by Антон Буков on 30.05.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <DeluxeInjection/DeluxeInjection.h>

@interface Benchmarks : XCTestCase

@end

@implementation Benchmarks

- (void)tearDown {
    [super tearDown];
    
    [DeluxeInjection rejectAll];
    [DeluxeInjection rejectLazy];
    [DeluxeInjection rejectDefaults];
    [DeluxeInjection forceRejectAll];
    
    [self testZNothing];
}

- (void)testZNothing {
    XCTAssertTrue([[DeluxeInjection debugDescription] rangeOfString:@"Nothing"].location != NSNotFound);
    if ([[DeluxeInjection debugDescription] rangeOfString:@"Nothing"].location == NSNotFound) {
        NSLog(@"XXX: %@", [DeluxeInjection debugDescription]);
    }
}

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
