//
//  DeluxeInjectionTests.m
//  DeluxeInjectionTests
//
//  Created by Anton Bukov on 03/18/2016.
//  Copyright (c) 2016 Anton Bukov. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <DeluxeInjection/DeluxeInjection.h>

@protocol TestProtocol <NSObject>

@end

@interface TestType : NSObject

@property (strong, nonatomic) NSMutableArray<DIInject> *classObject;
@property (strong, nonatomic) id<TestProtocol,DIInject> protocolObject;
@property (strong, nonatomic) NSMutableArray *forceClassObject;
@property (strong, nonatomic) id<TestProtocol> forceProtocolObject;

@property (strong, nonatomic) NSMutableArray<NSString *><DILazy> *lazyArray;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *><DILazy> *lazyDict;

@end

@implementation TestType

@end

//

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInjectByClass
{
    NSArray *answer1 = @[@1,@2,@3];
    NSArray *answer2 = @[@4,@5,@6];

    [DeluxeInjection inject:^id(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
        if (propertyClass == [NSMutableArray class]) {
            return [answer1 mutableCopy];
        }
        return nil;
    }];
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = nil;
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.classObject, answer2);
}

- (void)testInjectByProtocol
{
    id answer1 = @777;
    
    [DeluxeInjection inject:^id(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
        if ([protocols containsObject:@protocol(TestProtocol)]) {
            return [NSObject new];
        }
        return nil;
    }];
    
    TestType *test = [[TestType alloc] init];
    XCTAssertNotNil(test.protocolObject);
    test.protocolObject = nil;
    XCTAssertNotNil(test.protocolObject);
    test.protocolObject = answer1;
    XCTAssertEqualObjects(test.protocolObject, answer1);
}

- (void)testInjectBlock
{
    NSArray *answer1 = @[@1,@2,@3];
    NSArray *answer2 = @[@4,@5,@6];
    
    [DeluxeInjection injectBlock:^DIGetter (Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (propertyClass == [NSMutableArray class]) {
            return ^id(id self, SEL _cmd) {
                return [answer1 mutableCopy];
            };
        }
        return nil;
    }];
    
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceClassObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceProtocolObject)]);
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = nil;
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.classObject, answer2);
}

- (void)testRejectAll
{
    [DeluxeInjection injectBlock:^DIGetter (Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (propertyClass == [NSMutableArray class]) {
            return ^id(id self, SEL _cmd) {
                return @[];
            };
        }
        return nil;
    }];
    
    [DeluxeInjection rejectAll];
    
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceClassObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceProtocolObject)]);
}

- (void)testLazy
{
    TestType *test = [[TestType alloc] init];
    [DeluxeInjection lazyInject];
    
    XCTAssertNotNil(test.lazyArray);
    XCTAssertNotNil(test.lazyDict);
    test.lazyArray = nil;
    test.lazyDict = nil;
    XCTAssertNotNil(test.lazyArray);
    XCTAssertNotNil(test.lazyDict);
}

- (void)testPreformance {
    [self measureBlock:^{
        [DeluxeInjection inject:^id (id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            return nil;
        }];
    }];
}

@end

