//
//  DIInjectTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 07.07.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <DeluxeInjection/DIInject.h>

//

@protocol DIInjectTests_Protocol <NSObject>

@end

@interface DIInjectTests_Class : NSObject

@property (strong, nonatomic) NSMutableArray<DIInject> *classObject;
@property (strong, nonatomic) id<DIInjectTests_Protocol, DIInject> protocolObject;

@property (strong, nonatomic) NSMutableArray<DIInject> *dynamicClassObject;
@property (strong, nonatomic) id<DIInjectTests_Protocol, DIInject> dynamicProtocolObject;
@property (weak, nonatomic) NSString<DIInject> *dynamicWeakObject;

@end

@implementation DIInjectTests_Class

@dynamic dynamicClassObject;
@dynamic dynamicProtocolObject;
@dynamic dynamicWeakObject;

@end

//

@interface NSObject (DIInjectTests_Category)

@property (strong, nonatomic) NSArray<DIInject> *DIInjectTests_dynamicCategoryProperty;

@end

@implementation NSObject (DIInjectTests_Category)

@dynamic DIInjectTests_dynamicCategoryProperty;

@end

//

@interface DIInjectTests : XCTestCase

@end

@implementation DIInjectTests

- (void)tearDown {
    [super tearDown];
    
    [DeluxeInjection rejectAll];
    
    [self testZNothing];
}

- (void)testZNothing {
    XCTAssertTrue([[DeluxeInjection debugDescription] rangeOfString:@"Nothing"].location != NSNotFound);
    if ([[DeluxeInjection debugDescription] rangeOfString:@"Nothing"].location != NSNotFound) {
        NSLog(@"%@", [DeluxeInjection debugDescription]);
    }
}

- (void)testInjectByClass {
    NSArray *answer1 = @[ @1, @2, @3 ];
    NSArray *answer2 = @[ @4, @5, @6 ];
    
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setClassObject:)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setProtocolObject:)]);
    
    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (targetClass == [DIInjectTests_Class class] && propertyClass == [NSMutableArray class]) {
            return [answer1 mutableCopy];
        }
        return [DeluxeInjection doNotInject];
    }];
    
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setClassObject:)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setProtocolObject:)]);
    
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.classObject, answer2);
    test.classObject = nil;
    XCTAssertEqualObjects(test.classObject, answer1);
}

- (void)testInjectByProtocol {
    id answer1 = @777;
    id answer2 = @666;
    
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setClassObject:)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setProtocolObject:)]);
    
    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (targetClass == [DIInjectTests_Class class] && [propertyProtocols containsObject:@protocol(DIInjectTests_Protocol)]) {
            return answer1;
        }
        return [DeluxeInjection doNotInject];
    }];
    
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setClassObject:)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setProtocolObject:)]);
    
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    
    XCTAssertEqualObjects(test.protocolObject, answer1);
    test.protocolObject = answer2;
    XCTAssertEqualObjects(test.protocolObject, answer2);
    test.protocolObject = nil;
    XCTAssertEqualObjects(test.protocolObject, answer1);
}

- (void)testInjectBlock {
    NSArray *answer1 = @[ @1, @2, @3 ];
    NSArray *answer2 = @[ @4, @5, @6 ];
    
    [DeluxeInjection injectBlock:^DIGetter(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (targetClass == [DIInjectTests_Class class] && propertyClass == [NSMutableArray class]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        return nil;
    }];
    
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    
    XCTAssertEqualObjects(test.classObject, answer1);
    test.classObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.classObject, answer2);
    test.classObject = nil;
    XCTAssertEqualObjects(test.classObject, answer1);
}

- (void)testRejectAll {
    NSArray *answer1 = @[ @1, @2, @3 ];
    NSArray *answer2 = @[ @4, @5, @6 ];
    NSString *answer3 = @"hello";
    NSString *answer4 = @"bye";
    
    [DeluxeInjection injectBlock:^DIGetter(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if (targetClass == [DIInjectTests_Class class] && propertyClass == [NSString class]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return answer3;
            });
        }
        if (targetClass == [DIInjectTests_Class class] && propertyClass == [NSMutableArray class]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        if (targetClass == [DIInjectTests_Class class] && [propertyProtocols containsObject:@protocol(DIInjectTests_Protocol)]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        return nil;
    }];
    
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    
    XCTAssertEqualObjects(test.dynamicClassObject, answer1);
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer1);
    XCTAssertEqualObjects(test.dynamicWeakObject, answer3);
    test.dynamicClassObject = [answer2 mutableCopy];
    test.dynamicProtocolObject = [answer2 mutableCopy];
    test.dynamicWeakObject = answer4;
    XCTAssertEqualObjects(test.dynamicClassObject, answer2);
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer2);
    XCTAssertEqualObjects(test.dynamicWeakObject, answer4);
    test.dynamicClassObject = nil;
    test.dynamicProtocolObject = nil;
    test.dynamicWeakObject = nil;
    XCTAssertEqualObjects(test.dynamicClassObject, answer1);
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer1);
    XCTAssertEqualObjects(test.dynamicWeakObject, answer3);
    
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(dynamicClassObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(dynamicProtocolObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(dynamicWeakObject)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setDynamicClassObject:)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setDynamicProtocolObject:)]);
    XCTAssertTrue([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setDynamicWeakObject:)]);
    
    [DeluxeInjection rejectAll];
    
    XCTAssertThrows(test.dynamicClassObject);
    XCTAssertThrows(test.dynamicProtocolObject);
    XCTAssertThrows(test.dynamicWeakObject);
    XCTAssertThrows(test.dynamicClassObject = nil);
    XCTAssertThrows(test.dynamicProtocolObject = nil);
    XCTAssertThrows(test.dynamicWeakObject = nil);
    
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(classObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(protocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(dynamicClassObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(dynamicProtocolObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(dynamicWeakObject)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setDynamicClassObject:)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setDynamicProtocolObject:)]);
    XCTAssertFalse([DeluxeInjection checkInjected:[DIInjectTests_Class class] selector:@selector(setDynamicWeakObject:)]);
}

- (void)testInjectDynamicByClass {
    NSArray *answer1 = @[ @1, @2, @3 ];
    NSArray *answer2 = @[ @4, @5, @6 ];
    
    [DeluxeInjection injectBlock:^DIGetter(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
        if (targetClass == [DIInjectTests_Class class] && propertyClass == [NSMutableArray class]) {
            return DIGetterIfIvarIsNil(^id(id target) {
                return [answer1 mutableCopy];
            });
        }
        return nil;
    }];
    
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    
    XCTAssertEqualObjects(test.dynamicClassObject, answer1);
    test.dynamicClassObject = [answer2 mutableCopy];
    XCTAssertEqualObjects(test.dynamicClassObject, answer2);
    test.dynamicClassObject = nil;
    XCTAssertEqualObjects(test.dynamicClassObject, answer1);
}

- (void)testInjectDynamicByProtocol {
    id answer1 = @777;
    id answer2 = @666;
    
    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
        if (targetClass == [DIInjectTests_Class class] && [protocols containsObject:@protocol(DIInjectTests_Protocol)]) {
            return answer1;
        }
        return [DeluxeInjection doNotInject];
    }];
    
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer1);
    test.dynamicProtocolObject = answer2;
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer2);
    test.dynamicProtocolObject = nil;
    XCTAssertEqualObjects(test.dynamicProtocolObject, answer1);
}

- (void)testDynamicWeak {
    __weak id weakAnswer = nil;
    DIInjectTests_Class *test = [[DIInjectTests_Class alloc] init];
    @autoreleasepool {
        id answer1 = [@[ @1, @2, @3, @4, @5 ] mutableCopy];
        
        [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
            if (targetClass == [DIInjectTests_Class class] && [propertyName isEqualToString:NSStringFromSelector(@selector(dynamicWeakObject))]) {
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

- (void)testInjectToCategory {
    NSArray *answer1 = @[ @1, @2, @3 ];
    NSArray *answer2 = @[ @4, @5, @6 ];
    
    [DeluxeInjection inject:^id(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        if ([propertyName isEqualToString:NSStringFromSelector(@selector(DIInjectTests_dynamicCategoryProperty))]) {
            return answer1;
        }
        return [DeluxeInjection doNotInject];
    }];
    
    NSObject *test = [[NSObject alloc] init];
    
    XCTAssertEqualObjects(test.DIInjectTests_dynamicCategoryProperty, answer1);
    test.DIInjectTests_dynamicCategoryProperty = answer2;
    XCTAssertEqualObjects(test.DIInjectTests_dynamicCategoryProperty, answer2);
    test.DIInjectTests_dynamicCategoryProperty = nil;
    XCTAssertEqualObjects(test.DIInjectTests_dynamicCategoryProperty, answer1);
}

@end
