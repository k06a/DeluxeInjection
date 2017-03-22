//
//  AbstractTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 08.07.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import <DeluxeInjection/DeluxeInjection.h>

#import "AbstractTests.h"

@implementation AbstractTests

static dispatch_group_t runTestsSequentially;

- (void)setUp {
    [super setUp];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        runTestsSequentially = dispatch_group_create();
    });
    
    dispatch_group_enter(runTestsSequentially);
}

- (void)tearDown {
    [super tearDown];
    
    XCTAssertTrue([DeluxeInjection injectedClasses].count == 0,
                  @"Some injections still exists: %@",
                  [DeluxeInjection debugDescription]);
    
    dispatch_group_leave(runTestsSequentially);
}

@end
