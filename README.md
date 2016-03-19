# DeluxeInjection

[![CI Status](http://img.shields.io/travis/k06a/DeluxeInjection.svg?style=flat)](https://travis-ci.org/k06a/DeluxeInjection)
[![Version](https://img.shields.io/cocoapods/v/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)
[![License](https://img.shields.io/cocoapods/l/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)
[![Platform](https://img.shields.io/cocoapods/p/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)

## Usage

#### Auto injection

First of all imagine what are you trying to inject?

```objective-c
@interface SomeClass : SomeSuperclass

@property (strong, nonatomic) Feedback *feedback;

@end
```

Just one keyword will do this for you:
```objective-c
@interface SomeClass : SomeSuperclass

@property (strong, nonatomic) Feedback<DIInject> *feedback;

@end
```

And block wich will be called for each object of SomeClass on first `feedback` access:

```objective-c
Feedabck *feedback = [Feedback alloc] initWithSettings: ... ];
[DeluxeInjection inject:^(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
    if (propertyClass == [Feedback class]) {
    	return feedback;
    }
    return nil;
}];
```

Sure this block will be called inside getter iff `_feedback == nil`. And you is allowed to make a decision a return to value based on all this stuff:

* Target object pointer – `id target`
* Property name in string representation – `NSString *propertyName`
* Class of property – `Class propertyClass`, will be at least NSObject
* Set of property protocols – `NSSet<Protocol *> *protocols`, including all superprotocols

#### Laziness

Do you really like this boilerplate?

```objective-c
@interface SomeClass : SomeSuperclass

@property (strong, nonatomic) NSMutableArray *items;

@end

@implementation SomeClass

- (NSMutableArray *)items {
    if (_items == nil) {
        _items = [NSMutableArray array];
    }
    return items;
}

@end
```

Just one keyword will do this for you:

```objective-c
@interface SomeClass : SomeSuperclass

@property (strong, nonatomic) NSMutableArray<DILazy> *items;

@end
```

Sure it works with generic types:

```objective-c
@property (strong, nonatomic) NSMutableArray<NSString *><DILazy> *items;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *><DILazy> *items;
```

This all will be done after calling this:
```objective-c
[DeluxeInjection lazy];
```

#### Force injection

You can inject any class property you want ether without `DIInject` specification using `forceInject:`:

```objective-c
@interface TestClass : SomeSuperclass

@property (strong, nonatomic) Network *network;

@end

...

Network *network = [Network alloc] initWithSettings: ... ];
[DeluxeInjection forceInject:^id(id target, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
    if ([target isKindOfClass:[TestClass class]] && propertyClass == [Network class]) {
    	return network;
    }
    return nil;
}];
```

#### Blocks injection

Also you are able to use methods `injectBlock:` and `forceInjectBlock:` to return `DIResult` block, which will be called for each object while its getter access when instance variable is nil. Blcok injection may increase your app performance, if you care a lot about this.

For example this usage will inject only properties of types `NSMutableArray` and `NSMutableDictionary` with 2 prepared objects:

```objective-c
[DeluxeInjection injectBlock:^DIGetter (Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {
    if (propertyClass == [NSMutableArray class]) {
        return ^id(id self, SEL _cmd) {
            return [arrayMock1 mutableCopy];
        };
    }
    if (propertyClass == [NSMutableDictionary class]) {
        return ^id(id self, SEL _cmd) {
            return [dictMock2 mutableCopy];
        };
    }
    return nil;
}];
```

Whole block will be called once and returned `DIResult` blocks will be called each time instance variable will need new non-nil value.

#### All methods documentation

You can see parameters description right in source code comments.

1. Check if property of class is injected
   ```objective-c
   + (BOOL)checkInjected:(Class)class getter:(SEL)getter;
    ```

2. Inject concrete property
   ```objective-c
   + (void)inject:(Class)class getter:(SEL)getter block:(DIGetter)block;
      ```

3. Deinject concrete property injection
   ```objective-c
   + (void)deinject:(Class)class getter:(SEL)getter;
   ```

4. Inject **values** into class properties marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)inject:(DIPropertyGetter)block;
    ```

5. Inject **getters** into class properties marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)injectBlock:(DIPropertyGetterBlock)block;
      ```

6. Force inject **values** into class properties even **not** marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)forceInject:(DIPropertyGetter)block;
   ```

7. Force inject **getters** into class properties even **not** marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)forceInjectBlock:(DIPropertyGetterBlock)block;
     ```

8. Deinject some injections marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)deinject:(DIPropertyFilter)block;
   ```

9. Deinject all injections marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)deinjectAll;
   ```

10. Deinject some injections even **not** marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)forceDeinject:(DIPropertyFilter)block;
   ```

11.  Deinject **all** injections and marked explicitly with `<DIInject>` and `<DILazy>` protocols.
   ```objective-c
   + (void)forceDeinjectAll;
   ```

12. Inject properties marked with `<DILazy>` protocol using block: `^{ return [[class alloc] init]; }`
   ```objective-c
   + (void)lazy;
   ```
   
13. Deinject all injections marked explicitly with `<DILazy>` protocol.
   ```objective-c
   + (void)lazyDeinject;
   ```

14. Overriden `debugDescription` method to see tree of classes and injected properties
   ```objective-c
   + (NSString *)debugDescription;
   ```

## Performance and Testing

Enumeration of 15.000 classes during injection tooks 0.022 sec. You can find this performance test and other tests in Example project. I am planning to add as many tests as possible to detect all possible problems.

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

DeluxeInjection is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DeluxeInjection'
```

## Author

Anton Bukov, k06aaa@gmail.com

## License

DeluxeInjection is available under the MIT license. See the LICENSE file for more info.
