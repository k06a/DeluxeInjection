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
 *  Force inject \b values into class properties \b not marked explicitly with any of \c <DI***> protocol.
 *
 *  @param block Block to be called on every injection into instance. Block should return objects to be injected. Return value will be used each time instance variable is \c nil.
 */
+ (void)forceInject:(DIPropertyGetter)block;

/**
 *  Force inject \b getters into class properties \b not marked explicitly with any of \c <DI***> protocol.
 *
 *  @param block Block to be called once for every marked property of all classes. Block should return \c DIGetter block to be called as getter for each object on injection or \c nil if no property injection required for this property.
 */
+ (void)forceInjectBlock:(DIPropertyGetterBlock)block;

/**
 *  Reject some injections not marked with any of \c <DI***> protocol.
 *
 *  @param block Block to determine which injections to reject, will be called for all previously injected properties \b not marked explicitly with any of \c <DI***> protocol. Returns \c BOOL which means \c YES to reject and \NO \b not to reject.
 */
+ (void)forceReject:(DIPropertyFilter)block;

/**
 *  Reject all injections \b not marked with any of \c <DI***> protocol.
 */
+ (void)forceRejectAll;

@end
