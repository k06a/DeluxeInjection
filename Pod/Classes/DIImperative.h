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

@interface DIDeluxeInjectionImperative : NSObject

/**
 *  Inject all properties of class \c klass with \c value
 *
 *  @param klass Property class
 *  @param value Value to be injected
 */
- (void)injectByPropertyClass:(Class)klass value:(id)value;

/**
 *  Inject all properties conforming \c protocol with \c value
 *
 *  @param protocol Protocol of property
 *  @param value    Value to be injected
 */
- (void)injectByPropertyProtocol:(Protocol *)protocol value:(id)value;

/**
 *  Inject all properties of class \c klass with \c getter block
 *
 *  @param klass       Property class
 *  @param getterBlock Getter block to be injected
 */
- (void)injectByPropertyClass:(Class)klass getterBlock:(DIGetter)getterBlock;

/**
 *  Inject all properties conforming \c protocol with \c getter block
 *
 *  @param protocol    Protocol of property
 *  @param getterBlock Getter block to be injected
 */
- (void)injectByPropertyProtocol:(Protocol *)protocol getterBlock:(DIGetter)getterBlock;

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
