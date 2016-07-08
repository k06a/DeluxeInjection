//
//  DIDefaultsTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 08.07.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import "AbstractTests.h"

#import <DeluxeInjection/DIDefaults.h>

//

@interface DIDefaultsTests_Class : NSObject

@property (strong, nonatomic) NSNumber<DIDefaults> *defaultsNumber;
@property (strong, nonatomic) NSString<DIDefaults> *defaultsString;

@end

@implementation DIDefaultsTests_Class

@end

//

@interface DIDefaultsTests : AbstractTests

@end

@implementation DIDefaultsTests

- (void)tearDown {
    [DeluxeInjection rejectDefaults];
    
    [super tearDown];
}

- (void)testDefaults {
    id answer1 = @777;
    id answer2 = @"abc";
    
    NSString *key1 = NSStringFromSelector(@selector(defaultsNumber));
    NSString *key2 = NSStringFromSelector(@selector(defaultsString));
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key1];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key2];
    
    [DeluxeInjection injectDefaults];
    
    DIDefaultsTests_Class *test = [[DIDefaultsTests_Class alloc] init];
    
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key1]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key2]);
    
    test.defaultsNumber = answer1;
    test.defaultsString = answer2;
    XCTAssertEqualObjects(answer1, [[NSUserDefaults standardUserDefaults] objectForKey:key1]);
    XCTAssertEqualObjects(answer2, [[NSUserDefaults standardUserDefaults] objectForKey:key2]);
    
    test.defaultsNumber = nil;
    test.defaultsString = nil;
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key1]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key2]);
}

@end
