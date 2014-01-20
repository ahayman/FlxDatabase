//
//  SQLPredicate.m
//  iDB
//
//  Created by Aaron Hayman on 9/14/12.
//
//

#import "SQLPredicate.h"

@implementation SQLPredicate
#pragma mark -
#pragma mark Init Methods
- (id) init{
    if (self = [super init]){
        _op = SQLEquals;
        _connect = SQLConnectAnd;
    }
    return self;
}
- (id) initWithColumn:(NSString *)column value:(id)value operator:(SQLOperator)op connection:(SQLConnect)connection{
    if ((self = [super init])){
        _column = column;
        _value = value;
        _op = op;
        _connect = connection;
    }
    return self;
}
#pragma mark -
#pragma mark Private Methods
#pragma mark -
#pragma mark Protocol Methods
- (id) copyWithZone:(NSZone *)zone{
    SQLPredicate *copy = [[SQLPredicate alloc] init];
    copy.column = _column;
    copy.value = _value;
    copy.op = _op;
    copy.connect = _connect;
    
    return copy;
}
#pragma mark -
#pragma mark Properties
- (NSString *) connectionTypeString{
    switch (_connect) {
        case SQLConnectAnd:
            return @" AND";
        case SQLConnectOr:
            return @" OR";
        default:
            return @" AND";
    }
}
- (NSString *) predicateTypeString{
    switch (_op) {
        case SQLLike: return @"LIKE";
        case SQLEquals: return @"IS";
        case SQLLessThan: return @"<";
        case SQLNotEqualTo: return @"IS NOT";
        case SQLGreaterThan: return @">";
        case SQLLessThanOrEqualTo: return @"<=";
        case SQLGreaterThanOrEqualTo: return @">=";
        case SQLNotLike: return @"NOT LIKE";
    }
}
@end

@implementation SQLPredicateGroup {
    NSMutableArray *_predicates;
}
#pragma mark - Init Methods
- (id) init{
    return [self initWithConnection:SQLConnectAnd predicates:nil];
}
- (id) initWithConnection:(SQLConnect)connect predicates:(NSArray *)predicates{
    if (self = [super init]){
        _connect = connect;
        _predicates = predicates.count ? [NSMutableArray arrayWithArray:predicates] : [NSMutableArray array];
    }
    return self;
}
#pragma mark - Private Methods

#pragma mark - Protocol Methods
#pragma mark - Properties
- (void) setPredicates:(NSArray *)predicates{
    _predicates = [NSMutableArray arrayWithArray:predicates];
}
- (NSArray *) predicates{
    return _predicates;
}
- (id) copyWithZone:(NSZone *)zone{
    NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:_predicates.count];
    for (id predicate in _predicates){
        [predicates addObject:[predicate copy]];
    }
    return [[SQLPredicateGroup alloc] initWithConnection:_connect predicates:predicates];
}
- (NSString *) connectString{
    switch (_connect) {
        case SQLConnectAnd:
            return @" AND";
        case SQLConnectOr:
            return @" OR";
        default:
            return @" AND";
    }
}
#pragma mark - Standard Methods
- (void) addPredicate:(SQLPredicate *)predicate{
    if (predicate)
        [_predicates addObject:predicate];
}
- (void) removePredicate:(SQLPredicate *)predicate{
    if (predicate)
        [_predicates removeObject:predicate];
}
- (void) removeAllPredicates{
    [_predicates removeAllObjects];
}
- (void) addGroup:(SQLPredicateGroup *)group{
    if (group)
        [_predicates addObject:group];
}
- (void) removeGroup:(SQLPredicateGroup *)group{
    if (group)
        [_predicates removeObject:group];
}
#pragma mark - Overridden Methods

@end
