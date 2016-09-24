//
//  RuntimeRoutines.m
//  MachineLearningWorks
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

#import "RuntimeRoutines.h"

void RRClassEnumerateAllClasses(BOOL includeMetaClasses, void (^block)(Class klass)) {
    RRClassEnumerateSubclasses([NSObject class], includeMetaClasses, block);
}

void RRClassEnumerateSubclasses(Class parentclass, BOOL includeMetaClasses, void (^block)(Class klass)) {
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
        if (includeMetaClasses) {
            block(objc_getMetaClass(class_getName(*cursor)));
        }
    }

    free(classes);
}

void RRClassEnumerateMethods(Class klass, void (^block)(Method method)) {
    Method *methods = class_copyMethodList(klass, NULL);
    for (Method *cursor = methods; methods && *cursor; cursor++) {
        block(*cursor);
    }
    free(methods);
}

void RRClassEnumerateProperties(Class klass, void (^block)(objc_property_t property)) {
    objc_property_t *properties = class_copyPropertyList(klass, NULL);
    for (objc_property_t *cursor = properties; properties && *cursor; cursor++) {
        block(*cursor);
    }
    free(properties);
}

void RRClassEnumeratePropertiesWithSuperclassesProperties(Class klass, void (^block)(objc_property_t property)) {
    NSMutableSet <NSString *> *calledProperties = [NSMutableSet new];
    
    for (Class currentKlass = klass; currentKlass; currentKlass = [currentKlass superclass]) {
        RRClassEnumerateProperties(currentKlass, ^(objc_property_t property) {
            NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
            if ([calledProperties containsObject:name]) {
                return;
            }
            
            [calledProperties addObject:name];
            block(property);
        });
    }
}

void RRClassEnumerateIvars(Class klass, void (^block)(Ivar ivar)) {
    Ivar *ivars = class_copyIvarList(klass, NULL);
    for (Ivar *cursor = ivars; ivars && *cursor; cursor++) {
        block(*cursor);
    }
    free(ivars);
}

void RRClassEnumerateProtocols(Class klass, void (^block)(Protocol *protocol)) {
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(klass, NULL);
    for (__unsafe_unretained Protocol **cursor = protocols; protocols && *cursor; cursor++) {
        block(*cursor);
    }
    free(protocols);
}

void RRClassEnumerateProtocolsWithSuperprotocols(Class klass, void (^block)(Protocol *protocol)) {
    NSMutableSet<Protocol *> *protocols = [NSMutableSet set];
    RRClassEnumerateProtocols(klass, ^(Protocol *protocol) {
        if (![protocols containsObject:protocol]) {
            block(protocol);
            [protocols addObject:protocol];
        }

        RRProtocolEnumerateSuperprotocols(protocol, ^(Protocol *superprotocol) {
            if (![protocols containsObject:superprotocol]) {
                block(superprotocol);
                [protocols addObject:superprotocol];
            }
        });
    });
}

objc_property_t RRClassGetPropertyByName(Class klass, NSString *propertyName) {
    return class_getProperty(klass, propertyName.UTF8String);
}

void RRProtocolEnumerateSuperprotocols(Protocol *protocol, void (^block)(Protocol *superprotocol)) {
    __unsafe_unretained Protocol **protocols = protocol_copyProtocolList(protocol, NULL);
    for (__unsafe_unretained Protocol **cursor = protocols; protocols && *cursor; cursor++) {
        block(*cursor);
    }
    free(protocols);
}

void RRProtocolEnumerateProperties(Protocol *protocol, BOOL required, BOOL instance, void (^block)(objc_property_t property)) {
    objc_property_t *properties = protocol_copyPropertyList(protocol, NULL);
    for (objc_property_t *cursor = properties; properties && *cursor; cursor++) {
        objc_property_t property = protocol_getProperty(protocol, property_getName(*cursor), required, instance);
        if (property) {
            block(property);
        }
    }
    free(properties);
}

NSString *RRPropertyGetAttribute(objc_property_t property, char *attrribute) {
    char *value = property_copyAttributeValue(property, attrribute);
    if (value) {
        return [[NSString alloc] initWithBytesNoCopy:value length:strlen(value) encoding:NSUTF8StringEncoding freeWhenDone:YES];
    }
    return nil;
}

BOOL RRPropertyGetIsWeak(objc_property_t property) {
    return RRPropertyGetAttribute(property, "W") != nil;
}

SEL RRPropertyGetGetterIfExist(objc_property_t property) {
    char *value = property_copyAttributeValue(property, "G");
    if (value) {
        SEL sel = NSSelectorFromString([NSString stringWithUTF8String:value]);
        free(value);
        return sel;
    }
    return nil;
}

SEL RRPropertyGetSetterIfExist(objc_property_t property) {
    char *value = property_copyAttributeValue(property, "S");
    if (value) {
        SEL sel = NSSelectorFromString([NSString stringWithUTF8String:value]);
        free(value);
        return sel;
    }
    return nil;
}

SEL RRPropertyGetGetter(objc_property_t property) {
    return RRPropertyGetGetterIfExist(property) ?: NSSelectorFromString([NSString stringWithUTF8String:property_getName(property)]);
}

SEL RRPropertyGetSetter(objc_property_t property) {
    SEL sel = RRPropertyGetSetterIfExist(property);
    if (sel) {
        return sel;
    }
    NSString *str = [NSString stringWithUTF8String:property_getName(property)];
    str = [NSString stringWithFormat:@"set%@%@:", [[str substringToIndex:1] uppercaseString], [str substringFromIndex:1]];
    return NSSelectorFromString(str);
}

void RRPropertyGetClassAndProtocols(objc_property_t property, void (^block)(Class klass, NSSet<Protocol *> *protocols)) {
    char *value = property_copyAttributeValue(property, "T");
    NSString *type = [[NSString alloc] initWithBytesNoCopy:value length:(value ? strlen(value) : 0) encoding:NSUTF8StringEncoding freeWhenDone:YES];

    if ([type rangeOfString:@"@\""].location == 0) {
        type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
    }

    Class klass = nil;
    NSUInteger location = [type rangeOfString:@"<"].location;
    if (location != 0 && location != NSNotFound) {
        klass = NSClassFromString([type substringToIndex:location]);
        type = [type substringFromIndex:location];
    } else {
        klass = NSClassFromString(type);
    }

    NSMutableSet *protocols = [NSMutableSet set];
    while ((location = [type rangeOfString:@">"].location) != NSNotFound) {
        NSString *protocolStr = [type substringWithRange:NSMakeRange(1, location - 1)];
        Protocol *protocol = NSProtocolFromString(protocolStr);
        if (protocol) {
            [protocols addObject:protocol];
            RRProtocolEnumerateSuperprotocols(protocol, ^(Protocol *superprotocol) {
                [protocols addObject:superprotocol];
            });
        }
        type = [type substringFromIndex:location + 1];
    }

    block(klass, protocols);
}

objc_AssociationPolicy RRPropertyGetAssociationPolicy(objc_property_t property) {
    if (RRPropertyGetAttribute(property, "N") != nil) {
        if (RRPropertyGetAttribute(property, "W")) {
            return OBJC_ASSOCIATION_RETAIN; // Weaks are supported over boxing
        }
        if (RRPropertyGetAttribute(property, "C") != nil) {
            return OBJC_ASSOCIATION_COPY_NONATOMIC;
        }
        if (RRPropertyGetAttribute(property, "&") != nil) {
            return OBJC_ASSOCIATION_RETAIN_NONATOMIC;
        }
    }
    else {
        if (RRPropertyGetAttribute(property, "W")) {
            return OBJC_ASSOCIATION_RETAIN; // Weaks are supported over boxing
        }
        if (RRPropertyGetAttribute(property, "C") != nil) {
            return OBJC_ASSOCIATION_COPY;
        }
        if (RRPropertyGetAttribute(property, "&") != nil) {
            return OBJC_ASSOCIATION_RETAIN;
        }
    }
    return OBJC_ASSOCIATION_ASSIGN;
}

NSString *RRMethodGetReturnType(Method method) {
    char *returnType = method_copyReturnType(method);
    return [[NSString alloc] initWithBytesNoCopy:returnType length:(returnType ? strlen(returnType) : 0) encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

NSUInteger RRMethodGetArgumentsCount(Method method) {
    return method_getNumberOfArguments(method) - 2;
}

NSString *RRMethodGetArgumentType(Method method, NSUInteger index) {
    char *argumentType = method_copyArgumentType(method, (unsigned int)(index + 2));
    return [[NSString alloc] initWithBytesNoCopy:argumentType length:(argumentType ? strlen(argumentType) : 0) encoding:NSUTF8StringEncoding freeWhenDone:YES];
}
