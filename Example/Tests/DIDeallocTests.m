//
//  DIDeallocTests.m
//  DeluxeInjection
//
//  Created by Антон Буков on 23.10.16.
//  Copyright © 2016 Anton Bukov. All rights reserved.
//

#import "AbstractTests.h"

#import <DeluxeInjection/DeluxeInjection.h>

@interface DIDeallocTests_Class : NSObject

@property (strong, nonatomic) NSString<DILazy> *string;

@end

@implementation DIDeallocTests_Class

@dynamic string;

- (void)dealloc {
    NSAssert(self.string, @"");
}

@end

//

@interface DIDeallocTests : AbstractTests

@end

@implementation DIDeallocTests

- (void)tearDown {
    [DeluxeInjection rejectLazy];
    
    [super tearDown];
}

- (void)testAssociatedInDealloc {
    [DeluxeInjection injectLazy];
    
    __unused DIDeallocTests_Class *obj = [DIDeallocTests_Class new];
    NSAssert(obj.string, @"");
    obj.string = nil;
}

@end
