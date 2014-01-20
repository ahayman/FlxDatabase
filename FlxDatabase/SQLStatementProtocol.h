//
//  SQLStatementProtocol.h
//  FlxDatabase
//
//  Created by Aaron Hayman on 1/17/14.
//  Copyright (c) 2014 Aaron Hayman. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  All of the possible sql statements that can be generated.
 */
typedef NS_ENUM(NSUInteger, SQLStatementType){
    /**
     *  This will create a new table in a database.
     */
    SQLStatementCreate,
    /**
     *  This will update a table's rows (1 or more, depending on the predicate value).
     */
    SQLStatementUpdate,
    /**
     *  This will insert a new row into a table.
     */
    SQLStatementInsert,
    /**
     *  This will query a table and return an array of rows.
     */
    SQLStatementQuery,
    /**
     *  This will delete one or more rows from a table.
     */
    SQLStatementDelete,
    /**
     *  This will drop the table (delete it and all of it's contents).
     */
    SQLStatementDropTable,
    /**
     *  This will alter a table's name.
     */
    SQLStatementAlterTable,
    /**
     *  This will add one or more columns to the table.
     */
    SQLStatementAddColumn
};

/**
 *  The SQLStatementProtocol is used the by SQLDatabaseManager to process SQL statement against the database.
 */
@protocol SQLStatementProtocol <NSObject>
/**
 *  This is the SQL statement to run against the database.
 */
@property (readonly) NSString *newStatement;
/**
 *  This array should contain the parameters used in the SQL statement.  There should be exactly one array item per '?' (parameter) used in the SQL statement.
 */
@property (readonly) NSArray *parameters;
/**
 *  The GUID (globally unique identifier) is used as the primary ID for updates.  While the SQLDatabaseManager doesn't use the GUID, it will set the GUID to `nil` after processing an update.
 *  
 *  The GUID should never return `nil`. If there is no GUID set, then the property should auto-generate a new GUID and cache that. Thus, the GUID can be reset by setting it to `nil`, which will cause it to be auto generated next time it's requested.
 */
@property (strong) NSString *GUID;
/**
 *  This is the type of SQLStatement.
 */
@property SQLStatementType SQLType;
@end
