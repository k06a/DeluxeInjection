//
//  DIForceInject.h
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
