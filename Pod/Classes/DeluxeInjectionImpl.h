//
//  DeluxeInjection.h
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
//
//

#import <objc/message.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Block types

/**
 *  Block to be injected instead of property getter
 *
 *  @param target Receiver of selector
 *  @param ivar Pointer to instance variable
 *
 *  @return Injected value or \c [DeluxeInjection \c doNotInject] instance to not inject this property
 */
typedef id _Nullable (^DIGetter)(id target, id _Nullable * _Nonnull ivar);

/**
 *  Block to be injected instead of property setter
 *
 *  @param target Receiver of selector
 *  @param ivar Pointer to instance variable
 *
 *  @return Injected value or \c [DeluxeInjection \c doNotInject] instance to not inject this property
 */
typedef void (^DISetter)(id target, id _Nullable * _Nonnull ivar, id value);

/**
 *  Block to be injected instead of property getter
 *
 *  @param target Receiver of selector
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIGetterWithoutIvar)(id target);

/**
 *  Block to be injected for property
 *
 *  @param targetClass       Class to be injected
 *  @param propertyName      Injected property name
 *  @param propertyClass     Class of injected property, may be \c nil in case of type \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIPropertyGetter)(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as getter for property
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Selector of getter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, may be \c nil in case of type \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injectable block \c DIGetter or \c nil for skipping injection
 */
typedef DIGetter _Nullable (^DIPropertyGetterBlock)(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as setter for property
 *
 *  @param targetClass       Class to be injected
 *  @param setter            Selector of setter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, may be \c nil in case of type \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injectable block \c DISetter or \c [DeluxeInjecion \c doNotInject] for skipping injection
 */
typedef DISetter _Nullable (^DIPropertySetterBlock)(Class targetClass, SEL setter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as setter for property
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Selector of getter method
 *  @param setter            Selector of setter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, may be \c nil in case of type \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Array of getter and settor injectable blocks or \c nil or \c [DeluxeInjecion \c doNotInject] for skipping injection
 */
typedef NSArray *_Nullable (^DIPropertyBlock)(Class targetClass, SEL getter, SEL setter, NSString *propertyName, Class _Nullable propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to filter properties to be injected or not
 *
 *  @param targetClass       Class to be injected/rejected
 *  @param propertyName      Property name to be injected/rejected
 *  @param propertyClass     Class of property to be injected/rejected, may be \c nil in case of type \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return \c YES to inject/reject \c propertyName of \c targetClass or NO to not inject/reject
 */
typedef BOOL (^DIPropertyFilter)(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

/**
 *  Helper methods to create DIGetter and DISetter with Xcode autocomplete :)
 */
DIGetter DIGetterMake(DIGetter getter);
DISetter DISetterMake(DISetter setter);

/**
 *  Transforms getter block without \c ivar argument to block with \c ivar argument this way:
 *  \code
 *return ^id(id target, id *ivar) {
 *    if (*ivar == nil) {
 *        *ivar = getter(target);
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

/**
 *  Helper to call supers getter method
 *
 *  @param target Target to call
 *  @param class  Class of current getter implementation
 *  @param getter Selector to call
 *
 *  @return Return value be supers getter
 */
id DIGetterSuperCall(id target, Class class, SEL getter);

/**
 *  Helper to call supers setter method
 *
 *  @param target Target to call
 *  @param class  Class of current setter implementation
 *  @param getter Selector to call
 *
 *  @return Return value be supers setter
 */
void DISetterSuperCall(id target, Class class, SEL setter, id value);


#pragma mark - Main injection class

@interface DeluxeInjection : NSObject

/**
 *  Shared instance to show which injections to skip as return value in \c inject: and \c forceInject: methods
 *
 *  @return Share instance of helper class
 */
+ (id)doNotInject;

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
 *  Inject concrete property getter
 *
 *  @param class  Class of property to inject
 *  @param getter Class property getter to inject
 *  @param getterBlock Block to be injected into getter
 */
+ (void)inject:(Class)class getter:(SEL)getter getterBlock:(DIGetter)getterBlock;

/**
 *  Inject concrete property setter
 *
 *  @param class  Class of property to inject
 *  @param setter Class property setter to inject
 *  @param setterBlock Block to be injected into setter
 */
+ (void)inject:(Class)class setter:(SEL)getter setterBlock:(DISetter)setterBlock;

/**
 *  Reject concrete property injection
 *
 *  @param class  Class of property to reject
 *  @param getter Class property to reject
 */
+ (void)reject:(Class)class getter:(SEL)getter;

/**
 *  Overriden \c debugDescription method to see tree of classes and injected properties
 *
 *  @return String with injections info
 */
+ (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END
