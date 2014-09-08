//
//  SQLColumn.m
//  iDB
//
//  Created by Aaron Hayman on 9/14/12.
//
//

#import "SQLColumn.h"

#define $(...)        [NSString  stringWithFormat:__VA_ARGS__,nil]

@implementation SQLColumn{
    NSString *_name;
    NSString *_alias;
    SQLColumnType _type;
    SQLAggregate _aggregate;
    bool _primaryKey;
    bool _notNull;
    bool _unique;
    id _value;
}
#pragma mark -
#pragma mark Init Methods
- (id) init{
    return [self initWithColumn:nil];
}
- (id) initWithColumn:(NSString *)columnName{
    return [self initWithColumn:columnName ofColumnType:SQLColumnTypeNone usingAlias:nil aggregate:SQLAggregateNone];
}
- (id) initWithColumn:(NSString *)columnName usingAlias:(NSString *)alias{
    return [self initWithColumn:columnName ofColumnType:SQLColumnTypeNone usingAlias:alias aggregate:SQLAggregateNone];
}
- (id) initWithColumn:(NSString *)columnName ofColumnType:(SQLColumnType)newColumnType usingAlias:(NSString *)newAlias aggregate:(SQLAggregate)aggregate{
    if((self = [super init])){
        _name = columnName;
        _type = newColumnType;
        _alias = newAlias;
        _aggregate = aggregate;
        _primaryKey = NO;
        _notNull = NO;
        _unique = NO;
        _value = nil;
    }
    return self;
}
#pragma mark - Private Methods
#pragma mark - Protocol Methods
- (id) copyWithZone:(NSZone *)zone{
    SQLColumn *copy = [[SQLColumn alloc] initWithColumn:_name usingAlias:_alias];
    copy.type = _type;
    copy.aggregate = _aggregate;
    copy.primaryKey = _primaryKey;
    copy.notNull = _notNull;
    copy.unique = _unique;
    return copy;
}
#pragma mark - Properties
- (NSString *) nameString{
    if (_alias){
        return _alias;
    } else {
        if (_type != SQLColumnTypeNone){
            return $(@"%@(%@)", self.columnAggregateString, _name);
        } else {
            return _name;
        }
    }
}
- (NSString *) columnTypeString{
    switch (_type) {
        case SQLColumnTypeText:
            return @"TEXT";
        case SQLColumnTypeInt:
            return @"INTEGER";
        case SQLColumnTypeReal:
            return @"REAL";
        case SQLColumnTypeBlob:
            return @"BLOB";
        case SQLColumnTypeNone:
            return @"";
        default:
            return @"";
    }
}
- (NSString *) columnAggregateString{
    switch (_aggregate) {
        case SQLAggregateNone:
            return @"";
        case SQLAggregateTotal:
            return @"total";
        case SQLAggregateMax:
            return @"max";
        case SQLAggregateMin:
            return @"min";
        case SQLAggregateAvg:
            return @"avg";
        case SQLAggregateCount:
            return @"COUNT";
        default:
            return @"";
    }
}
- (void) setValue:(id)value{
    if ([self validateValue:value]) _value = value;
    else {
      //FlxLog(@"Column type: %@, couldn't validate Value: %@", [self columnTypeString], value);
        _value = nil;
    }
}
- (id) value{
    return  _value;
}
#pragma mark - Standard Methods
- (BOOL) validateValue:(id)value{
    if (!value) return YES;
    switch (_type) {
        case SQLColumnTypeNone:
            return YES;
        case SQLColumnTypeReal:
        case SQLColumnTypeInt:
            return [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]];
        case SQLColumnTypeBlob:
            return [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]];
        case SQLColumnTypeText:
            return [value isKindOfClass:[NSString class]];
    }
    return NO;
}
#pragma mark - Overridden Methods
- (NSUInteger) hash{
    return [self nameString].hash;
}
- (BOOL) isEqual:(id)object{
    if (![object isKindOfClass:[SQLColumn class]]) return NO;
    return [self.nameString isEqualToString:[object nameString]];
}
@end
