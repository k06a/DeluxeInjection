//
//  DILazy.h
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DeluxeInjectionImpl.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DILazy <NSObject>

@end

@interface NSObject (DILazy) <DILazy>

@end

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

NS_ASSUME_NONNULL_END
