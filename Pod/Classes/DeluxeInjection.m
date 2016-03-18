//
//  DeluxeInjection.m
//  MLWorks
//
//  Created by Антон Буков on 18.03.16.
//
//

#import "DIRuntimeRoutines.h"
#import "DeluxeInjection.h"

@implementation DeluxeInjection

+ (void)enumerateAllClassProperties:(void(^)(Class class, objc_property_t property))block conformingProtocols:(Protocol *)protocol {
    NSString *protocol_str = [NSString stringWithFormat:@"<%@>", NSStringFromProtocol(protocol)];
    DIRuntimeEnumerateClasses(^(Class class) {
        DIRuntimeEnumerateClassProperties(class, ^(objc_property_t property) {
            DIRuntimeEnumeratePropertyAttribute(property, "T", ^(char *value) {
                NSString *type = [NSString stringWithUTF8String:value];
                if ([type rangeOfString:protocol_str].location != NSNotFound) {
                    block(class, property);
                }
            });
        });
    });
}

+ (void)enumerate:(id(^)(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols))block conformingProtocol:(Protocol *)protocol {
    [self enumerateAllClassProperties:^(Class class, objc_property_t property) {
        DIRuntimeEnumeratePropertyGetter(property, ^(SEL getterSelector) {
            DIRuntimeEnumeratePropertyAttribute(property, "T", ^(char *propertyType) {
                id (^getter)(id) = [^(id self, SEL _cmd){
                    __block Ivar propertyIvar = nil;
                    DIRuntimeEnumeratePropertyAttribute(property, "V", ^(char *value) {
                        propertyIvar = class_getInstanceVariable(class, value);
                    });
                    if (!propertyIvar) {
                        return (id)nil;
                    }
                    
                    NSString *key = [NSString stringWithUTF8String:ivar_getName(propertyIvar)];
                    __block id value = [self valueForKey:key];
                    if (value == nil) {
                        NSString *proprtyName = [NSString stringWithUTF8String:property_getName(property)];
                        DIRuntimeEnumeratePropertyType(property, ^(Class class, NSSet<Protocol *> * protocols) {
                            NSMutableSet *protocolsWithoutDI = [protocols mutableCopy];
                            [protocolsWithoutDI removeObject:@protocol(DIInject)];
                            [protocolsWithoutDI removeObject:@protocol(DILazy)];
                            value = block(self, proprtyName, class, protocolsWithoutDI);
                        });
                        [self setValue:value forKey:key];
                    }
                    return value;
                } copy];
                
                Method method = class_getInstanceMethod(class, getterSelector);
                const char *types = method_getTypeEncoding(method);
                IMP newImp = imp_implementationWithBlock(getter);
                class_replaceMethod(class, getterSelector, newImp, types);
            });
        });
    } conformingProtocols:protocol];
}

+ (void)inject:(id(^)(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols))block {
    [self enumerate:block conformingProtocol:@protocol(DIInject)];
}

+ (void)lazy {
    [self enumerate:^(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
        return [[propertyClass alloc] init];
    } conformingProtocol:@protocol(DILazy)];
}

@end
