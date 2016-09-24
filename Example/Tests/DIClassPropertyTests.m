//
//  DIClassPropertyTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 24.09.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import "AbstractTests.h"

#import <DeluxeInjection/DeluxeInjection.h>

//

@interface DIClassPropertyTests_Example : NSObject

@property (strong, class) NSString<DIAssociate> *classProperty;

@end

@implementation DIClassPropertyTests_Example

@dynamic /*(class)*/ classProperty;

static NSUInteger setterCallsCount = 0;

+ (void)setClassProperty:(NSString<DIAssociate> *)classProperty {
    setterCallsCount++;
}

@end

//

@interface DIClassPropertyTests : AbstractTests

@end

@implementation DIClassPropertyTests

- (void)testClassProperty {
    [DeluxeInjection injectAssociate];

    NSString *answer = @"test";
    XCTAssertEqual(setterCallsCount, 0);
    
    DIClassPropertyTests_Example.classProperty = answer;
    XCTAssertEqual(setterCallsCount, 1);
    XCTAssertEqualObjects(DIClassPropertyTests_Example.classProperty, answer);
    
    DIClassPropertyTests_Example.classProperty = nil;
    XCTAssertEqual(setterCallsCount, 2);
    XCTAssertNil(DIClassPropertyTests_Example.classProperty);
    
    [DeluxeInjection rejectAssociate];
}

@end
