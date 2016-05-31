//
//  DIImperative.h
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

#import "DIDeluxeInjection.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Block to filter properties to be injected
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Selector of getter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return \c YES to inject property, \c NO to skip injection
 */
typedef BOOL (^DIPropertyFilterBlock)(Class targetClass,
                                      SEL getter,
                                      NSString * propertyName,
                                      Class _Nullable propertyClass,
                                      NSSet<Protocol *> *propertyProtocols);

/**
 *  Block to be injected for property getter
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Property getter selector
 *  @param propertyName      Injected property name
 *  @param propertyClass     Class of injected property, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *  @param target            Receiver of selector
 *  @param ivar              Pointer to instance variable
 *  @param originalGetter    Original setter pointer if exists
 *
 *  @return Injected value or \c nil
 */
typedef id _Nullable (^DIImperativeGetter)(Class targetClass,
                                           SEL getter,
                                           NSString *propertyName,
                                           Class _Nullable propertyClass,
                                           NSSet<Protocol *> *propertyProtocols,
                                           id target,
                                           id _Nullable * _Nonnull ivar,
                                           DIOriginalGetter _Nullable originalGetter);

/**
 *  Block to be injected for property setter
 *
 *  @param targetClass       Class to be injected
 *  @param setter            Property setter selector
 *  @param propertyName      Injected property name
 *  @param propertyClass     Class of injected property, \c nil in case of \c id
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *  @param target            Receiver of selector
 *  @param ivar              Pointer to instance variable
 *  @param value             New value to assign inside setter
 *  @param originalSetter    Original setter pointer if exists
 */
typedef void (^DIImperativeSetter)(Class targetClass,
                                   SEL setter,
                                   NSString *propertyName,
                                   Class _Nullable propertyClass,
                                   NSSet<Protocol *> *propertyProtocols,
                                   id target,
                                   id _Nullable * _Nonnull ivar,
                                   id _Nullable value,
                                   DIOriginalSetter _Nullable originalSetter);


//

@interface DIImperativeInjector : NSObject


#pragma mark - Property injection type

/**
 *  Set property \c klass to be injected
 *
 *  @param klass Property class
 */
- (instancetype)byPropertyClass:(Class)klass;

/**
 *  Set property \c protocol to be injected
 *
 *  @param protocol Protocol of property
 */
- (instancetype)byPropertyProtocol:(Protocol *)protocol;

/**
 *  Set value to be injected
 *
 *  @param getterValue Value to be injected
 */
- (instancetype)getterValue:(id)getterValue;

#pragma mark - Property injection value or blocks

/**
 *  Set getter block to be injected
 *
 *  @param getterBlock Value block to be injected
 */
- (instancetype)getterBlock:(DIImperativeGetter)getterBlock;

/**
 *  Set setter block to be injected
 *
 *  @param setterBlock Value block to be injected
 */
- (instancetype)setterBlock:(DIImperativeSetter)setterBlock;

#pragma mark - Property injection filtering

/**
 *  Set filter block for conditional injection
 *
 *  @param filterBlock Block which define what properties can be injected
 */
- (instancetype)filterBlock:(DIPropertyFilterBlock)filterBlock;

/**
 *  Set filter class for conditional injection
 *
 *  @param filterContainerClass Class which sublasses properties can be injected
 */
- (instancetype)filterContainerClass:(Class)filterContainerClass;

@end

//

@interface DIImperative : NSObject

/**
 *  Register plugin protocol to be scanned while injection
 *
 *  @param pluginProtocol Protocol what properties can be injected
 */
+ (void)registerPluginProtocol:(Protocol *)pluginProtocol;

/**
*  Create injector object
*
*  @return injector object
*/
- (DIImperativeInjector *)inject;

/**
 *  Create rejector object
 *
 *  @return rejector object
 */
- (DIImperativeInjector *)reject;

/**
 *  Debug method to skip asserts
 */
- (void)skipAsserts;

@end

//

/**
 *  Block to apply imperative injections
 *
 *  @param lets Object to apply imperative injections
 */
typedef void (^DIImperativeBlock)(DIImperative *lets);

@interface DeluxeInjection (DIImperative)

/**
 *  Method to apply imperative injections inside block. All properties
 *  marked with \c DIInject protocol should be injected at least once.
 *  Properties who will be injected several times will be logged to \c NSLog().
 *
 *  @param block Block to apply imperative injections
 */
+ (void)imperative:(DIImperativeBlock)block;

@end

NS_ASSUME_NONNULL_END
