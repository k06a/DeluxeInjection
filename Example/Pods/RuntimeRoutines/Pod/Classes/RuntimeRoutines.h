//
//  RuntimeRoutines.h
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

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Class

void RRClassEnumerateAllClasses(BOOL includeMetaClasses, void (^block)(Class klass));
void RRClassEnumerateSubclasses(Class parentclass, BOOL includeMetaClasses, void (^block)(Class klass));
void RRClassEnumerateMethods(Class klass, void (^block)(Method method));
void RRClassEnumerateProperties(Class klass, void (^block)(objc_property_t property));
void RRClassEnumeratePropertiesWithSuperclassesProperties(Class klass, void (^block)(objc_property_t property));
void RRClassEnumerateIvars(Class klass, void (^block)(Ivar ivar));
void RRClassEnumerateProtocols(Class klass, void (^block)(Protocol *protocol));
void RRClassEnumerateProtocolsWithSuperprotocols(Class klass, void (^block)(Protocol *protocol));
objc_property_t RRClassGetPropertyByName(Class klass, NSString *propertyName);

#pragma mark - Protocol

void RRProtocolEnumerateSuperprotocols(Protocol *protocol, void (^block)(Protocol *superprotocol));
void RRProtocolEnumerateProperties(Protocol *protocol, BOOL required, BOOL instance, void (^block)(objc_property_t property));

#pragma mark - Property

NSString *RRPropertyGetAttribute(objc_property_t property, char *attrribute);
BOOL RRPropertyGetIsWeak(objc_property_t property);
SEL _Nullable RRPropertyGetGetterIfExist(objc_property_t property);
SEL _Nullable RRPropertyGetSetterIfExist(objc_property_t property);
SEL RRPropertyGetGetter(objc_property_t property);
SEL RRPropertyGetSetter(objc_property_t property);
void RRPropertyGetClassAndProtocols(objc_property_t property, void (^block)(Class _Nullable klass, NSSet<Protocol *> *protocols));
objc_AssociationPolicy RRPropertyGetAssociationPolicy(objc_property_t property);

#pragma mark - Method

NSString *RRMethodGetReturnType(Method method);
NSUInteger RRMethodGetArgumentsCount(Method method);
NSString *RRMethodGetArgumentType(Method method, NSUInteger index);

NS_ASSUME_NONNULL_END
