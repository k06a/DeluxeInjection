//
//  DeluxeInjection.h
//  DeluxeInjection
//
//  Copyright (c) 2016 Anton Bukov <k06aaa@gmail.com>
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Block types

typedef id _Nullable (*DIOriginalGetter)(id target, SEL cmd);
typedef void (*DIOriginalSetter)(id target, SEL cmd, id _Nullable value);

/**
 *  Block to be injected instead of property getter
 *
 *  @param target Receiver of selector
 *  @param ivar Pointer to instance variable
 *  @param originalGetter Original getter pointer if exists
 *
 *  @return Injected value or \c [DeluxeInjection \c doNotInject] instance to not inject this property
 */
typedef id _Nullable (^DIGetter)(id target, id _Nullable * _Nonnull ivar, DIOriginalGetter _Nullable originalGetter);
typedef id _Nullable (^DIGetterWithoutOriginal)(id target, id _Nullable * _Nonnull ivar);
typedef id _Nullable (^DIGetterWithoutIvar)(id target);

/**
 *  Block to be injected instead of property setter
 *
 *  @param target Receiver of selector
 *  @param ivar Pointer to instance variable
 *  @param value New value to assign inside setter
 *  @param originalSetter Original setter pointer if exists
 */
typedef void (^DISetter)(id target, id _Nullable * _Nonnull ivar, id value, DIOriginalSetter _Nullable originalSetter);
typedef void (^DISetterWithoutOriginal)(id target, id _Nullable * _Nonnull ivar, id value);
typedef void (^DISetterWithoutIvar)(id target, id value);

/**
 *  Block to be injected for property
 *
 *  @param targetClass       Class to be injected
 *  @param propertyName      Injected property name
 *  @param propertyClass     Class of injected property, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIPropertyGetter)(Class targetClass,
                                         SEL getter,
                                         NSString *propertyName,
                                         Class _Nullable propertyClass,
                                         NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as getter for property
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Selector of getter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injectable block \c DIGetter or \c nil for skipping injection
 */
typedef DIGetter _Nullable (^DIPropertyGetterBlock)(Class targetClass,
                                                    SEL getter,
                                                    NSString *propertyName,
                                                    Class _Nullable propertyClass,
                                                    NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as setter for property
 *
 *  @param targetClass       Class to be injected
 *  @param setter            Selector of setter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Injectable block \c DISetter or \c [DeluxeInjecion \c doNotInject] for skipping injection
 */
typedef DISetter _Nullable (^DIPropertySetterBlock)(Class targetClass,
                                                    SEL setter,
                                                    NSString *propertyName,
                                                    Class _Nullable propertyClass,
                                                    NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to get injectable block as setter for property
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Selector of getter method
 *  @param setter            Selector of setter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Array of getter and settor injectable blocks or \c nil or \c [DeluxeInjecion \c doNotInject] for skipping injection
 */
typedef NSArray *_Nullable (^DIPropertyBlock)(Class targetClass,
                                              SEL getter,
                                              SEL setter,
                                              NSString *propertyName,
                                              Class _Nullable propertyClass,
                                              NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to filter properties to be injected or not
 *
 *  @param targetClass       Class to be injected/rejected
 *  @param propertyName      Property name to be injected/rejected
 *  @param propertyClass     Class of property to be injected/rejected, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return \c YES to inject/reject \c propertyName of \c targetClass or NO to not inject/reject
 */
typedef BOOL (^DIPropertyFilter)(Class targetClass,
                                 NSString *propertyName,
                                 Class _Nullable propertyClass,
                                 NSSet<Protocol *> *propertyProtocols);

/**
 *  Helper methods to create DIGetter and DISetter with Xcode autocomplete :)
 */
DIGetter DIGetterMake(DIGetterWithoutOriginal getter);
DISetter DISetterMake(DISetterWithoutOriginal setter);
DIGetter DIGetterWithOriginalMake(DIGetter getter);
DISetter DISetterWithOriginalMake(DISetter setter);

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
 *  @param klass  Class of current getter implementation
 *  @param getter Selector to call
 *
 *  @return Return value be supers getter
 */
id DIGetterSuperCall(id target, Class klass, SEL getter);

/**
 *  Helper to call supers setter method
 *
 *  @param target Target to call
 *  @param klass  Class of current setter implementation
 *  @param setter Selector to call
 */
void DISetterSuperCall(id target, Class klass, SEL setter, id value);

#pragma mark - Main injection class

@interface DeluxeInjection : NSObject

/**
 *  Shared instance to show which injections to skip as return value in \c inject: and \c forceInject: methods
 *
 *  @return Share instance of helper class
 */
+ (id)doNotInject;

/**
 *  Check if \c getter or \c setter of \c class was injected
 *
 *  @param klass  Class of property to check
 *  @param selector Selector to check
 *
 *  @return \c YES if injected, otherwise \c NO
 */
+ (BOOL)checkInjected:(Class)klass selector:(SEL)selector;

/**
 *  Get array of classes with some properties injected
 *
 *  @return Array of \c Class objects
 */
+ (NSArray<Class> *)injectedClasses;

/**
 *  Get array of selectors of injected properties
 *
 *  @param klass Class of properties
 *
 *  @return Array of \c NSStrings, should be transformed with NSSelectorFromString
 */
+ (NSArray<NSString *> *)injectedSelectorsForClass:(Class)klass;

/**
 *  Overriden \c debugDescription method to see tree of classes and injected properties
 *
 *  @return String with injections info
 */
+ (NSString *)debugDescription;

@end

NS_ASSUME_NONNULL_END
