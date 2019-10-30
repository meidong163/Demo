//
//  NSObject+kvo.h
//  KVODemo
//
//  Created by 舒江波 on 2019/10/30.
//  Copyright © 2019 com.pactera. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Block)(id _Nullable observedObject, NSString *observedKey, id oldValue, id newValue);


NS_ASSUME_NONNULL_BEGIN

@interface NSObject (kvo)

- (void)addObservedObj:(NSObject *)observeObj forKey:(NSString *)key WithBlock:(Block)block;
- (void)removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
