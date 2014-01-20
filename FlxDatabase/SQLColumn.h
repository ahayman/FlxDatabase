//
//  SQLColumn.h
//  iDB
//
//  Created by Aaron Hayman on 9/14/12.
//
//

#import <Foundation/Foundation.h>
@class SQLStatement;

typedef NS_ENUM(NSUInteger, SQLColumnType){
    SQLColumnTypeText,
    SQLColumnTypeInt,
    SQLColumnTypeReal,
    SQLColumnTypeBlob,
    SQLColumnTypeNone
};

typedef NS_ENUM(NSUInteger, SQLAggregate){
    SQLAggregateNone,
    SQLAggregateTotal,
    SQLAggregateMax,
    SQLAggregateMin,
    SQLAggregateAvg,
    SQLAggregateCount
};

/**
 *  The SQLColumn is used as part of a SQLStatement.  It represents a table column in a query or update. While a column can contain information for any query or update, only certain properties will be used, depending on the context to which it is applied.
 */
@interface SQLColumn : NSObject <NSCopying>
/**
 *  The name of the column. This is always used, so you really need to have a name.  Otherwise, really, what's the point?
 */
@property (readonly) NSString *name;
/**
 *  The alias is only used for queries.  It allows you to rename a column in the results. 
 *
 *  It's recommended that you use an alias if you also use any kind of aggregate for the column. Using an aggregate will alter the column name (for example: Total(<columnName>)) and setting the alias will help prevent confusion later when you go to retrieve the value.
 */
@property (readonly) NSString *alias;
/**
 *  The aggregate is only used for Queries and it will aggregate the data in this column according to the type you set here. How this work may depend on how the rest of the statement is setup (other columns, whether you've added groups, etc...).  If you're unsure, you probably need to brush up your SQL.
 *  Default: SQLAggregateNone
 */
@property SQLAggregate aggregate;
/**
 *  This is the data type of the column. SQLite doesn't enforce column types (it's more like a recommendation... you know, like stop signs). However, the column will enforce the data type if you have one set. If the type is set to `SQLColumnTypeNone`, the column will accept any data.
 *  Default: SQLColumnTypeNone
 */
@property SQLColumnType type;
/**
 *  The value is only used for inserts and updates. The value will be validated against the column type unless the column type is `SQLColumnTypeNone`.
 */
@property (strong) id value;
/**
 *  This is used only for creating new columns and tables. This will set the column as a primary key.
 */
@property bool primaryKey;
/**
 *  This is also used for column and table creation. SQLite will require all new records and updates to have a value for this column. However, the column itself doesn't enforce this.
 */
@property bool notNull;
/**
 *  This is used only for creating new columns and tables. SQLite will require all entries into this column to be unique.
 */
@property bool unique;
/**
 *  This returns the string SQL equivalent of the column type.
 */
@property (readonly) NSString *columnTypeString;
/**
 *  This returns the string SQL equivalent of the aggregate type.
 */
@property (readonly) NSString *columnAggregateString;

/**
 *  Init the SQLColumn with a column name.  Defaults to the column type `SQLColumnTypeNone`.
 *
 *  @param columnName Name of the Column
 *
 *  @return SQLColumn object.
 */
- (id) initWithColumn:(NSString *)columnName;
/**
 *  Init the SQLColumn with a column name and an alias. Defaults to the column type `SQLColumnTypeNone`.
 *
 *  @param columnName Name of the column.
 *  @param alias      Alias for the column.
 *
 *  @return SQLColumn object.
 */
- (id) initWithColumn:(NSString *)columnName usingAlias:(NSString *)alias;
/**
 *  Init the SQLColumn with the following parameters:
 *
 *  @param columnName Name of the column.
 *  @param columnType Type of the column.
 *  @param alias      Alias of the column.
 *  @param aggregate  Column Aggregate.
 *
 *  @return SQLColumn object
 */
- (id) initWithColumn:(NSString *)columnName ofColumnType:(SQLColumnType)columnType usingAlias:(NSString *)alias aggregate:(SQLAggregate)aggregate;
/**
 *  Use this function to determine whether a particular value is valid for the column's type.
 *
 *  @param value The value you wish to validate.
 *
 *  @return `YES` if the value is valid, `NO` if it's not.
 */
- (BOOL) validateValue:(id)value;
@end
