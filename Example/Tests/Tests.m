//
//  DeluxeInjectionTests.m
//  DeluxeInjectionTests
//
//  Copyright (c) 2016 Anton Bukov <k06aaa@gmail.com>
//

#import <XCTest/XCTest.h>

#import <DeluxeInjection/DeluxeInjection.h>

@protocol TestProtocol <NSObject>

@end

@interface TestType : NSObject

@property (strong, nonatomic) NSMutableArray<DIInject> *classObject;
@property (strong, nonatomic) id<TestProtocol, DIInject> protocolObject;
@property (strong, nonatomic) NSMutableArray *forceClassObject;
@property (strong, nonatomic) id<TestProtocol> forceProtocolObject;

@property (strong, nonatomic) NSMutableArray<DIInject> *dynamicClassObject;
@property (strong, nonatomic) id<TestProtocol, DIInject> dynamicProtocolObject;
@property (weak, nonatomic) NSString *dynamicWeakObject;

@property (strong, nonatomic) NSMutableArray<NSString *><DILazy> *lazyArray;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *><DILazy> *lazyDict;

@property (strong, nonatomic) NSNumber<DIDefaults> *defaultsNumber;
@property (strong, nonatomic) NSString<DIDefaults> *defaultsString;

@end

@implementation TestType

@dynamic dynamicClassObject;
@dynamic dynamicProtocolObject;
@dynamic dynamicWeakObject;

@end

//

@interface NSObject (TestCategory)

@property (strong, nonatomic) NSArray<DIInject> *dynamicCategoryProperty;

@end

@implementation NSObject (TestCategory)

@dynamic dynamicCategoryProperty;

@end

//

@interface Tests : XCTestCase

@end

@implementation Tests

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

- (void)testLazy {
    TestType *test = [[TestType alloc] init];
    [DeluxeInjection injectLazy];

    XCTAssertNotNil(test.lazyArray);
    XCTAssertNotNil(test.lazyDict);
    test.lazyArray = nil;
    test.lazyDict = nil;
    XCTAssertNotNil(test.lazyArray);
    XCTAssertNotNil(test.lazyDict);
}

- (void)testDefaults {
    id answer1 = @777;
    id answer2 = @"abc";

    NSString *key1 = NSStringFromSelector(@selector(defaultsNumber));
    NSString *key2 = NSStringFromSelector(@selector(defaultsString));

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key1];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key2];

    TestType *test = [[TestType alloc] init];
    [DeluxeInjection injectDefaults];

    test.defaultsNumber = answer1;
    test.defaultsString = answer2;

    XCTAssertEqualObjects(answer1, [[NSUserDefaults standardUserDefaults] objectForKey:key1]);
    XCTAssertEqualObjects(answer2, [[NSUserDefaults standardUserDefaults] objectForKey:key2]);

    test.defaultsNumber = nil;
    test.defaultsString = nil;

    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key1]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key2]);
}

- (void)testInjectImperative {
    id answer1 = @[@1,@2,@3];
    id answer2 = @"abc";

    [DeluxeInjection imperative:^(DIImperative *lets){
        [lets injectLazy];
        [lets injectDefaults];
        [lets injectDynamic];
        
        [[[lets inject] byPropertyClass:[NSMutableArray class]] getterValue:[answer1 mutableCopy]];
        [[[lets inject] byPropertyClass:[NSArray class]] getterValue:answer1];
        [[[lets inject] byPropertyProtocol:@protocol(TestProtocol)] getterValue:answer2];
        
        [lets skipAsserts];
    }];

    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.classObject, answer1);
    XCTAssertTrue([test.classObject isKindOfClass:[NSMutableArray class]]);
    XCTAssertEqualObjects(test.protocolObject, answer2);
    XCTAssertEqual(test.dynamicCategoryProperty, answer1);
}

@end
