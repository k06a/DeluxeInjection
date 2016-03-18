//
//  DIRuntimeRoutines.h
//  MLWorks
//
//  Created by Антон Буков on 18.03.16.
//
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

void DIRuntimeEnumerateClasses(void (^block)(Class class));
void DIRuntimeEnumerateClassSubclasses(Class parentclass, void (^block)(Class class));
void DIRuntimeEnumerateClassProperties(Class class, void (^block)(objc_property_t property));
void DIRuntimeEnumerateClassIvars(Class class, void (^block)(Ivar ivar));
void DIRuntimeEnumerateClassProtocols(Class class, void (^block)(Protocol *protocol));
void DIRuntimeEnumerateClassProtocolsWithParents(Class class, void (^block)(Protocol *protocol));

void DIRuntimeEnumerateProtocolSuperprotocols(Protocol *protocol, void (^block)(Protocol *superprotocol));
void DIRuntimeEnumerateProtocolProperties(Protocol *protocol, BOOL required, BOOL instance, void (^block)(objc_property_t property));

void DIRuntimeEnumeratePropertyAttribute(objc_property_t property, char *attrribute, void (^block)(char *value));
void DIRuntimeEnumeratePropertyGetter(objc_property_t property, void (^block)(SEL getter));
void DIRuntimeEnumeratePropertySetter(objc_property_t property, void (^block)(SEL setter));
void DIRuntimeEnumeratePropertyType(objc_property_t property, void (^block)(Class class, NSSet<Protocol *> *protocols));

NS_ASSUME_NONNULL_END
