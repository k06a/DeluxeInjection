//
//  DeluxeInjection.h
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Protocols for mark injection

@protocol DIInject <NSObject>

@end

@protocol DILazy <NSObject>

@end

#pragma mark - Block types

/**
 *  Block to be injected instead of property getter
 *
 *  @param self Receiver of selector
 *  @param _cmd Getter selector
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIGetter)(id self, SEL _cmd);

/**
 *  Block to be injected for property
 *
 *  @param target            Object with injected property
 *  @param propertyName      Injected property name
 *  @param propertyClass     Class of injected property, at least NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIPropertyGetter)(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block for property
 *
 *  @param targetClass       Class to be injected
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, at least NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injectable block \c DIGetter or \c nil for skipping injection
 */
typedef DIGetter _Nullable (^DIPropertyGetterBlock)(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to filter properties to be injected or not
 *
 *  @param targetClass       Class to be injected/deinjected
 *  @param propertyName      Property name to be injected/deinjected
 *  @param propertyClass     Class of property to be injected/deinjected, at least NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return \c YES to inject/deinject \c propertyName of \c targetClass or NO to not inject/deinject
 */
typedef BOOL (^DIPropertyFilter)(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

#pragma mark - Main injection class

@interface DeluxeInjection : NSObject

/**
 *  Inject \b values into class properties marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called on every injection into instance. Will be called during getter call each time instance variable is \c nil. Block should return objects to be injected.
 */
+ (void)inject:(DIPropertyGetter)block;

/**
 *  Inject \b getters into class properties marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called once for every marked property of all classes. Block should return \c DIGetter block to be called for each object on injection or \c nil if no injection required for this property.
 */
+ (void)injectBlock:(DIPropertyGetterBlock)block;

/**
 *  Force inject \b values into class properties even \b not marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called on every injection into instance. Will be called during getter call each time instance variable is \c nil. Block should return objects to be injected.
 */
+ (void)forceInject:(DIPropertyGetter)block;

/**
 *  Force inject \b getters into class properties even \b not marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to be called once for every marked property of all classes. Block should return \c DIGetter block to be called for each object on injection or \c nil if no property injection required for this property.
 */
+ (void)forceInjectBlock:(DIPropertyGetterBlock)block;

/**
 *  Check if \c property of \c class is injected
 *
 *  @param class  Class of property to check
 *  @param getter Class property to check
 *
 *  @return \c YES if injected, otherwise \c NO
 */
+ (BOOL)checkInjected:(Class)class getter:(SEL)getter;

/**
 *  Deinject concrete property injection
 *
 *  @param class  Class of property to deinject
 *  @param getter Class property to deinject
 */
+ (void)deinject:(Class)class getter:(SEL)getter;

/**
 *  Deinject some injections marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to determine which injections to deinject, will be called for all previously injected properties. Returns \c BOOL which means to deinject or \b not to deinject.
 */
+ (void)deinject:(DIPropertyFilter)block;

/**
 *  Deinject all injections marked explicitly with \c <DIInject> protocol.
 */
+ (void)deinjectAll;

/**
 *  Deinject some injections even \b not marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to determine which injections to deinject, will be called for all previously injected properties. Returns \c BOOL which means to deinject or \b not to deinject.
 */
+ (void)forceDeinject:(DIPropertyFilter)block;

/**
 *  Deinject all injections even \b not marked explicitly with \c <DIInject> protocol.
 */
+ (void)forceDeinjectAll;

/**
 *  Inject properties marked with \c <DILazy> protocol using block: \code ^{ return [[class alloc] init]; } \endcode
 */
+ (void)lazy;

/**
 *  Overriden \c debugDescription to see tree of classes and injected properties
 *
 *  @return String with injections info
 */
+ (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END
