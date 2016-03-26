//
//  DIDefaults.h
//  Pods
//
//  Created by Anton Bukov on 27.03.16.
//
//

#import "DeluxeInjectionPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DIDefaults <NSObject>

@end

@interface DeluxeInjection (DIDefaults)

/**
 *  Inject properties marked with \c <DIDefaults> protocol using NSUserDefaults access
 */
+ (void)injectDefaults;

/**
 *  Inject properties marked with \c <DIDefaults> protocol
 *  using NSUserDefaults access with optional sychronization
 */
+ (void)injectDefaultsSynchronized:(DIPropertyFilter)block;

/**
 *  Reject all injections marked explicitly with \c <DIDefaults> protocol.
 */
+ (void)rejectDefaults;

@end

NS_ASSUME_NONNULL_END
