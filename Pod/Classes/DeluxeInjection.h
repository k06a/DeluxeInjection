//
//  DeluxeInjection.h
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Protocols for explicit mark injections

@protocol DIInject <NSObject>

@end

@protocol DILazy <NSObject>

@end

#pragma mark - Block types

/**
 *  Block to be injected instead of property getter
 *
 *  @param self Receiver of selector
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIGetterWithoutIvar)(id self);

/**
 *  Block to be injected instead of property getter
 *
 *  @param self Receiver of selector
 *  @param ivar Pointer to instance variable
 *
 *  @return Injected value or \c [DIDoNotInject \c it] instance to not inject this property
 */
typedef id _Nullable (^DIGetter)(id self, id _Nullable * _Nonnull ivar);

/**
 *  Block to be injected for property
 *
 *  @param targetClass       Class to be injected
 *  @param propertyName      Injected property name
 *  @param propertyClass     Class of injected property, at least NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIPropertyGetter)(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as getter for property
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
 *  @param targetClass       Class to be injected/rejected
 *  @param propertyName      Property name to be injected/rejected
 *  @param propertyClass     Class of property to be injected/rejected, at least NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return \c YES to inject/reject \c propertyName of \c targetClass or NO to not inject/reject
 */
typedef BOOL (^DIPropertyFilter)(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Transforms getter block without \c ivar argument to block with \c ivar argument this way:
 *  \code
 *return ^id(id self, id *ivar) {
 *    if (*ivar == nil) {
 *        *ivar = getter(self);
 *    }
 *    return *ivar;
 *};
 *  \endcode
 *
 *  @param getter Block without \c ivar argument
 *
 *  @return Block with \c ivar argument
 */
DIGetter DIGetterIfIvarIsNil(DIGetterWithoutIvar getter);

#pragma mark - Helper class to show what to not inject

@interface DIDoNotInject : NSObject

/**
 *  Shared instance to show which injections to skip as return value in \c inject: and \c forceInject: methods
 *
 *  @return Share instance of helper class
 */
+ (instancetype)it;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - Main injection class

@interface DeluxeInjection : NSObject

#pragma mark Single property injectors

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
 *  Inject concrete property
 *
 *  @param class  Class of property to inject
 *  @param getter Class property to inject
 */
+ (void)inject:(Class)class getter:(SEL)getter block:(DIGetter)block;

/**
 *  Reject concrete property injection
 *
 *  @param class  Class of property to reject
 *  @param getter Class property to reject
 */
+ (void)reject:(Class)class getter:(SEL)getter;

#pragma mark Mass injectors / rejectors

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
 *  Reject some injections marked explicitly with \c <DIInject> protocol.
 *
 *  @param block Block to determine which injections to reject, will be called for all previously injected properties. Returns \c BOOL which means to reject or \b not to reject.
 */
+ (void)reject:(DIPropertyFilter)block;

/**
 *  Reject all injections marked explicitly with \c <DIInject> protocol.
 */
+ (void)rejectAll;

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

/**
 *  Inject properties marked with \c <DILazy> protocol using block: \code ^{ return [[class alloc] init]; } \endcode
 */
+ (void)lazyInject;

/**
 *  Reject all injections marked explicitly with \c <DILazy> protocol.
 */
+ (void)lazyReject;

/**
 *  Overriden \c debugDescription method to see tree of classes and injected properties
 *
 *  @return String with injections info
 */
+ (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END
