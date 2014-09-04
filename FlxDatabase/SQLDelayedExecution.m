//
//  ReferencedExecution.m
//  iDB
//
//  Created by Aaron Hayman on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SQLDelayedExecution.h"
#import <objc/message.h>

typedef void (^ExecBlock)(void);

@implementation SQLDelayedExecution{
    NSMutableArray *_targets;
    NSMutableArray *_selectors;
    NSMutableArray *_blocks;
    NSUInteger _count;
}
@synthesize referenceCount=_count;

#pragma mark - 
#pragma mark Init Methods
+ (SQLDelayedExecution *) execWithCount:(NSUInteger)count block:(void (^)(void))block{
    SQLDelayedExecution *exec = [[SQLDelayedExecution alloc] initWithBlock:block];
    exec.referenceCount = count;
    return exec;
}
- (id) init{
    if (self = [super init]){
        _targets = [[NSMutableArray alloc] init];
        _selectors = [[NSMutableArray alloc] init];
        _blocks = [[NSMutableArray alloc] init];
        _count = 1;
    }
    return self;
}
- (id) initWithTarget:(id)target action:(SEL)action{
    self = [self init];
    [self addTarget:target action:action];
    _count = 1;
    return self;
}
- (id) initWithBlock:(void (^)(void))block{
    self = [self init];
    [self addBlock:block];
    _count = 1;
    return self;
}
#pragma mark -
#pragma mark Protocol Methods
- (NSUInteger) blockCount{
    return _blocks.count;
}
- (NSUInteger) targetCount{
    return _targets.count;
}
#pragma mark -
#pragma mark Standard Methods
- (void) addTarget:(id)target action:(SEL)action{
    if (target){
        NSValue *object = [NSValue valueWithNonretainedObject:target];
        NSString *actionString = NSStringFromSelector(action);
        if (actionString){
            [_targets addObject:object];
            [_selectors addObject:actionString];
        }
    }
}
- (void) addBlock:(void (^)(void))block{
    if (block) [_blocks addObject:[block copy]];
}
- (void) removeTarget:(id)target action:(SEL)action{
    for (NSValue *value in _targets) if (target == value.nonretainedObjectValue){
        NSUInteger index = [_targets indexOfObject:value];
        [_targets removeObjectAtIndex:index];
        [_selectors removeObjectAtIndex:index];
    }
}
- (void) removeLastBlock{
    [_blocks removeLastObject];
}
- (void) removeBlockAtIndex:(NSUInteger)index{
    if (index < _blocks.count){
        [_blocks removeObjectAtIndex:index];
    }
}
- (void) increment{ 
    _count++; 
}
- (void) decrement{
    if (_count > 0){ 
        _count--;
        if (_count == 0) [self execute];
    }
}
- (void) incrementBy:(NSUInteger)count{
    _count += count;
}
- (void) decrementBy:(NSUInteger)count{
    if (count >= _count && _count > 0){
        _count = 0;
        [self execute];
    } else {
        _count -= count;
    }
}
- (void) execute{
    _count = 0;
    for (ExecBlock block in _blocks) block();
    
    id target;
    NSString *selString;
    for (int i = 0; i < _targets.count; i++){
        target = [[_targets objectAtIndex:i] nonretainedObjectValue];
        selString = [_selectors objectAtIndex:i];
        objc_msgSend(target, NSSelectorFromString(selString));
    }
}
@end
