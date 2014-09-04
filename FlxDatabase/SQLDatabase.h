    //
    //  ISDatabase.h
    //  GroceryList
    //
    //  Created by Aaron Hayman on 2/3/11.
    //  Copyright 2011 __MyCompanyName__. All rights reserved.
    //

#import <UIKit/UIKit.h>

@interface SQLDatabase : NSObject 

/**
 *  This is the path to the database. This will need to be set before you open the database.  However, normally this should be necessary as you'd normally use either `initWithPath:` or `initWithFileName:` which will set this property on initialization.
 */
@property (nonatomic, retain) NSString *pathToDatabase;
/**
 Returns a SQLDatabse at the specified path. If no file exists at that path, a new database will be created. This will automatically 'open' the database for use.
 */
- (id) initWithPath:(NSString *) filePath;
/**
 Returns a SQLDatabase at the specified fileName in the standard Documents directory path. If no file exists at that path, a new database will be created. This will automatically 'open' the database for use.
 **/
- (id) initWithFileName:(NSString *)fileName;
/**
 This will close the database.  Required if you intend on moving the database file.
 */
- (void) close;
/**
 This will open the database.  There is no need to call this after class inititlization as it will be called as part of the initilization.
 */
- (void) open;
/**
 Convenience method that calls: `executeQuery:withParameters`, passing `nil` as the parameters.  Generally, unless it's a very simple query, it's not recommended you use this or else risk code injection.
 @return Returns an array of NSMutableDictionary items that reflects the row results.
 */
- (NSArray *) executeQuery:(NSString *)sql;
/**
 *  Executes a query with the parameters provided.
 *
 *  @param sql        The query statement.
 *  @param parameters The parameter values (should match '?' in the statement).
 *
 *  @return An array of NSMutableDictionary items for each row returned from the query.
 */
- (NSArray *) executeQuery:(NSString *)sql withParameters:(NSArray *)parameters;
/**
 *  Executes a query with the parameters provided.
 *
 *  @param sql        The query statement.
 *  @param parameters The parameter values (should match '?' in the statement).
 *  @param rowClass   The class type you want created for each row returned. For each column returned in the query, the resulting value will be set on the class type using the column name as the keyPath. If `nil` is passed, NSMutableDictionary class will be used as the row class.
 *  @warning If the rowClass doesn't respond to a keyPath (column name), an exception will be thrown.
 *
 *  @return An array of class items that represent the items returned in the query.
 */
- (NSArray *) executeQuery:(NSString *)sql withParameters:(NSArray *)parameters withClassForRow:(Class)rowClass;
/**
 *  This will execute the query.  It's not recommended you use this method for if there are any unkown parameters. Instead, parameratize the statement and use `executeUpdate:withParameters` instead.
 *
 *  @param sql The SQL update statement.
 *
 *  @return An integer representing success.  -1 if the update failed.
 */
- (NSInteger) executeUpdate:(NSString *)sql;
/**
 *  This will execute the query with the given parameters.  Each '?' in the statement must match up with a parameter in the supplied parameters.
 *
 *  @param sql The SQL update statement.
 *  @param parameters The parameter values (should match '?' in the statement).
 *
 *  @return An integer representing success. -1 if the update failed.
 */
- (NSInteger) executeUpdate:(NSString *)sql withParameters:(NSArray *)parameters;
/**
 *  Grab an array of columns for the provided table name.
 *
 *  @param tableName The name of the table you want to get columns for.
 *
 *  @return An array of NSString column names.
 */
- (NSArray *) columnsForTableName:(NSString *)tableName;
/**
 *  Grab all table information for the database.
 *
 *  @return Returns an array of NSMutableDictionary items for each table in the database.
 */
- (NSArray *) tables;
/**
 *  Grab all table names in the database.
 *
 *  @return Returns an array of NSString items for each table in the database.
 */
- (NSArray *) tableNames;
/**
 *  This will begin an immediate transaction. You should follow up with "commit" when you're done.
 */
- (void) beginImmediateTransaction;
/**
 *  This will begin an exclusive transaction. You should follow this up with "commit" when you're done.
 */
- (void) beginExclusiveTransaction;
/**
 *  This will begin a read transaction (which is, in fact, just a regular transaction). You should follow this up with "commit".
 */
- (void) beginReadTransaction;
/**
 *  This will commit the transaction (if you're updating) or end the transaction (for a query).  Really, it's all the same thing.
 */
- (void) commit;
/**
 *  This will rollback a set of updates in a transaction.
 */
- (void) rollback;
/**
 *  @return This will return the last row ID inserted.
 */
- (NSUInteger) lastInsertRowId;
/**
 *  @return Returns the database version.
 */
- (NSString *) dbVersion;
@end
