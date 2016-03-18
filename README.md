# DeluxeInjection

[![CI Status](http://img.shields.io/travis/k06a/DeluxeInjection.svg?style=flat)](https://travis-ci.org/k06a/DeluxeInjection)
[![Version](https://img.shields.io/cocoapods/v/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)
[![License](https://img.shields.io/cocoapods/l/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)
[![Platform](https://img.shields.io/cocoapods/p/DeluxeInjection.svg?style=flat)](http://cocoapods.org/pods/DeluxeInjection)

## Usage

#### Injection

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

Sure this block will be called inside getter if `_feedback == nil`. And you is allowed to make a decision a return value based on all this stuff:

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
