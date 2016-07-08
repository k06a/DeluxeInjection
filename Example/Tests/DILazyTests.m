//
//  DILazyTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 08.07.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import "AbstractTests.h"

#import <DeluxeInjection/DILazy.h>

//

@interface DILazyTests_Class : NSObject

@property (strong, nonatomic) NSMutableArray<NSString *><DILazy> *lazyArray;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *><DILazy> *lazyDict;

@end

@implementation DILazyTests_Class

@end

//

@interface DILazyTests : AbstractTests

@end

@implementation DILazyTests

- (void)tearDown {
    [DeluxeInjection rejectLazy];
    
    [super tearDown];
}

- (void)testLazy {
    [DeluxeInjection injectLazy];
    
    DILazyTests_Class *test = [[DILazyTests_Class alloc] init];
    
    [test.lazyArray addObject:@"object"];
    test.lazyDict[@"key"] = @"value";
    XCTAssertTrue([test.lazyArray isKindOfClass:[NSMutableArray class]]);
    XCTAssertTrue([test.lazyDict isKindOfClass:[NSMutableDictionary class]]);
    XCTAssertTrue(test.lazyArray.count == 1);
    XCTAssertTrue(test.lazyDict.count == 1);
    
    test.lazyArray = nil;
    test.lazyDict = nil;
    XCTAssertTrue([test.lazyArray isKindOfClass:[NSMutableArray class]]);
    XCTAssertTrue([test.lazyDict isKindOfClass:[NSMutableDictionary class]]);
    XCTAssertTrue(test.lazyArray.count == 0);
    XCTAssertTrue(test.lazyDict.count == 0);
    
}

@end
