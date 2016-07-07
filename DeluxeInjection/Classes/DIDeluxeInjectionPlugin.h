//
//  DIDeluxeInjectionPlugin.h
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

#import <objc/runtime.h>

#import "DIDeluxeInjection.h"

NS_ASSUME_NONNULL_BEGIN

@interface DeluxeInjection (Plugin)

+ (void)inject:(DIPropertyBlock)block conformingProtocols:(NSArray<Protocol *> * _Nullable)protocols;
+ (void)reject:(DIPropertyFilter)block conformingProtocols:(NSArray<Protocol *> * _Nullable)protocols;

/**
 *  Inject concrete property getter
 *
 *  @param klass  Class of property to inject
 *  @param property Class property to inject
 *  @param getterBlock Block to be injected into getter
 *  @param setterBlock Block to be injected into setter
 */
+ (void)inject:(Class)klass property:(objc_property_t)property getterBlock:(DIGetter)getterBlock setterBlock:(DISetter)setterBlock;

@end

NS_ASSUME_NONNULL_END
