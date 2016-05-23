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

/**
 *  Block to filter properties to be injected
 *
 *  @param targetClass       Class to be injected
 *  @param getter            Selector of getter method
 *  @param propertyName      Property name to be injected
 *  @param propertyClass     Class of property to be injected, at least \c NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return \c YES to inject property, \c NO to skip injection
 */
typedef BOOL (^DIPropertyFilterBlock)(Class targetClass, SEL getter, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

//

@interface DIDeluxeInjectionImperativeInjector : NSObject

/**
 *  Set value to be injected
 *
 *  @param valueObject Value to be injected
 */
- (instancetype)valueObject:(id)valueObject;

/**
 *  Set value block to be injected
 *
 *  @param valueBlock Value block to be injected
 */
- (instancetype)valueBlock:(DIGetter)valueBlock;

/**
 *  Set filter class for conditional injection
 *
 *  @param filterClass Class which sublasses properties can be injected
 */
- (instancetype)filterClass:(Class)filterClass;

/**
 *  Set filter block for conditional injection
 *
 *  @param filterBlock Block which define what properties can be injected
 */
- (instancetype)filterBlock:(DIPropertyFilterBlock)filterBlock;

@end

//

@interface DIDeluxeInjectionImperative : NSObject

/**
 *  Inject all properties of class \c klass with \c value
 *
 *  @param klass Property class
 *
 *  @return Injector object to define value and options to be injected
 */
- (DIDeluxeInjectionImperativeInjector *)injectByPropertyClass:(Class)klass;

/**
 *  Inject all properties conforming \c protocol with \c value
 *
 *  @param protocol Protocol of property
 *
 *  @return Injector object to define value and options to be injected
 */
- (DIDeluxeInjectionImperativeInjector *)injectByPropertyProtocol:(Protocol *)protocol;

@end

//

/**
 *  Block to apply imperative injections
 *
 *  @param lets Object to apply imperative injections
 */
typedef void (^DIImperativeBlock)(DIDeluxeInjectionImperative *lets);

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
