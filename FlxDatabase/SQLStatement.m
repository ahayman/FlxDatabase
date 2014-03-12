    //
    //  SQLConstructor.m
    //  
    //
    //  Created by Aaron Hayman on 2/11/11.
    //  Copyright 2011 __MyCompanyName__. All rights reserved.
    //

#import "SQLStatement.h"
#import "FlxToolkit.h"

@interface SQLStatement () 
- (NSString *) constructCreateStatement;
- (NSString *) constructUpdateStatement;
- (NSString *) constructInsertStatement;
- (NSString *) constructQueryStatement;
- (NSString *) constructDropTable;
- (NSString *) constructDelete;
- (NSString *) constructAlterTable;
- (NSString *) constructAddColumn;
- (NSString *) sqlConflictString;

@property (strong) NSMutableArray *columns;
@property (strong) NSMutableArray *predicates;
@property (strong) NSMutableArray *orderings;
@property (strong) NSMutableArray *groups;
@end

@implementation SQLStatement{
    //Object Values
    NSString *_tableName;
    SQLStatementType _SQLType;
    SQLConflict _conflict;
    NSMutableArray *_columns;
    NSMutableArray *_predicates;
    NSMutableArray *_orderings;
    NSMutableArray *_groups;
    //Result Values
    NSMutableArray *_parameters;
    NSString *_GUID;
}
static NSArray *defaultColumns(){
    static NSArray *defaultColumns = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultColumns = Array(GUIDKey, SQLCreatedDate, SQLModifiedDate);
    });
    return defaultColumns;
}
static NSArray *defaultColumnTypes(){
    static NSArray *types = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = Array(@(SQLColumnTypeText), @(SQLColumnTypeReal), @(SQLColumnTypeReal));
    });
    return types;
}
#pragma mark - Init Methods
+ (SQLStatement *) renameTable:(NSString *)tableName to:(NSString *)newTableName{
    SQLStatement *constructor = [[SQLStatement alloc] initWithType:SQLStatementAlterTable forTable:tableName];
    constructor.alterTableName = newTableName;
    return constructor;
}
+ (SQLStatement *) getAllTables{
    SQLStatement *constructor = [[SQLStatement alloc] initWithType:SQLStatementQuery forTable:@"sqlite_master"];
    [constructor addColumn:@"*" ofColumnType:SQLColumnTypeNone];
    [constructor addPredicate:@"table" forColumn:@"type" operator:SQLEquals];
    [constructor addOrderForColumn:@"name" withDirection:SQLOrderAscending];
    return constructor;
}
+ (SQLStatement *) statementType:(SQLStatementType)type forTable:(NSString *)table{
    return [[SQLStatement alloc] initWithType:type forTable:table];
}
- (id) init{
    return nil;
}
- (id) initWithType:(SQLStatementType)sqlType forTable:(NSString *)tableName{
    FlxTry(tableName.length, @"Tried to init a SQLStatement without a table name. Sorry, but you need a table name.", NO, {
        return nil;
    })
    if ((self = [super init])){
        _tableName = tableName;
        self.SQLType = sqlType;
        _columns = [NSMutableArray new];
        _predicates = [NSMutableArray new];
        _orderings = [NSMutableArray new];
        _groups = [NSMutableArray new];
        _parameters = [NSMutableArray new];
        _created = nil;
        _modified = nil;
        _selectDistinct = NO;
        _tableInfo = NO;
        _limit = 0;
        _offset = -1;
    }
    return self;
}
#pragma mark - 
#pragma mark Private Methods
- (void) appendPredicateTo:(NSMutableString *)statement{
    if (_predicates.count > 0) {
        [statement appendString:@" WHERE"];
        NSUInteger count = 0;
        for (id predicateItem in _predicates) {
            if ([predicateItem isKindOfClass:[SQLPredicate class]]){
                SQLPredicate *predicate = predicateItem;
                if (count > 0) {
                    [statement appendFormat:@" %@", predicate.connectString];
                }
                if (predicate.value && predicate.op == SQLLessThan){
                    [statement appendString:@" ("];
                }
                [statement appendFormat:@" \"%@\".\"%@\"", _tableName, predicate.column];
                
                if (!predicate.value || predicate.value == [NSNull null]){
                    if (predicate.op == SQLEquals || predicate.op == SQLLessThan || predicate.op == SQLLessThanOrEqualTo){
                        [statement appendString:@" IS NULL"];
                    } else {
                        [statement appendString:@" IS NOT NULL"];
                    }
                } else {
                    [statement appendFormat:@" %@", predicate.operatorString];
                    [statement appendString:@" ?"];
                    [_parameters addObject:predicate.value ? predicate.value : [NSNull null]];
                    if (predicate.op == SQLLessThan){
                        [statement appendFormat:@" OR \"%@\".\"%@\" IS NULL)", _tableName, predicate.column];
                    }
                }
                count ++;
            } else if ([predicateItem isKindOfClass:[SQLPredicateGroup class]]){
                if ([predicateItem predicates].count){
                    if (count){
                        [statement appendString:[predicateItem connectString]];
                    }
                    [statement appendString:[self stringFromPredicateGroup:predicateItem]];
                    count++;
                }
            }
        }
    }
}
- (NSString *) constructCreateStatement{
    if (_columns.count < 1) return @"";
    if (!_tableName) return @"";
    
    NSMutableString *statement = [NSMutableString stringWithFormat: @"CREATE TABLE IF NOT EXISTS \"%@\" (", _tableName];
    
    //Append the default columns
    [statement appendFormat:@"\"%@\" VARCHAR(36) PRIMARY KEY", GUIDKey];
    [statement appendFormat:@", \"%@\" REAL", SQLCreatedDate];
    [statement appendFormat:@", \"%@\" REAL", SQLModifiedDate];
    
    for (SQLColumn *currentColumn in _columns) {
        if (currentColumn.name && ![currentColumn.name isEqual: @""] && ![currentColumn.name isEqual:@"*"] && ![defaultColumns() containsObject:currentColumn.name]){
            [statement appendFormat:@", \"%@\" %@", currentColumn.name, currentColumn.columnTypeString];
            if (currentColumn.primaryKey) [statement appendString:@" PRIMARY KEY"];
            if (currentColumn.notNull == YES) [statement appendString:@" NOT NULL"];
            if (currentColumn.unique == YES) [statement appendString:@" UNIQUE"];
        }
    }
    [statement appendString:@");"];
    return statement;
}
- (NSString *) constructUpdateStatement{
    if (_columns.count < 1) return @"";
    if (!_tableName || [_tableName isEqualToString:@""]) return nil;
    NSMutableString *statement = [NSMutableString stringWithFormat:@"UPDATE \"%@\" SET", _tableName];
    
    id updateValue;
    int count = 0;
    NSDate *now = [NSDate date];
    [statement appendFormat:@" \"%@\" = ?,", [defaultColumns() objectAtIndex:2]];
    [_parameters addObject:now];
    _modified = [NSNumber numberWithDouble:[now timeIntervalSinceReferenceDate]];
    
    NSArray *disallowedUpdates = Array(@"*", GUIDKey, SQLCreatedDate, SQLModifiedDate);
    
    for (int i = 0; i < _columns.count; i++) {
        SQLColumn *currentColumn = [_columns objectAtIndex:i];
        updateValue = currentColumn.value ? currentColumn.value : [NSNull null];
        
        if ([disallowedUpdates containsObject:currentColumn.name]) continue;
        
        if (count > 0 ) [statement appendString:@","];
        [statement appendFormat:@" \"%@\" = ?", currentColumn.name];
        [_parameters addObject:updateValue];
        count++;
    }
    
    [self appendPredicateTo:statement];
    
    [statement appendString:@";"];
    
    return statement;
}
- (NSString *) constructInsertStatement{
    NSUInteger count = _columns.count;
    if (count < 1) return @"";
    NSMutableString *statement = [NSMutableString stringWithFormat:@"INSERT OR %@ INTO \"%@\" (",[self sqlConflictString], _tableName];
    NSMutableString *valueStatement = [NSMutableString stringWithString:@" VALUES ("];
    
    NSDate *now = [NSDate date];
    NSMutableSet *defaults = [NSMutableSet setWithObjects:defaultColumns()[1], defaultColumns()[2], nil];
    
    [statement appendFormat:@"\"%@\"", defaultColumns()[0]];
    [valueStatement appendString:@"?"];
    _created = _modified = @([now timeIntervalSinceReferenceDate]);
    [_parameters addObject:self.GUID];
    for (SQLColumn *currentColumn in _columns){
        id currentValue = currentColumn.value;
        if (currentValue && ![currentColumn.name isEqual: @"*"] && ![currentColumn.name isEqualToString:GUIDKey]){
            [statement appendString:@","];
            [valueStatement appendString:@","];
            [statement appendFormat:@" \"%@\"", currentColumn.name];
            [valueStatement appendString:@" ?"];
            [_parameters addObject:currentValue];
            [defaults removeObject:currentColumn.name];
        }
    }
    for (NSString *column in defaults){
        [statement appendString:@","];
        [valueStatement appendString:@","];
        [statement appendFormat:@" \"%@\"", column];
        [valueStatement appendString:@" ?"];
        [_parameters addObject:_created];
    }
    [statement appendString:@")"];
    [valueStatement appendString:@")"];
    [statement appendString:valueStatement];
    [statement appendString:@";"];
    return statement;
}
- (NSString *) constructQueryStatement{
    NSUInteger count = _columns.count;
    if (count < 1) return @"";
    NSMutableString *statement = [NSMutableString stringWithString:@"SELECT"];
    if (_selectDistinct) [statement appendString:@" DISTINCT"];
    
    //First check if we're grabbing all fields
    count = 0;
    for (SQLColumn *currentColumn in _columns){
        if ([currentColumn.name isEqual: @"*"]) {
            if (count > 0) [statement appendString:@","];
            [statement appendFormat:@" \"%@\".%@", _tableName, currentColumn.name];
            count ++;
            break;
        }
    }
    
    //If we haven't grabbed all fields, add the fields we want
    if (count == 0){
        for (SQLColumn *currentColumn in _columns) {
            if (count > 0) [statement appendString:@","];
            if (currentColumn.aggregate == SQLAggregateNone){
                [statement appendFormat:@" \"%@\".\"%@\"", _tableName, currentColumn.name];
            } else {
                [statement appendFormat:@" %@(\"%@\".\"%@\")", currentColumn.columnAggregateString, _tableName, currentColumn.name];
            }
            
            if (currentColumn.alias){
                [statement appendString: [NSString stringWithFormat: @" AS \"%@\"", currentColumn.alias]];
            }
            count ++;
        }
    }
    
    [statement appendFormat:@" FROM \"%@\"", _tableName];
    
    [self appendPredicateTo:statement];
    
    //Construct the groups
    count = 0;
    if (_groups.count > 0) {
        [statement appendString:@" GROUP BY"];
        for (SQLColumn *column in _groups) {
            if (count > 0) [statement appendString:@","];
            if (column.alias){
                [statement appendFormat:@" \"%@\"", column.alias];
            } else {
                [statement appendFormat:@" \"%@\".\"%@\"", _tableName, column.name];
            }
            count ++;
        }
    }
    
    count = 0;
    if (_orderings.count > 0){
        [statement appendString:@" ORDER BY"];
        for (SQLOrder *order in _orderings){
            if (count > 0) [statement appendString:@","];
            if (order.customOrdering.count){
                [statement appendFormat:@" CASE \"%@\".\"%@\"", _tableName, order.column];
                if (order.orderDirection == SQLOrderAscending){
                    for (int i = 0; i < order.customOrdering.count; i++){
                        [statement appendFormat:@" WHEN ? THEN %i", i];
                        id pred = order.customOrdering[i];
                        if ([pred isKindOfClass:[NSNumber class]] || [pred isKindOfClass:[NSString class]])
                            [_parameters addObject:pred];
                        else
                            [_parameters addObject:[pred description]];
                    }
                    [statement appendFormat:@" ELSE %lu END", (unsigned long)order.customOrdering.count];
                } else {
                    for (int i = 0; i < order.customOrdering.count; i++){
                        [statement appendFormat:@" WHEN ? THEN %lu", (unsigned long)order.customOrdering.count - i];
                        id pred = order.customOrdering[i];
                        if ([pred isKindOfClass:[NSNumber class]] || [pred isKindOfClass:[NSString class]])
                            [_parameters addObject:pred];
                        else
                            [_parameters addObject:[pred description]];
                    }
                    [statement appendFormat:@" ELSE 0 END"];
                }
                count++;
            } else {
                [statement appendFormat:@" \"%@\".\"%@\"", _tableName, order.column];
                [statement appendFormat:@" %@", order.orderDirectionString];
                count ++;
            }
        }
    }
    
    if (_limit > 0 || _offset > -1){
        [statement appendFormat:@" LIMIT %lu", (unsigned long)_limit];
        if (_offset > -1) [statement appendFormat:@" OFFSET %ld",(long)_offset];
    }
    
    [statement appendString:@";"];
    return statement;
}
- (NSString *) stringFromPredicateGroup:(SQLPredicateGroup *)group{
    if (!group.predicates.count) return @"";
    NSUInteger count = 0;
    NSMutableString *statement = [NSMutableString stringWithString:@"("];
    for (id predicateItem in group.predicates) {
            if ([predicateItem isKindOfClass:[SQLPredicate class]]){
                SQLPredicate *predicate = predicateItem;
                if (count > 0) {
                    [statement appendFormat:@" %@", predicate.connectString];
                }
                if (predicate.value && predicate.op == SQLLessThan && group.predicates.count > 1){
                    [statement appendString:@" ("];
                }
                [statement appendFormat:@" \"%@\".\"%@\"", _tableName, predicate.column];
                if (!predicate.value || predicate.value == [NSNull null]){
                    if (predicate.op == SQLEquals || predicate.op == SQLLessThan || predicate.op == SQLLessThanOrEqualTo){
                        [statement appendString:@" IS NULL"];
                    } else {
                        [statement appendString:@" IS NOT NULL"];
                    }
                } else {
                    [statement appendFormat:@" %@", predicate.operatorString];
                    [statement appendString:@" ?"];
                    [_parameters addObject:predicate.value ? predicate.value : [NSNull null]];
                    if (predicate.op == SQLLessThan){
                        [statement appendFormat:@" OR \"%@\".\"%@\" IS NULL%@", _tableName, predicate.column, group.predicates.count > 1 ? @")" : @" "];
                    }
                }
                count ++;
            } else if ([predicateItem isKindOfClass:[SQLPredicateGroup class]]){
                if ([predicateItem predicates].count){
                    if (count){
                        [statement appendString:[predicateItem connectString]];
                    }
                    [statement appendString:[self stringFromPredicateGroup:predicateItem]];
                    count++;
                }
            }
    }
    [statement appendString:@")"];
    return statement;
}
- (NSString *) constructDelete{
    NSMutableString *statement = [NSMutableString stringWithFormat:@""];
    if (_predicates.count > 0) {
        [statement appendFormat:@"DELETE FROM \"%@\" WHERE", _tableName];
    } else if (_columns){
        return $(@"DELETE FROM \"%@\"", [_columns.firstObject tableName]);
    } else {
        return @"";
    }
    
    int count = 0;
    for (SQLPredicate *predicate in _predicates) {
        if (predicate.value){
            if (count > 0) [statement appendFormat:@" %@", predicate.connectString];
            [statement appendFormat:@" \"%@\" %@ ?", predicate.column, predicate.operatorString];
            [_parameters addObject:(predicate.value) ? : [NSNull null]];
            count ++;
        }
    }
    
    [statement appendString:@";"];
    return statement;
}
- (NSString *) constructDropTable{
    if (!_tableName) return @"";
    return [NSString stringWithFormat: @"DROP TABLE IF EXISTS \"%@\"", _tableName];
}
- (NSString *) constructAlterTable{
    if (!_tableName.length || !_alterTableName) return @"";
    return [NSString stringWithFormat:@"ALTER TABLE \"%@\" RENAME TO \"%@\";", _tableName, _alterTableName];
}
- (NSString *) constructAddColumn{
    if (_columns.count < 1) return @"";
    SQLColumn *currentColumn = [_columns objectAtIndex:0];
    NSMutableString *statement = [NSMutableString stringWithFormat: @"ALTER TABLE \"%@\" ADD COLUMN", _tableName];
    if (currentColumn.name && ![currentColumn.name isEqualToString:@""] && ![currentColumn.name isEqual:@"*"]){
        [statement appendFormat:@" \"%@\" %@", currentColumn.name, currentColumn.columnTypeString];
    } else {
        return @"";
    }
    [statement appendString:@";"];
    return statement;
}
- (NSString *) sqlConflictString{
    switch (_conflict) {
        case SQLConflictReplace:
            return @"REPLACE";
        case SQLConflictIgnore:
            return @"IGNORE";
        case SQLConflictFail:
            return @"FAIL";
        case SQLConflictAbort:
            return @"ABORT";
        case SQLConflictRollback:
            return @"ROLLBACK";
        default:
            return @"ROLLBACK";
    }
}
#pragma mark -
#pragma mark Protocol Methods
- (id) copyWithZone:(NSZone *)zone{
    SQLStatement *returnConstructor = [[[self class] alloc] initWithType:_SQLType forTable:_tableName];
    returnConstructor.conflict = self.conflict;
    returnConstructor.columns = _columns.deepCopy;
    returnConstructor.predicates = _predicates.deepCopy;
    returnConstructor.orderings = _orderings.deepCopy;
    returnConstructor.groups = _groups.deepCopy;
    returnConstructor.limit = self.limit;
    returnConstructor.offset = self.offset;
    returnConstructor.selectDistinct = self.selectDistinct;
    returnConstructor.tableInfo = self.tableInfo;
    
    return returnConstructor;
}
- (NSString *) description{
    return  $(@"%@ \n Parameters:%@", self.newStatement, self.parameters.description);
}
#pragma mark - 
#pragma mark Properties
- (void) setTableName:(NSString *)tableName{
    if (tableName.length){
        _tableName = tableName;
    }
}
- (NSString *) tableName{
    return _tableName;
}
- (NSArray *) defaultColumnNames{
    return defaultColumns();
}
- (NSString *) newStatement{
    if (_tableInfo == YES){
        return [NSString stringWithFormat:@"PRAGMA table_info(\"%@\");", _tableName];
    }
    [_parameters removeAllObjects];
    switch (_SQLType) {
        case SQLStatementCreate: return [self constructCreateStatement];
        case SQLStatementInsert: return [self constructInsertStatement];
        case SQLStatementUpdate: return [self constructUpdateStatement];
        case SQLStatementQuery: return [self constructQueryStatement];
        case SQLStatementDelete: return [self constructDelete];
        case SQLStatementAddColumn: return [self constructAddColumn];
        case SQLStatementDropTable: return [self constructDropTable];
        case SQLStatementAlterTable: return [self constructAlterTable];
    }
    return @"";
}
- (NSArray *) parameters{
    return _parameters;
}
- (NSArray *) defaultColumns{
    return ({
        NSMutableArray *columns = [NSMutableArray new];
        NSArray *columNames = defaultColumns();
        NSArray *types = defaultColumnTypes();
        for (int i = 0; i < columNames.count; i++){
            [columns addObject:[[SQLColumn alloc] initWithColumn:columNames[i] ofColumnType:[types[i] integerValue] usingAlias:Nil aggregate:SQLAggregateNone]];
        }
        columns;
    });
}
- (void) setGUID:(NSString *)GUID{
    _GUID = GUID;
}
- (NSString *) GUID{
    if (!_GUID){
        _GUID = [NSString newGUID];
    }
    return _GUID;
}
#pragma mark - Standard Methods
#pragma mark Column Methods
- (SQLColumn *) addColumn:(NSString *)column{
    return [self addSQLColumn:[[SQLColumn alloc] initWithColumn:column]];
}
- (SQLColumn *) addColumn:(NSString *)column usingAlias:(NSString *)newAlias{
    return [self addColumn:column ofColumnType:SQLColumnTypeNone usingAlias:newAlias withAggregate:SQLAggregateNone];
}
- (SQLColumn *) addColumn:(NSString *)column ofColumnType:(SQLColumnType)newColumnType{
    return [self addColumn:column ofColumnType:newColumnType usingAlias:nil withAggregate:SQLAggregateNone];
}
- (SQLColumn *) addColumn:(NSString *)column ofColumnType:(SQLColumnType)newColumnType usingAlias:(NSString *)newAlias withAggregate:(SQLAggregate)aggregate{
    return [self addSQLColumn:[[SQLColumn alloc] initWithColumn:column ofColumnType:newColumnType usingAlias:newAlias aggregate:aggregate]];
}
- (SQLColumn *) addSQLColumn:(SQLColumn *)column{
    if (column.name){
        NSUInteger index = [_columns indexOfObject:column];
        if (index != NSNotFound){
            return _columns[index];
        }
        [_columns addObject:column];
        return column;
    }
    return nil;
}
- (SQLColumn *) getColumnNamed:(NSString *)columnName{
    for (SQLColumn *column in _columns) if ([column.name isEqualToString:columnName] || [column.alias isEqualToString:columnName]) return column;
    return nil;
}
- (SQLColumn *) removeColumnNamed:(NSString *)columnName{
    for (SQLColumn *column in _columns) if ([column.name isEqualToString:columnName] || [column.alias isEqualToString:columnName]){
        [_columns removeObject:column];
        
        return column;
    }
    return nil;
}
- (void) removeColumn:(SQLColumn *)column{
    for (SQLColumn *cColumn in _columns) if (cColumn == column){ 
        [_columns removeObject:cColumn];
        return;
    }
}
- (void) removeAllColumns{
    [_columns removeAllObjects];
}
- (void) addDefaultColumns{
    for (int i = 0; i < defaultColumns().count; i++){
        [self addColumn:[defaultColumns() objectAtIndex:i] ofColumnType:[[defaultColumnTypes() objectAtIndex:i] intValue]];
    }
}
#pragma mark Predicate Methods
- (SQLPredicate *) addPredicate:(id)predicate forSQLColumn:(SQLColumn *)column operator:(SQLOperator)op{
    if (column.name){
        SQLPredicate *pred = [[SQLPredicate alloc] initWithColumn:column.name value:predicate operator:op connection:SQLConnectAnd];
        [_predicates addObject:pred];
        return pred;
    }
    return nil;
}
- (SQLPredicate *) addPredicate:(id)predicate forColumn:(NSString *)columnName{
    return [self addPredicate:predicate forColumn:columnName operator:SQLEquals];
}
- (SQLPredicate *) addPredicate:(id)predicate forColumn:(NSString *)columnName operator:(SQLOperator)op{
    if (columnName && ![columnName isEqualToString:@"*"]){
        SQLPredicate *pred = [[SQLPredicate alloc] initWithColumn:columnName value:predicate operator:op connection:SQLConnectAnd];
        [_predicates addObject:pred];
        return pred;
    }
    assert(NO);
    return nil;
}
- (void) addPredicate:(SQLPredicate *)predicate{
    if (predicate.column){
        [_predicates addObject:predicate];
    }
}
- (void) removePredicate:(SQLPredicate *)predicate{
    [_predicates removeObject:predicate];
}
- (void) removeAllPredicates{
    [_predicates removeAllObjects];
}
- (void) addPredicateGroup:(SQLPredicateGroup *)group{
    if (group){
        [_predicates addObject:group];
    }
}
- (void) removePredicateGroup:(SQLPredicateGroup *)group{
    if (group){
        [_predicates removeObject:group];
    }
}
#pragma mark Order Methods
- (SQLOrder *) addOrderForSQLColumn:(SQLColumn *)column withDirection:(SQLOrderDirection)direction{
    return [self addOrderForColumn:column.name withDirection:direction];
}
- (SQLOrder *) addOrderForColumn:(NSString *)columnName withDirection:(SQLOrderDirection)direction{
    if (columnName){
        SQLOrder *order = [[SQLOrder alloc] initWithColumn:columnName orderDirection:direction];
        NSUInteger index = [_orderings indexOfObject:order];
        if (index == NSNotFound){
            [_orderings addObject:order];
        } else {
            _orderings[index] = order;
        }
        return order;
    }
    return nil;
}
- (void) addOrderParameter:(SQLOrder *)order{
    if (order.column) {
        NSUInteger index = [_orderings indexOfObject:order];
        if (index == NSNotFound){
            [_orderings addObject:order];
        } else {
            _orderings[index] = order;
        }
    }
}
- (void) removeOrderParameter:(SQLOrder *)order{
    [_orderings removeObject:order];
}
- (void) removeOrderWithColumName:(NSString *)column{
    if (!column.length) return;
    [_orderings removeObject:[[SQLOrder alloc] initWithColumn:column orderDirection:SQLOrderAscending]];
}
- (void) removeAllOrderParameters{
    [_orderings removeAllObjects];
}
#pragma mark Grouping Methods
- (void) addGroupColumn:(SQLColumn *)groupColumn{
    [_groups addObject:groupColumn];
}
- (void) removeGroupColumn:(SQLColumn *)groupColumn{
    [_groups removeObject:groupColumn];
}
@end
