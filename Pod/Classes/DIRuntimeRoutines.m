//
//  DIRuntimeRoutines.m
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

#import "DIRuntimeRoutines.h"

void DIRuntimeEnumerateClasses(void (^block)(Class class)) {
    DIRuntimeEnumerateClassSubclasses([NSObject class], block);
}

void DIRuntimeEnumerateClassSubclasses(Class parentclass, void (^block)(Class class)) {
    Class *classes = objc_copyClassList(NULL);
    for (Class *cursor = classes; classes && *cursor; cursor++) {
        // Filter only NSObject subclasses
        Class superclass = *cursor;
        while (superclass && superclass != parentclass) {
            superclass = class_getSuperclass(superclass);
        }
        if (!superclass) {
            continue;
        }
        
        block(*cursor);
    }
    
    free(classes);
}

void DIRuntimeEnumerateClassProperties(Class class, void (^block)(objc_property_t property)) {
    objc_property_t *properties = class_copyPropertyList(class, NULL);
    for (objc_property_t *cursor = properties; properties && *cursor; cursor++) {
        block(*cursor);
    }
    free(properties);
}

objc_property_t DIRuntimeEnumerateClassGetProperty(Class class, NSString *propertyName) {
    return class_getProperty(class, propertyName.UTF8String);
}

void DIRuntimeEnumerateClassIvars(Class class, void (^block)(Ivar ivar)) {
    Ivar* ivars = class_copyIvarList(class, NULL);
    for (Ivar *cursor = ivars; ivars && *cursor; cursor++) {
        block(*cursor);
    }
    free(ivars);
}

void DIRuntimeEnumerateClassProtocols(Class class, void (^block)(Protocol *protocol)) {
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(class, NULL);
    for (__unsafe_unretained Protocol **cursor = protocols; protocols && *cursor; cursor++) {
        block(*cursor);
    }
    free(protocols);
}

void DIRuntimeEnumerateClassProtocolsWithParents(Class class, void (^block)(Protocol *protocol)) {
    NSMutableSet<Protocol *> *protocols = [NSMutableSet set];
    DIRuntimeEnumerateClassProtocols(class, ^(Protocol *protocol){
        if (![protocols containsObject:protocol]) {
            block(protocol);
            [protocols addObject:protocol];
        }
        
        DIRuntimeEnumerateProtocolSuperprotocols(protocol, ^(Protocol *superprotocol) {
            if (![protocols containsObject:superprotocol]) {
                block(superprotocol);
                [protocols addObject:superprotocol];
            }
        });
    });
}

void DIRuntimeEnumerateProtocolSuperprotocols(Protocol *protocol, void (^block)(Protocol *superprotocol)) {
    __unsafe_unretained Protocol **protocols = protocol_copyProtocolList(protocol, NULL);
    for (__unsafe_unretained Protocol **cursor = protocols; protocols && *cursor; cursor++) {
        block(*cursor);
    }
    free(protocols);
}

void DIRuntimeEnumerateProtocolProperties(Protocol *protocol, BOOL required, BOOL instance, void (^block)(objc_property_t property)) {
    objc_property_t *properties = protocol_copyPropertyList(protocol, NULL);
    for (objc_property_t *cursor = properties; properties && *cursor; cursor++) {
        objc_property_t property = protocol_getProperty(protocol, property_getName(*cursor), required, instance);
        if (property) {
            block(property);
        }
    }
    free(properties);
}

NSString *DIRuntimeGetPropertyAttribute(objc_property_t property, char *attrribute) {
    char *value = property_copyAttributeValue(property, attrribute);
    if (value) {
        return [[NSString alloc] initWithBytesNoCopy:value length:strlen(value) encoding:NSUTF8StringEncoding freeWhenDone:YES];
    }
    return nil;
}

BOOL DIRuntimeGetPropertyIsWeak(objc_property_t property) {
    return DIRuntimeGetPropertyAttribute(property, "W") != nil;
}

SEL DIRuntimeGetPropertyGetter(objc_property_t property) {
    char *value = property_copyAttributeValue(property, "G");
    if (value) {
        SEL sel = NSSelectorFromString([NSString stringWithUTF8String:value]);
        free(value);
        return sel;
    }
    return NSSelectorFromString([NSString stringWithUTF8String:property_getName(property)]);
}

SEL DIRuntimeGetPropertySetter(objc_property_t property) {
    char *value = property_copyAttributeValue(property, "S");
    if (value) {
        SEL sel = NSSelectorFromString([NSString stringWithUTF8String:value]);
        free(value);
        return sel;
    }
    NSString *str = [NSString stringWithUTF8String:property_getName(property)];
    str = [NSString stringWithFormat:@"set%@%@:",[[str substringToIndex:1] uppercaseString], [str substringFromIndex:1]];
    return NSSelectorFromString(str);
}

void DIRuntimeGetPropertyType(objc_property_t property, void (^block)(Class class, NSSet<Protocol *> *protocols)) {
    char *value = property_copyAttributeValue(property, "T");
    NSString *type = [[NSString alloc] initWithBytesNoCopy:value length:(value ? strlen(value) : 0) encoding:NSUTF8StringEncoding freeWhenDone:YES];
    
    if ([type rangeOfString:@"@\""].location == 0) {
        type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
    }
    
    Class class = nil;
    NSUInteger location = [type rangeOfString:@"<"].location;
    if (location != 0 && location != NSNotFound) {
        class = NSClassFromString([type substringToIndex:location]);
        type = [type substringFromIndex:location];
    }
    
    NSMutableSet *protocols = [NSMutableSet set];
    while ((location = [type rangeOfString:@">"].location) != NSNotFound) {
        NSString *protocolStr = [type substringWithRange:NSMakeRange(1, location-1)];
        Protocol *protocol = NSProtocolFromString(protocolStr);
        if (protocol) {
            [protocols addObject:protocol];
            DIRuntimeEnumerateProtocolSuperprotocols(protocol, ^(Protocol *superprotocol) {
                [protocols addObject:superprotocol];
            });
        }
        type = [type substringFromIndex:location + 1];
    }
    
    block(class, protocols);
}

objc_AssociationPolicy DIRuntimePropertyAssociationPolicy(objc_property_t property) {
    if (DIRuntimeGetPropertyAttribute(property, "N") != nil) {
        if (DIRuntimeGetPropertyAttribute(property, "W")) {
            return OBJC_ASSOCIATION_RETAIN; // Weaks are supported over boxing
        }
        if (DIRuntimeGetPropertyAttribute(property, "C") != nil) {
            return OBJC_ASSOCIATION_COPY_NONATOMIC;
        }
        if (DIRuntimeGetPropertyAttribute(property, "&") != nil) {
            return OBJC_ASSOCIATION_RETAIN_NONATOMIC;
        }
    } else {
        if (DIRuntimeGetPropertyAttribute(property, "W")) {
            return OBJC_ASSOCIATION_RETAIN; // Weaks are supported over boxing
        }
        if (DIRuntimeGetPropertyAttribute(property, "C") != nil) {
            return OBJC_ASSOCIATION_COPY;
        }
        if (DIRuntimeGetPropertyAttribute(property, "&") != nil) {
            return OBJC_ASSOCIATION_RETAIN;
        }
    }
    return OBJC_ASSOCIATION_ASSIGN;
}

NSString *DIRuntimeMethodGetReturnType(Method method) {
    char *returnType = method_copyReturnType(method);
    return [[NSString alloc] initWithBytesNoCopy:returnType length:(returnType ? strlen(returnType) : 0) encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

NSString *DIRuntimeMethodGetArgumentType(Method method, NSUInteger index) {
    char *argumentType = method_copyArgumentType(method, (unsigned int)(index + 2));
    return [[NSString alloc] initWithBytesNoCopy:argumentType length:(argumentType ? strlen(argumentType) : 0) encoding:NSUTF8StringEncoding freeWhenDone:YES];
}
