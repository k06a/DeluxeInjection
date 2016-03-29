//
//  DIRuntimeRoutines.h
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

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

void DIRuntimeEnumerateClasses(void (^block)(Class class));
void DIRuntimeEnumerateClassSubclasses(Class parentclass, void (^block)(Class class));
void DIRuntimeEnumerateClassProperties(Class class, void (^block)(objc_property_t property));
objc_property_t DIRuntimeEnumerateClassGetProperty(Class class, NSString *propertyName);
void DIRuntimeEnumerateClassIvars(Class class, void (^block)(Ivar ivar));
void DIRuntimeEnumerateClassProtocols(Class class, void (^block)(Protocol *protocol));
void DIRuntimeEnumerateClassProtocolsWithParents(Class class, void (^block)(Protocol *protocol));

void DIRuntimeEnumerateProtocolSuperprotocols(Protocol *protocol, void (^block)(Protocol *superprotocol));
void DIRuntimeEnumerateProtocolProperties(Protocol *protocol, BOOL required, BOOL instance, void (^block)(objc_property_t property));

NSString *DIRuntimeGetPropertyAttribute(objc_property_t property, char *attrribute);
BOOL DIRuntimeGetPropertyIsWeak(objc_property_t property);
SEL DIRuntimeGetPropertyGetter(objc_property_t property);
SEL DIRuntimeGetPropertySetter(objc_property_t property);
void DIRuntimeGetPropertyType(objc_property_t property, void (^block)(Class _Nullable class, NSSet<Protocol *> *protocols));

objc_AssociationPolicy DIRuntimePropertyAssociationPolicy(objc_property_t property);

NS_ASSUME_NONNULL_END
