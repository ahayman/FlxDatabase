//
//  ReferencedExecution.h
//  iDB
//
//  Created by Aaron Hayman on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLDelayedExecution : NSObject
@property NSUInteger referenceCount;
@property (readonly) NSUInteger blockCount;
@property (readonly) NSUInteger targetCount;
+ (SQLDelayedExecution *) execWithCount:(NSUInteger)count block:(void (^)(void))block;

- (id) initWithTarget:(id)target action:(SEL)action;
- (id) initWithBlock:(void (^)(void))block;

- (void) addTarget:(__weak id)target action:(SEL)action;
- (void) addBlock:(void (^)(void))block;

- (void) removeTarget:(id)target action:(SEL)action;
- (void) removeLastBlock;
- (void) removeBlockAtIndex:(NSUInteger)index;

- (void) increment;
- (void) decrement;
- (void) incrementBy:(NSUInteger)count;
- (void) decrementBy:(NSUInteger)count;

@end
