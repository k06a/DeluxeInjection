//
//  DILazy.h
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

@protocol DILazy <NSObject>

@end

@interface NSObject (DILazy) <DILazy>

@end

//

@interface DeluxeInjection (DILazy)

/**
 *  Inject properties marked with \c <DILazy> protocol using block: \code
 *if (_ivar == nil)
 *    _ivar = [[class alloc] init];
 *return _ivar
 *\endcode
 */
+ (void)injectLazy;

/**
 *  Reject all injections marked explicitly with \c <DILazy> protocol.
 */
+ (void)rejectLazy;

@end

//

@interface DIImperative (DILazy)

/**
 *  Inject properties marked with \c <DILazy> protocol using block: \code
 *if (_ivar == nil)
 *    _ivar = [[class alloc] init];
 *return _ivar
 *\endcode
 */
- (void)injectLazy;

/**
 *  Reject all injections marked explicitly with \c <DILazy> protocol.
 */
- (void)rejectLazy;

@end

NS_ASSUME_NONNULL_END
