//
//  DIRuntimeRoutines.h
//  MLWorks
//
//  Created by Anton Bukov on 18.03.16.
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

NSString *DIRuntimeGetPropertyAttribute(objc_property_t property, char *attrribute);
SEL DIRuntimeGetPropertyGetter(objc_property_t property);
SEL DIRuntimeGetPropertySetter(objc_property_t property);
void DIRuntimeGetPropertyType(objc_property_t property, void (^block)(Class _Nullable class, NSSet<Protocol *> *protocols));

objc_AssociationPolicy DIRuntimePropertyAssociationPolicy(objc_property_t property);

NS_ASSUME_NONNULL_END
