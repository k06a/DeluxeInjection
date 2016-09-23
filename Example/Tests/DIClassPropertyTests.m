//
//  DIClassPropertyTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 24.09.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <DeluxeInjection/DeluxeInjection.h>

//

@interface DIClassPropertyTests_Example : NSObject

@property (strong, class) NSString<DIAssociate> *classProperty;

@end

@implementation DIClassPropertyTests_Example

@dynamic classProperty;

@end

//

@interface DIClassPropertyTests : XCTestCase

@end

@implementation DIClassPropertyTests

//- (void)testClassProperty {
//    [DeluxeInjection injectAssociate];
//    
//    DIClassPropertyTests_Example.classProperty = @"test";
//    XCTAssertEqualObjects(DIClassPropertyTests_Example.classProperty, @"test");
//}

@end
