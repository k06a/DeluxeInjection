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

@interface DIImperative : NSObject

/**
 *  Register plugin protocol to be scanned while injection
 *
 *  @param pluginProtocol Protocol what properties can be injected
 */
+ (void)registerPluginProtocol:(Protocol *)pluginProtocol;

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
