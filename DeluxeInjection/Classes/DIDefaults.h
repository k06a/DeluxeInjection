//
//  DIDefaults.h
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

@protocol DIDefaults <NSObject>

@end

@protocol DIDefaultsSync <NSObject>

@end

@protocol DIDefaultsArchived <NSObject>

@end

@protocol DIDefaultsArchivedSync <NSObject>

@end

@interface NSObject (DIDefaults) <DIDefaults, DIDefaultsSync, DIDefaultsArchived, DIDefaultsArchivedSync>

@end

/**
 *  Block to define custom key for properties to store in NSUserDefaults
 *
 *  @param targetClass       Class to be injected/rejected
 *  @param propertyName      Property name to be injected/rejected
 *  @param propertyClass     Class of property to be injected/rejected, at least \c NSObject
 *  @param propertyProtocols Set of property protocols including all superprotocols
 *
 *  @return Key to store in \c NSUserDefaults for propertyName of \c targetClass or \c nil to use \c propertyName
 */
typedef NSString * _Nullable (^DIDefaultsKeyBlock)(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols);

@interface DeluxeInjection (DIDefaults)

/**
 *  Inject properties marked with \c <DIDefaults> and \c <DIDefaultsSync> protocol using NSUserDefaults access
 */
+ (void)injectDefaults;

/**
 *  Inject properties marked with \c <DIDefaults> and \c <DIDefaultsSync> protocol
 *  using NSUserDefaults access with custom key provided by block
 */
+ (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock;

/**
 *  Reject all injections marked explicitly with \c <DIDefaults> and \c <DIDefaultsSync> protocol.
 */
+ (void)rejectDefaults;

@end

NS_ASSUME_NONNULL_END
