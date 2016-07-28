//
//  DIImperativePlugin.h
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

#import "DIImperative.h"

NS_ASSUME_NONNULL_BEGIN

@interface DIPropertyHolder : NSObject

@property (assign, nonatomic) Class targetClass;
@property (assign, nonatomic) Class propertyClass;
@property (strong, nonatomic) NSString *propertyName;
@property (strong, nonatomic) NSSet<Protocol *> *propertyProtocols;
@property (assign, nonatomic) SEL getter;
@property (assign, nonatomic) SEL setter;
@property (assign, nonatomic) BOOL wasInjectedGetter;
@property (assign, nonatomic) BOOL wasInjectedSetter;

@end

//

@interface DIImperative (Plugin)

@property (strong, nonatomic) NSMutableDictionary<id,NSMutableArray<DIPropertyHolder *> *> *byClass;
@property (strong, nonatomic) NSMutableDictionary<NSValue *,NSMutableArray<DIPropertyHolder *> *> *byProtocol;

@end

NS_ASSUME_NONNULL_END
