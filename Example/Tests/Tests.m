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

@property (strong, nonatomic) NSMutableArray<DIInject> *dynamicClassObject;
@property (strong, nonatomic) id<TestProtocol,DIInject> dynamicProtocolObject;
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

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)testInjectByClass
{
    NSArray *answer1 = @[@1,@2,@3];
    NSArray *answer2 = @[@4,@5,@6];

    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (propertyClass == [NSMutableArray class]) {
            return [answer1 mutableCopy];
        }
        return [DeluxeInjection doNotInject];
    }];
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.classObject, answer2);
    test.classObject = nil;
    XCTAssertEqualObjects(test.classObject, answer1);
}

- (void)testInjectByProtocol
{
    id answer1 = @777;
    id answer2 = @666;
    
    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyProtocols containsObject:@protocol(TestProtocol)]) {
            return answer1;
        }
        return [DeluxeInjection doNotInject];
    }];
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.protocolObject, answer1);
    test.protocolObject = answer2;
    XCTAssertEqualObjects(test.protocolObject, answer2);
    test.protocolObject = nil;
    XCTAssertEqualObjects(test.protocolObject, answer1);
}

- (void)testInjectBlock
{
    NSArray *answer1 = @[@1,@2,@3];
    NSArray *answer2 = @[@4,@5,@6];
    
    [DeluxeInjection injectBlock:^DIGetter (Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (propertyClass == [NSMutableArray class]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        return nil;
    }];
    
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceClassObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceProtocolObject)]);
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.classObject, answer2);
    test.classObject = nil;
    XCTAssertEqualObjects(test.classObject, answer1);
}

- (void)testRejectAll
{
    NSArray *answer1 = @[@1,@2,@3];
    NSArray *answer2 = @[@4,@5,@6];
    
    [DeluxeInjection injectBlock:^DIGetter (Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (propertyClass == [NSMutableArray class]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        if ([propertyProtocols containsObject:@protocol(TestProtocol)]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        return nil;
    }];

    TestType *test = [[TestType alloc] init];
    
    test.dynamicClassObject = [answer2 mutableCopy];
    test.dynamicProtocolObject = [answer2 mutableCopy];
    
    XCTAssertEqualObjects(test.dynamicClassObject, answer2);
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer2);

    XCTAssertNoThrow(test.dynamicClassObject);
    XCTAssertNoThrow(test.dynamicProtocolObject);
    XCTAssertNoThrow(test.dynamicClassObject = nil);
    XCTAssertNoThrow(test.dynamicProtocolObject = nil);
    
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(classObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(protocolObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(lazyArray)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(lazyDict)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(dynamicClassObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[TestType class] getter:@selector(dynamicProtocolObject)]);
    
    [DeluxeInjection rejectAll];
    
    XCTAssertThrows(test.dynamicClassObject);
    XCTAssertThrows(test.dynamicProtocolObject);
    XCTAssertThrows(test.dynamicClassObject = nil);
    XCTAssertThrows(test.dynamicProtocolObject = nil);
    
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceClassObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(forceProtocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(dynamicClassObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[TestType class] getter:@selector(dynamicProtocolObject)]);
}

- (void)testInjectDynamicByClass
{
    NSArray *answer1 = @[@1,@2,@3];
    NSArray *answer2 = @[@4,@5,@6];
    
    [DeluxeInjection injectBlock:^DIGetter(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
        if (propertyClass == [NSMutableArray class]) {
            return DIGetterIfIvarIsNil(^id (id target) {
                return [answer1 mutableCopy];
            });
        }
        return nil;
    }];
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.dynamicClassObject, answer1);
    test.dynamicClassObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.dynamicClassObject, answer2);
    test.dynamicClassObject = nil;
    XCTAssertEqualObjects(test.dynamicClassObject, answer1);
}

- (void)testInjectDynamicByProtocol
{
    id answer1 = @777;
    id answer2 = @666;
    
    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
        if ([protocols containsObject:@protocol(TestProtocol)]) {
            return answer1;
        }
        return [DeluxeInjection doNotInject];
    }];
    
    TestType *test = [[TestType alloc] init];
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer1);
    test.dynamicProtocolObject = answer2;
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer2);
    test.dynamicProtocolObject = nil;
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer1);
}

- (void)testDynamicWeak {
    __weak id weakAnswer = nil;
    TestType *test = [[TestType alloc] init];
    @autoreleasepool {
        id answer1 = [@[@1,@2,@3,@4,@5] mutableCopy];
        
        [DeluxeInjection forceInject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
            if ([propertyName isEqualToString:NSStringFromSelector(@selector(dynamicWeakObject))]) {
                return answer1;
            }
            return [DeluxeInjection doNotInject];
        }];
        
        weakAnswer = answer1;
        test.dynamicWeakObject = answer1;
        XCTAssertEqualObjects(weakAnswer, answer1);
        XCTAssertEqualObjects(test.dynamicWeakObject, answer1);
    }
    XCTAssertNil(weakAnswer);
    XCTAssertNil(test.dynamicWeakObject);
}

- (void)testLazy
{
    TestType *test = [[TestType alloc] init];
    [DeluxeInjection injectLazy];
    
    XCTAssertNotNil(test.lazyArray);
    XCTAssertNotNil(test.lazyDict);
    test.lazyArray = nil;
    test.lazyDict = nil;
    XCTAssertNotNil(test.lazyArray);
    XCTAssertNotNil(test.lazyDict);
}

- (void)testDefaults
{
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

- (void)testInjectPreformance {
    [self measureBlock:^{
        [DeluxeInjection inject:^id (Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            return nil;
        }];
    }];
}

- (void)testForceInjectPreformance {
    [self measureBlock:^{
        [DeluxeInjection forceInject:^id (Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
            return [DeluxeInjection doNotInject];
        }];
    }];
}

@end

