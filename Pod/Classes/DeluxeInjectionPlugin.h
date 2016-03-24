//
//  DeluxeInjectionPlugin.h
//  MLWorks
//
//  Created by Anton Bukov on 24.03.16.
//
//

#import "DeluxeInjectionImpl.h"

@interface DeluxeInjection (Plugin)

+ (void)inject:(DIPropertyBlock)block conformingProtocol:(Protocol *)protocol;
+ (void)reject:(DIPropertyFilter)block conformingProtocol:(Protocol *)protocol;

@end
