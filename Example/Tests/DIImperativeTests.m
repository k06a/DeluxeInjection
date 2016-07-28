//
//  DIImperativeTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 08.07.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import "AbstractTests.h"

#import <DeluxeInjection/DeluxeInjection.h>

//

@protocol DIImperativeTests_Protocol <NSObject>

@end

@interface DIImperativeTests_Class : NSObject

@property (strong, nonatomic) NSMutableArray<DIInject> *classObject;
@property (strong, nonatomic) id<DIImperativeTests_Protocol, DIInject> protocolObject;
@property (strong, nonatomic) NSMutableArray *forceClassObject;
@property (strong, nonatomic) id<DIImperativeTests_Protocol> forceProtocolObject;

@property (strong, nonatomic) NSMutableArray<DIInject> *dynamicClassObject;
@property (strong, nonatomic) id<DIImperativeTests_Protocol, DIInject> dynamicProtocolObject;
@property (weak, nonatomic) NSString *dynamicWeakObject;

@property (strong, nonatomic) NSMutableArray<NSString *><DILazy> *lazyArray;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *><DILazy> *lazyDict;

@property (strong, nonatomic) NSNumber<DIDefaults> *defaultsNumber;
@property (strong, nonatomic) NSString<DIDefaults> *defaultsString;

@end

@implementation DIImperativeTests_Class

@dynamic dynamicClassObject;
@dynamic dynamicProtocolObject;
@dynamic dynamicWeakObject;

@end

//

@interface DIImperativeTests_Class (DIImperativeTests_Category)

@property (strong, nonatomic) NSArray<DIInject> *DIImperativeTests_dynamicCategoryProperty;

@end

@implementation DIImperativeTests_Class (DIImperativeTests_Category)

@dynamic DIImperativeTests_dynamicCategoryProperty;

@end

//

@interface DIImperativeTests : AbstractTests

@end

@implementation DIImperativeTests

- (void)tearDown {
    [DeluxeInjection imperative:^(DIImperative *lets){
        [lets rejectAll];
        
        [lets skipAsserts];
    }];
    
    [super tearDown];
}

- (void)testInjectImperative {
    id answer1 = @[@1,@2,@3];
    id answer2 = @"abc";
    
    [DeluxeInjection imperative:^(DIImperative *lets){
        [[[[lets inject]
           byPropertyClass:[NSMutableArray class]]
          filterContainerClass:[DIImperativeTests_Class class]]
         getterValue:[answer1 mutableCopy]];
        
        [[[[lets inject]
           byPropertyClass:[NSArray class]]
          filterContainerClass:[DIImperativeTests_Class class]]
         getterValue:answer1];
        
        [[[[lets inject]
           byPropertyProtocol:@protocol(DIImperativeTests_Protocol)]
          filterContainerClass:[DIImperativeTests_Class class]]
         getterValue:answer2];
        
        [lets skipAsserts];
    }];
    
    DIImperativeTests_Class *test = [[DIImperativeTests_Class alloc] init];
    
    XCTAssertEqualObjects(test.classObject, answer1);
    XCTAssertTrue([test.classObject isKindOfClass:[NSMutableArray class]]);
    XCTAssertEqualObjects(test.protocolObject, answer2);
    XCTAssertEqual(test.DIImperativeTests_dynamicCategoryProperty, answer1);
}

@end
