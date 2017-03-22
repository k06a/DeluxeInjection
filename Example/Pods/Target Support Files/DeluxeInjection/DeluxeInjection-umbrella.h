#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DeluxeInjection.h"
#import "DIAssociate.h"
#import "DIDefaults.h"
#import "DIDeluxeInjection.h"
#import "DIDeluxeInjectionPlugin.h"
#import "DIForceInject.h"
#import "DIImperative.h"
#import "DIImperativePlugin.h"
#import "DIInject.h"
#import "DIInjectPlugin.h"
#import "DILazy.h"

FOUNDATION_EXPORT double DeluxeInjectionVersionNumber;
FOUNDATION_EXPORT const unsigned char DeluxeInjectionVersionString[];

