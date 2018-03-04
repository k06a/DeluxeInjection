//
//  DIInject.h
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
#import "DIImperative.h"

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

//

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

/**
 *  Helper methods to create DIImperativeGetter and DIImperativeSetter with Xcode autocomplete :)
 */
DIImperativeGetter DIImperativeGetterMake(DIImperativeGetter getter);
DIImperativeSetter DIImperativeSetterMake(DIImperativeSetter setter);


/**
 *  Helper methods to create DIImperativeGetter and DIImperativeSetter with DIGetter and DISetter
 */
DIImperativeGetter DIImperativeGetterFromGetter(DIGetter getter);
DIImperativeSetter DIImperativeSetterFromSetter(DISetter getter);

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
- (instancetype)getterValue:(nullable id)getterValue;

/**
 *  Set value to be injected by lazy block
 *
 *  @param lazyBlock Block to be called on first access only
 */
- (instancetype)getterValueLazy:(id(^)(void))lazyBlock;

/**
 *  Set value to be injected by class
 *
 *  @param lazyClass Class value to be injected with alloc-init
 */
- (instancetype)getterValueLazyByClass:(Class)lazyClass;

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

@interface DIImperative (DIInject)

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
 *  Reject all injected properties marked with \c DIInject
 */
- (void)rejectAll;

@end

NS_ASSUME_NONNULL_END
