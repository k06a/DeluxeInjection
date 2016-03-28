//
//  DIInject.h
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DeluxeInjectionPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DIInject <NSObject>

@end

@interface NSObject (DIInject) <DIInject>

@end

@interface DeluxeInjection (DIInject)

/**
 *  Inject \b values into class properties marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called on every injection into instance. Will be called during getter call each time instance variable is \c nil. Block should return objects to be injected.
 */
+ (void)inject:(DIPropertyGetter)block;

/**
 *  Inject \b getters into class properties marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called once for every marked property of all classes. Block should return \c DIGetter block to be called as getter for each object on injection or \c nil if no injection required for this property.
 */
+ (void)injectBlock:(DIPropertyGetterBlock)block;

/**
 *  Reject some injections marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to determine which injections to reject, will be called for all previously injected properties. Returns \c BOOL which means to reject or \b not to reject.
 */
+ (void)reject:(DIPropertyFilter)block;

/**
 *  Reject all injections marked explicitly with \c <DIInject> protocol.
 */
+ (void)rejectAll;

@end

NS_ASSUME_NONNULL_END
