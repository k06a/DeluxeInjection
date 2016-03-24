//
//  DIForceInject.h
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DeluxeInjectionPlugin.h"

@interface DeluxeInjection (DIForceInject)

/**
 *  Force inject \b values into class properties even \b not marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called on every injection into instance. Will be called during getter call each time instance variable is \c nil. Block should return objects to be injected.
 */
+ (void)forceInject:(DIPropertyGetter)block;

/**
 *  Force inject \b getters into class properties even \b not marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called once for every marked property of all classes. Block should return \c DIGetter block to be called as getter for each object on injection or \c nil if no property injection required for this property.
 */
+ (void)forceInjectBlock:(DIPropertyGetterBlock)block;

/**
 *  Reject some injections even \b not marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to determine which injections to reject, will be called for all previously injected properties. Returns \c BOOL which means to reject or \b not to reject.
 */
+ (void)forceReject:(DIPropertyFilter)block;

/**
 *  Reject all injections and marked explicitly with \c <DIInject> and \c <DILazy> protocols.
 */
+ (void)forceRejectAll;

@end
