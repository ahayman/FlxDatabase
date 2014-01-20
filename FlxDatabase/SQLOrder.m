//
//  SQLOrder.m
//  iDB
//
//  Created by Aaron Hayman on 9/14/12.
//
//

#import "SQLOrder.h"
#import "FlxToolkit.h"

@implementation SQLOrder{
    SQLOrderDirection _orderDirection;
    NSArray *_customOrdering;
}
#pragma mark -
#pragma mark Init Methods
- (id) init{
    return nil;
}
- (id) initWithColumn:(NSString *)column orderDirection:(SQLOrderDirection)order{
    if (!column.length) return nil;
    if ((self = [super init])){
        _column = column;
        [self setOrderDirection:order];
    }
    return self;
}
#pragma mark -
#pragma mark Protocol Methods
- (id) copyWithZone:(NSZone *)zone{
    SQLOrder *copy = [[SQLOrder alloc] initWithColumn:_column orderDirection:_orderDirection];
    copy.customOrdering = _customOrdering;
    return copy;
}
#pragma mark -
#pragma mark Properties
- (void) setOrderDirection:(SQLOrderDirection)newOrder{
    if (newOrder <= 1) _orderDirection = newOrder;
    else _orderDirection = SQLOrderAscending;
}
- (SQLOrderDirection) orderDirection{
    return _orderDirection;
}
- (NSString *) orderDirectionString{
    switch (_orderDirection) {
        case SQLOrderAscending:
            return $(@"%@ASC", !_caseSensitive ? @"COLLATE NOCASE ": @"");
        case SQLOrderDescending:
            return $(@"%@DESC", !_caseSensitive ? @"COLLATE NOCASE ": @"");
        default:
            return $(@"%@ASC", !_caseSensitive ? @"COLLATE NOCASE ": @"");
    }
}
#pragma mark - Overridden Methods
- (NSString *) description{
    return $(@"%@ %@", _column, self.orderDirectionString);
}
- (BOOL) isEqual:(id)object{
    if (![object isKindOfClass:[SQLOrder class]]) return NO;
    else {
        return [_column isEqualToString:[object column]];
    }
}
- (NSUInteger) hash{
    return _column.hash;
}
@end
