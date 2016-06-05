# DeluxeInjection :syringe:

[![CI Status](http://img.shields.io/travis/k06a/DeluxeInjection.svg?style=flat)](https://travis-ci.org/k06a/DeluxeInjection)
[![Coverage Status](https://coveralls.io/repos/github/k06a/DeluxeInjection/badge.svg?branch=master)](https://coveralls.io/github/k06a/DeluxeInjection?branch=master)
[![Version](https://img.shields.io/cocoapods/v/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)
[![Platform](https://img.shields.io/cocoapods/p/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)

<img src="/images/Relax.png" align="right" height="300px" hspace="10px" vspace="10px">

## Features

1. Auto-injection as first-class feature
2. Force injection for any property of any class
3. Lazy properties initialization feature
3. `NSUserDefaults`-backed properties feature
4. Both *value-* and *getter-*injection supported
5. Inject both *ivar*-backed and `@dynamic` properties (over association)
6. Easily access *ivar*s inside injected getter

## Auto injection

<img src="/images/AI.png" align="right" height="400px" hspace="10px" vspace="10px">

First of all imagine what are you trying to inject?

```objective-c
@interface SomeClass : SomeSuperclass

@property (nonatomic) Feedback *feedback;

@end
```

Just one keyword will do this for you:
```objective-c
@interface SomeClass : SomeSuperclass

@property (nonatomic) Feedback<DIInject> *feedback;

@end
```

And block to be called for all classes properties marked with `<DIInject>`:

```objective-c
Feedabck *feedback = [Feedback alloc] initWithSettings: ... ];
[DeluxeInjection inject:^(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
    if (propertyClass == [Feedback class]) {
    	return feedback;
    }
    return [DeluxeInjection doNotInject]; // Special value to skip injection for propertyName of targetClass
}];
```

And you is allowed to make a decision to return value based on all this stuff:

* Target class for injection – `Class targetClass`
* Property name in string representation – `NSString *propertyName`
* Class of property – `Class propertyClass`, or `nil` in case of *id*
* Set of property protocols – `NSSet<Protocol *> *protocols`, including all superprotocols

You are also able to use method `injectBlock:` to return `DIGetter` block to provide injected getter or nil to skip injection. You may wanna use this methods if wanna make a decision to return value on target object. Maybe return different mutable copies for different targets or etc. Following code will inject only properties of types `NSMutableArray` and `NSMutableDictionary` with 2 prepared objects using two different but equal ways:

```objective-c
NSArray *array1 = @[@1, @2, @3];
NSDictionary *dict1 = @[@"key" : @"value"];

[DeluxeInjection injectBlock:^DIGetter (Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *propertyProtocols) {

    if (propertyClass == [NSMutableArray class]) {
        return DIGetterIfIvarIsNil(^id(id target) {
            return [array1 mutableCopy];
        });
    }
    
    if (propertyClass == [NSMutableDictionary class]) {
        return ^id(id target, id *ivar) {
            if (*ivar == nil) {
                *ivar = [dict1 mutableCopy];
            }
            return *ivar;
        };
    }
    
    return nil; // It is also safe to return a [DeluxeInjection doNotInject] here :)
}];
```

Whole block will be called once for each property of each class. Returned `DIGetter` blocks will be used as injected getter. Helper function `DIGetterIfIvarIsNil` allows to skip boilerplate *if-ivar-is-nil-then-assing-ivar-and-return-ivar*.

## Laziness

<img src="/images/LI.png" align="right" height="400px" hspace="10px" vspace="10px">

Do you really like this boilerplate?

```objective-c
@interface SomeClass : SomeSuperclass

@property (nonatomic) NSMutableArray *items;

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

@property (nonatomic) NSMutableArray<DILazy> *items;

@end
```

Of course this will work for generic types:

```objective-c
@property (nonatomic) NSMutableArray<NSString *><DILazy> *items;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *><DILazy> *items;
```

This all will be done after calling this:

```objective-c
[DeluxeInjection injectLazy];
```

## Force injection

<img src="/images/FI.png" align="right" height="400px" hspace="10px" vspace="10px">

You can force inject any property of any class even without `DIInject` specification using `forceInject:` method:

```objective-c
@interface TestClass : SomeSuperclass

@property (nonatomic) Network *network;

@end

...

Network *network = [Network alloc] initWithSettings: ... ];
[DeluxeInjection forceInject:^id(Class targetClass, NSString *propertyName, Class propertyClass, NSSet<Protocol *> *protocols) {
    if ([target isKindOfClass:[TestClass class]] && propertyClass == [Network class]) {
    	return network;
    }
    return [DeluxeInjection doNotInject]; // Special value to skip injection for propertyName of targetClass
}];
```

You are also able to use method `forceInjectBlock:` to return `DIGetter` block to provide injected getter similar to method `injectBlock:`.

## *NSUserDefaults-*backed properties

Wanna achieve this behavior with less boilerplate code?

```objective-c
@interface SomeClass : SomeSuperclass

@property (nonatomic) NSString *username;

@end

@implementation SomeClass

- (NSString *)username {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
}

- (void)setUsername:(NSString *)username {
    return [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"username"];
}

@end
```

Just use `<DIDefaults>` or `<DIDefaultsSync>` protocols on property declaration:

```objective-c
@interface SomeClass : SomeSuperclass

@property (nonatomic) NSString<DIDefaults> *username;

@end
```

And do not forget to call injection before usage: `[DeluxeInjection injectDefaults];` You are also able to use `injectDefaultsWithKey:` to provide block to get custom key to use with user defaults. Also look at `<DIDefaultsSync>` to inject getter and setter with synchronization.

## Plugins

Look at source code: `DIInject`, `DIForceInject`, `DILazy`, `DIDefaults` are implemented like separated plugins, so you can easily implement your own protocols and define injected getter and setter for each with easy access to arguments and *ivar* or associated value.

## All methods documentation

You can see methods and arguments documentation right in Xcode.

1. Check if property of class is injected
   ```objective-c
   + (BOOL)checkInjected:(Class)class getter:(SEL)getter;
    ```

2. Inject concrete property
   ```objective-c
   + (void)inject:(Class)class getter:(SEL)getter block:(DIGetter)block;
      ```

3. Reject concrete property injection
   ```objective-c
   + (void)reject:(Class)class getter:(SEL)getter;
   ```

   #### Auto-injection

4. Inject **values** into class properties marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)inject:(DIPropertyGetter)block;
    ```

5. Inject **getters** into class properties marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)injectBlock:(DIPropertyGetterBlock)block;
      ```

6. Reject some injections marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)reject:(DIPropertyFilter)block;
   ```

7. Reject all injections marked explicitly with `<DIInject>` protocol.
   ```objective-c
   + (void)rejectAll;
   ```

   #### Force injections

8. Force inject **values** into class properties **not** marked explicitly with any of `<DI***>` protocols.
   ```objective-c
   + (void)forceInject:(DIPropertyGetter)block;
   ```

9. Force inject **getters** into class properties **not** marked explicitly with any of `<DI***>` protocols.
   ```objective-c
   + (void)forceInjectBlock:(DIPropertyGetterBlock)block;
     ```

10. Reject some injections **not** marked explicitly with any of `<DI***>` protocols.
   ```objective-c
   + (void)forceReject:(DIPropertyFilter)block;
   ```

11.  Reject **all** injections **not** marked explicitly with any of `<DI***>` protocols.
   ```objective-c
   + (void)forceRejectAll;
   ```

   #### Lazy initializers injections

12. Inject properties marked with `<DILazy>` protocol using block: `^{ if (_ivar == nil) { _ivar = [[propertyClass alloc] init]; return _ivar; }`
   ```objective-c
   + (void)injectLazy;
   ```
   
13. Reject all injections marked explicitly with `<DILazy>` protocol.
   ```objective-c
   + (void)rejectLazy;
   ```
   
   #### NSUserDefaults-backed properties

14. Inject properties marked with `<DIDefaults>` or `<DIDefaultsSync>` protocol
   ```objective-c
   + (void)injectDefaults;
   ```
   
15. Inject properties marked with `<DIDefaults>` or `<DIDefaultsSync>` protocol and provide block to generate custom key
   ```objective-c
   + (void)injectDefaultsWithKey:(DIDefaultsKeyBlock)keyBlock;
   ```
   
16. Reject all injections marked explicitly with `<DIDefaults>` or `<DIDefaultsSync>` protocol.
   ```objective-c
   + (void)rejectDefaults;
   ```

   #### Other methods

17. Overriden `debugDescription` method to see tree of classes and injected properties
   ```objective-c
   + (NSString *)debugDescription;
   ```

18. Transforms getter block without `ivar` argument to block with `ivar` argument
   ```objective-c
   DIGetter DIGetterIfIvarIsNil(DIGetterWithoutIvar getter);
   ```

## Performance and Testing

Four times enumeration of 15.000 classes during lazy-injection, defaults-injection and twice dependant auto-injection tooks 0.16 sec. Performance will increase in future versions, it is one of first-class feature of the library to be super-performant. You can find some performance test and other tests in Example project. I am planning to add as many tests as possible to detect all possible problems. May be you wanna help me with tests?

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

DeluxeInjection is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'DeluxeInjection'
```

Or, if you’re using [Carthage](https://github.com/Carthage/Carthage), simply add DeluxeInjection to your `Cartfile`:

```
github "k06a/DeluxeInjection"
```

## Author

Anton Bukov
k06aaa@gmail.com
https://twitter.com/k06a

## License

DeluxeInjection is available under the MIT license. See the LICENSE file for more info.

## Contribution

– Wanna really help to project?<br/>
– Help me to add more test and divide them by plugins.

– Found any bugs?<br/>
– Feel free to open issue or discuss to me directly [@k06a](https://twitter.com/k06a)!

Contribution workflow:<br/>
1. Fork repository<br/>
2. Create new branch from master<br/>
3. Commit to your newly created branch<br/>
4. Open Pull Request and we will talk :)
