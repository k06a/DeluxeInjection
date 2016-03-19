//
//  DIRuntimeRoutines.m
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
//
//

#import "DIRuntimeRoutines.h"

void DIRuntimeEnumerateClasses(void (^block)(Class class)) {
    DIRuntimeEnumerateClassSubclasses([NSObject class], block);
}

void DIRuntimeEnumerateClassSubclasses(Class parentclass, void (^block)(Class class)) {
    int classesCount = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(classesCount * sizeof(Class));
    objc_getClassList(classes, classesCount);
    
    for (int i = 0; i < classesCount; i++) {
        Class class = classes[i];
        
        // Filter only NSObject subclasses
        Class superclass = class;
        while (superclass && superclass != parentclass) {
            superclass = class_getSuperclass(superclass);
        }
        if (!superclass) {
            continue;
        }
        
        block(class);
    }
    
    free(classes);
}

void DIRuntimeEnumerateClassProperties(Class class, void (^block)(objc_property_t property)) {
    unsigned int propertiesCount = 0;
    objc_property_t *properties = class_copyPropertyList(class, &propertiesCount);
    
    for (int i = 0; i < propertiesCount; i++) {
        block(properties[i]);
    }
    
    free(properties);
}

void DIRuntimeEnumerateClassIvars(Class class, void (^block)(Ivar ivar)) {
    unsigned int ivarsCount;
    Ivar* ivars = class_copyIvarList(class, &ivarsCount);
    
    for(unsigned int i = 0; i < ivarsCount; ++i) {
        block(ivars[i]);
    }
    
    free(ivars);
}

void DIRuntimeEnumerateClassProtocols(Class class, void (^block)(Protocol *protocol)) {
    unsigned int protocolsCount = 0;
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(class, &protocolsCount);
    
    for (int i = 0; i < protocolsCount; i++) {
        block(protocols[i]);
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
    unsigned int protocolsCount = 0;
    __unsafe_unretained Protocol **protocols = protocol_copyProtocolList(protocol, &protocolsCount);
    
    for (int i = 0; i < protocolsCount; i++) {
        block(protocols[i]);
    }
    
    free(protocols);
}

void DIRuntimeEnumerateProtocolProperties(Protocol *protocol, BOOL required, BOOL instance, void (^block)(objc_property_t property)) {
    unsigned int propertiesCount = 0;
    objc_property_t *properties = protocol_copyPropertyList(protocol, &propertiesCount);
    
    for (int i = 0; i < propertiesCount; i++) {
        objc_property_t property = protocol_getProperty(protocol, property_getName(properties[i]), required, instance);
        if (property) {
            block(property);
        }
    }
    
    free(properties);
}

NSString *DIRuntimeEnumeratePropertyAttribute(objc_property_t property, char *attrribute, void (^block)(NSString *value)) {
    char *value = property_copyAttributeValue(property, attrribute);
    NSString *str = nil;
    if (value) {
        str = [NSString stringWithUTF8String:value];
        free(value);
        if (block) {
            block(str);
        }
    }
    return str;
}

void DIRuntimeEnumeratePropertyGetter(objc_property_t property, void (^block)(SEL getter)) {
    char *value = property_copyAttributeValue(property, "G");
    if (value) {
        block(NSSelectorFromString([NSString stringWithUTF8String:value]));
        free(value);
    } else {
        block(NSSelectorFromString([NSString stringWithUTF8String:property_getName(property)]));
    }
}

void DIRuntimeEnumeratePropertySetter(objc_property_t property, void (^block)(SEL setter)) {
    char *value = property_copyAttributeValue(property, "S");
    if (value) {
        block(NSSelectorFromString([NSString stringWithUTF8String:value]));
        free(value);
    } else {
        block(NSSelectorFromString([@"set" stringByAppendingString:[[NSString stringWithUTF8String:property_getName(property)] capitalizedString]]));
    }
}

void DIRuntimeEnumeratePropertyType(objc_property_t property, void (^block)(Class class, NSSet<Protocol *> *protocols)) {
    char *value = property_copyAttributeValue(property, "T");
    NSString *type = [NSString stringWithUTF8String:value];
    free(value);
    
    if ([type rangeOfString:@"@\""].location == 0) {
        type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
    }
    
    Class class = [NSObject class];
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
