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

- (void)tearDown {
    [super tearDown];
    
    XCTAssertTrue([DeluxeInjection injectedClasses].count == 0,
                  @"Some injections still exists: %@",
                  [DeluxeInjection debugDescription]);
}

@end
