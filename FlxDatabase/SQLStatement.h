    //
    //  SQLConstructor.h
    //  GroceryList
    //
    //  Created by Aaron Hayman on 2/11/11.
    //  Copyright 2011 __MyCompanyName__. All rights reserved.
    //

#import <Foundation/Foundation.h>
#import "SQLPredicate.h"
#import "SQLOrder.h"
#import "SQLColumn.h"
#import "SQLStatementProtocol.h"

// Default Column Names
#define GUIDKey @"GUID"
#define SQLCreatedDate @"SQLCreatedDateTime"
#define SQLModifiedDate @"SQLModifiedDateTime"


typedef NS_ENUM(NSUInteger, SQLConflict) {
    SQLConflictReplace,
    SQLConflictIgnore,
    SQLConflictFail,
    SQLConflictAbort,
    SQLConflictRollback
};

/**
 *  The SQLStatement takes a bunch of information (columns, predicates, orderings, groups, etc) and will construct an SQL statment (thus the name...).  Not all the properties available on this class will work for all situations. Specifically, some properties only apply to a query while others will only apply to an update. Each property will explain when and where it can be used.
 *  
 *  @warning You cannot simply `init` (or `new`) this class. It must have a table name in order to be constructed, so one is required.
 *
 *  Generally, you construct a SQLStatement by adding columns, predicates, etc and then pass it to the SQLDatabaseManager for processing. Be careful about creating a SQLStatement, passing it to the manager for processing, and then immediately modifying it. The SQLDatabaseManager doesn't copy the statement, so you'll be modifying the original which could lead to undesirable results.  If you're going to reuse a statement, it's probably best to pass to the manager a copy of the statement instead.
 *
 *  There are quite a few auto-generated readonly properties. However, the order you access some of them is important. Normally, you won't need to access these, except perhaps, to debug a statement but when you do, this is important to know:
    - The `NSString *newStatement` property is auto-generated and *is not cached*. Each time you access it, you're creating a new statement. So if you need to access this, it's recommended you store the string in a local variable.
    - When a `statement` is generated, so also are the parameters: `NSArray *parameters`, and `parameters` *is* cached.  So if you attempt to access a statement's parameters before you access the statement, you'll either get `nil` or you'll get old parameters (if you've modified the statement).
    - Property `NSString *GUID` is auto-generated.  You *can* set your own GUID if you want, pass the statement to the database manager and it will be used (for insertion/updating).  However, this is not recommended. The GUID must be unique to that table.  If not, the statement will fail since the GUID is the primary key on the table. Instead, use the auto-generated GUID (by simply accessing the property one will be generated and cached) and pass the statement to the manager.  Just be aware that the manager will set the GUID to `nil` when it's done, but *after* the return block has been called.  This way, if you pass the statement to the manager again, a new GUID will be created.
    - NSNumber *modified & *created properties are automatically cached when an update/insertion statement is generated. You can set these beforehand by adding a column with one of the default colum names and setting it's value. However, you really shouldn't need to do this. The updated & created dates are automagically generated, which you can access after the SQLStatement has been run.
 **/
@interface SQLStatement : NSObject <SQLStatementProtocol, NSCopying>

/**
 *  This will return a NSArray of SQLColumn items currently in the statement.
 */
@property (readonly) NSArray *columns;

/**
 *  This will return a NSArray of SQLPredicate & SQLPredicateGroup items currently in the statement.
 */
@property (readonly) NSArray *predicates;

/**
 *  This will return a NSArray of SQLOrder items currently in the statement.
 */
@property (readonly) NSArray *orderings;

/**
 *  This will return a NSArray of SQLColumn items currently being grouped.
 */
@property (readonly) NSArray *groups;

/**
 *  This will return a NSArray of SQLColumn items that represent the default columns in the table.  Currently, the default columns represent the GUID, a Created Date, and a Modified Date.  Generally, you don't need to set or modify these columns as it's done automatically during insertion/updating.
 */
@property (readonly) NSArray *defaultColumns;

/**
 *  This is just a NSArray of NSString items for the column names.
 */
@property (readonly) NSArray *defaultColumnNames;

/**
 *  This is only relevant for insertions and updates. It is automatically generated when the statement property is generated.
 *  @warning Be careful about generating a statement (by accessing the statement property), accessing the modified date and then passing the statement to the manager for processing. The modified date will be regenerated when the statement is processed.  Thus the value you received won't be the value inserted into the table. Instead, pass the statement to the manager and grab the modified date in the return block.
 */
@property (readonly) NSNumber *modified;

/**
 *  This is only relevant for insertions and updates. It is automatically generated when the statement property is generated.
 *  @warning Be careful about generating a statement (by accessing the statement property), accessing the created date and then passing the statement to the manager for processing. The created date will be regenerated when the statement is processed.  Thus the value you received won't be the value inserted into the table. Instead, pass the statement to the manager and grab the created date in the return block.
 */
@property (readonly) NSNumber *created;

/**
 *  This is only relevant for insertions and updates. This gives you a few options if your update/insertion conflicts with an existing row, ie: The primary key already exists. The options here represent the standard SQLite conflict options. I'm not going into detail on all that, but you can find everything you need to know here: [http://www.sqlite.org/lang_conflict.html](http://www.sqlite.org/lang_conflict.html).
 *  Default: SQLConflictReplace
 */
@property SQLConflict conflict;

/**
 *  This corresponds to the `LIMIT` clause in SQLite for both queries and updates. If the value is `0` or `negative`, then there is no limit. This will limit the number of results returned from a query or the number of rows affected by an update.
 *  Default: 0
 */
@property NSUInteger limit;

/**
 *  This corresponds to the `OFFSET` clause in SQLite. If the value is `-1` (or any negative number), then the offset doesn't apply. This is most often used in conjunction with `limit` to "page" a large number of query results in an effort to be kind to your local memory.
 *  Default: -1
 */
@property NSInteger offset;

/**
 *  Only used for Queries. This will change a standard "SELECT" to "SELECT DISTINCT". Essentially, if there are duplicate rows in the returned results, this will remove them from the results.
 *  Default: NO
 */
@property bool selectDistinct;

/**
 *  If set to YES, the statement will ignore all other properties and become a Query that returns information on the table itself: `PRAGMA table_info(<tableName>);`. This can often be useful to determine if the table exists before you try querying or updating it. Simply set `tableInfo = NO;` to regain normal functionality.
 *  Default: NO
 */
@property bool tableInfo;

/**
 *  Get/Set the tableName.  Normally, this is set when you initialize the SQLStatement.
 *
 *  @warning You cannot set the tableName to `nil`. The statement must have a tableName in order to function. If you attempt to set the tableName to `nil`, the request will be ignored.
 */
@property (readonly) NSString *tableName;

/**
 *  This is only used when you're altering a table's name. This value must be present if you use `SQLStatementAlterTable`.
 */
@property (strong) NSString *alterTableName;

/**
 *  The actual sql statement used on the databse. The statement is auto-generated each time you access this property, so it's recommended that you store the statement in a local variable. When you access this statement several other properties *can* update:
 *  - GUID (if it hasn't already been set)
 *  - parameters
 *  - created (for insertions)
 *  - modified (for updates/insertions)
 */
@property (readonly) NSString *newStatement;

/**
 *  This contains an array of cached parameters generated from the last time the sql statement was generated.
 */
@property (readonly) NSArray *parameters;

/**
 *  This is the GUID. If you request the property and it's not been set, a new GUID will be automatically generated. If you set this property to `nil`, the next the GUID is accessed a new one will be generated.
 */
@property (strong) NSString *GUID;

/**
 *  This defines what kind of SQL statement will be generated.
 *  @see SQLStatementType
 */
@property SQLStatementType SQLType;

/**
 *  This will return a custom SQLStatement that queries the database ("sqlite_master") for all tables in the database.
 *
 *  @return SQLStatement
 */
+ (SQLStatement *) getAllTables;

/**
 *  This will return a SQLStatement of type `SQLStatementAlterTable` designed to alter the table from one name to another.
 *
 *  @param tableName    The original table name.
 *  @param newTableName The new name you want the table renamed to.
 *
 *  @return SQLStatement
 */
+ (SQLStatement *) renameTable:(NSString *)tableName to:(NSString *)newTableName;

/**
 *  Convenience constructor that returns a SQLStatement for the table you specify with the given type.
 *
 *  @param type  The type of sql statement you want.
 *  @param table The name of the table.
 *
 *  @warning If you attempt to pass `nil` or a zero-length string for a table name, you'll get `nil` back.
 *
 *  @return SQLStatement
 */
+ (SQLStatement *) statementType:(SQLStatementType)type forTable:(NSString *)table;
/**
 *  Init a SQLStatement for the table you specify with the given type.
 *
 *  @param type  The type of sql statement you want.
 *  @param table The name of the table.
 *
 *  @warning If you attempt to pass `nil` or a zero-length string for a table name, you'll get `nil` back.
 *
 *  @return SQLStatement
 */
- (id) initWithType:(SQLStatementType)sqlType forTable:(NSString *)tableName;
#pragma mark Column Methods
/**
 *  This will add the column to the table. If the column already exists in the table, the column won't be added, but instead the original column will be returned. 
 *
 *  @param column The SQLColumn you wish to add
 *
 *  @return The SQLColumn that was added or found (could be different than the one you supplied)
 */
- (SQLColumn *) addSQLColumn:(SQLColumn *)column;
/**
 *  This will add a column with the specified name. The column type will be set to SQLColumnTypeNone.
 *  SQLStatement will search to see if a column already exists with that name. If so, that one will be returned and nothing will be added.
 *
 *  @param column Name of the column.
 *
 *  @return The SQLColumn that was added or found with the same name/alias.
 */
- (SQLColumn *) addColumn:(NSString *)column;
/**
 *  This will add a column with the specified name and alias.
 *  SQLStatement will search to see if a column already exists with that name. If so, that one will be returned and nothing will be added.
 *
 *  @param column   Column Name
 *  @param newAlias Column Alias
 *
 *  @return The SQLColumn that was added or found with the same name/alias.
 */
- (SQLColumn *) addColumn:(NSString *)column usingAlias:(NSString *)newAlias;
/**
 *  Add a column with the specified name and column type.
 *  SQLStatement will search to see if a column already exists with that name. If so, that one will be returned and nothing will be added.
 *
 *  @param column        Column Name
 *  @param newColumnType Column Type
 *
 *  @return The SQLColumn that was added or found with the same name/alias.
 */
- (SQLColumn *) addColumn:(NSString *)column ofColumnType:(SQLColumnType)newColumnType;
/**
 *  Add a column with the specified parameters.
 *  SQLStatement will search to see if a column already exists with that name. If so, that one will be returned and nothing will be added.
 *
 *  @param column        The Column Name
 *  @param newColumnType The Column Type
 *  @param newAlias      *optional* alias for the column
 *  @param aggregate     The Column Aggregate
 *
 *  @return The SQLColumn that was added or found with the same name/alias.
 */
- (SQLColumn *) addColumn:(NSString *)column ofColumnType:(SQLColumnType)newColumnType usingAlias:(NSString *)newAlias withAggregate:(SQLAggregate)aggregate;
/**
 *  Returns a column that has either a name or alias of the one provided.
 *
 *  @param columnName Name/Alias of the column you want.
 *
 *  @return SQLColumn or `nil` if not found.
 */
- (SQLColumn *) getColumnNamed:(NSString *)columnName;
/**
 *  Removes a column with the name or alias of the one provided and returns that column.
 *
 *  @param columnName Name/Alias of the column you want.
 *
 *  @return SQLColumn or `nil` if not found.
 */
- (SQLColumn *) removeColumnNamed:(NSString *)column;
/**
 *  Remove the column, if found.
 *
 *  @param column SQLColumn you wish to remove.
 */
- (void) removeColumn:(SQLColumn *)column;
/**
 *  Removes all columns from the statement.
 */
- (void) removeAllColumns;
/**
 *  Used mostly in queries. The default columns are automatically added for queries. This method will automatically add them to the query.
 */
- (void) addDefaultColumns;
#pragma mark Predicate Methods
/**
 *  Constructs a predicate from the variable provides, adds it to the statement and returns it.
 *
 *  @param predicate The predicate value
 *  @param column    The Column you wish to use. Note: only the column name is grabbed.
 *  @param op        The comparison operator.
 *
 *  @return The SQLPredicate added to the statement.
 */
- (SQLPredicate *) addPredicate:(id)predicate forSQLColumn:(SQLColumn *)column operator:(SQLOperator)op;
/**
 *  Constructs a predicate from the variable provides, adds it to the statement and returns it. Defaults to using Equality predicate type.
 *
 *  @param predicate  Predicate value
 *  @param columnName Column Name
 *
 *  @return The SQLPredicate added to the statement.
 */
- (SQLPredicate *) addPredicate:(id)predicate forColumn:(NSString *)columnName;
/**
 *  Constructs a predicate from the variable provides, adds it to the statement and returns it.
 *
 *  @param predicate The predicate value
 *  @param column    The Name of the column you wish to use.
 *  @param op        The comparison operator.
 *
 *  @return The SQLPredicate added to the statement.
 */
- (SQLPredicate *) addPredicate:(id)predicate forColumn:(NSString *)columnName operator:(SQLOperator)op;
/**
 *  This will add the predicate to the statement.
 *
 *  @param predicate The predicate you wish to add.
 */
- (void) addPredicate:(SQLPredicate *)predicate;
/**
 *  This will remove the predicate from the statement.
 *
 *  @param predicate The predicate you wish to remove.
 */
- (void) removePredicate:(SQLPredicate *)predicate;
/**
 *  This will remove all predicates from the statement.
 */
- (void) removeAllPredicates;
/**
 *  This will add the group to the statement... but I bet you already knew that.
 *
 *  @param group The PredicateGroup you want to add.
 */
- (void) addPredicateGroup:(SQLPredicateGroup *)group;
/**
 *  This will remove...ugh... seriously, you know what this does right?
 *
 *  @param group PredicateGroup.
 */
- (void) removePredicateGroup:(SQLPredicateGroup *)group;
#pragma mark Order Methods
/**
 *  This will a new order and either add it or replace an existing order (if one exists with the same column name).
 *
 *  @param column    The column you wish to add the ordering.
 *  @param direction The direction you want to order by.
 *
 *  @return SQLOrder
 */
- (SQLOrder *) addOrderForSQLColumn:(SQLColumn *)column withDirection:(SQLOrderDirection)direction;
/**
 *  This will create a new order and either add it or replace an existing order (if one exists with the same column name).
 *
 *  @param column    The column you wish to add the ordering.
 *  @param direction The direction you want to order by.
 *
 *  @return SQLOrder
 */
- (SQLOrder *) addOrderForColumn:(NSString *)columnName withDirection:(SQLOrderDirection)direction;
/**
 *  This will either add the order, or replace an existing order if one exists with the same name.
 *
 *  @param order The order you wish to add. (sounds like you're ordering pizza...)
 */
- (void) addOrderParameter:(SQLOrder *)order;
/**
 *  Remove the order from the statement (in case you didn't like the pepperoni).
 *
 *  @param order The order you wish removed.
 */
- (void) removeOrderParameter:(SQLOrder *)order;
/**
 *  Remove an order that's using the supplied column name (if any).
 *
 *  @param column The column name of the order you wish to remove.
 */
- (void) removeOrderWithColumName:(NSString *)column;
/**
 *  I'm pretty sure the method name says it all.
 */
- (void) removeAllOrderParameters;
#pragma mark Grouping Methods
/**
 *  This will add the specified column as a group in the statement.
 *
 *  @param groupColumn The colum you wish to group by.
 */
- (void) addGroupColumn:(SQLColumn *)groupColumn;
/**
 *  This will remove the specified column as a group in the statement.
 *
 *  @param groupColumn The column you wish to remove as a group in the statement.
 */
- (void) removeGroupColumn:(SQLColumn *)groupColumn;
@end
