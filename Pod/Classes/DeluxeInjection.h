//
//  DeluxeInjection.h
//  MLWorks
//
//  Created by Антон Буков on 18.03.16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DIInject <NSObject>

@end

@protocol DILazy <NSObject>

@end

@interface DeluxeInjection : NSObject

+ (void)inject:(id(^)(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols))block;
+ (void)lazy;

@end

NS_ASSUME_NONNULL_END
