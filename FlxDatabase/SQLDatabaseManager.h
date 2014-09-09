    //
    //  SQLExecutionManager.h
    //  GroceryList
    //
    //  Created by Aaron Hayman on 2/23/11.
    //  Copyright 2011 __MyCompanyName__. All rights reserved.
    //

#import <Foundation/Foundation.h>
#import "SQLStatementProtocol.h"
#import "SQLDatabase.h"

#define DatabaseName @"database.db"

@class SQLStatement;
@class SQLUpdateQueue;
@class SQLQueryQueue;

typedef void (^QueueBlock) (NSArray *results);
typedef void (^ExecBlock) (NSInteger result);
typedef void (^CompletionBlock) (void);

@interface SQLDatabaseManager : NSObject <NSCopying>
/**
 *  Returns whether or not the database is open.
 */
@property (readonly) BOOL databaseOpen;
/**
 *  Returns the database file path.
 */
@property (readonly) NSString *databasePath;
/**
 *  Convenience method: Calls `initWithFileName:` appending the file name to the documents directory.
 *
 *  @param fileName The name of the database file in the documents directory you wish to open.
 *
 *  @return SQLDatabaseManager
 */
- (id) initWithFileName:(NSString *)fileName;
/**
 *  Initializes a SQLDatabaseManager and opens the database at the file provided by the path. If no file is present at the path, a new one will be created.  If the file present at the path isn't a SQLite database file, an exception will be thrown.
 *  @warning Only one SQLDatabaseManager can be initialized per file.  If you try to initialize a new SQLDatabaseManager for a file that already has a manager, that existing manager will be returned instead of a new manager.
 *
 *  @param path Full file path to the database file.
 *
 *  @return SQLDatabaseManager
 */
- (id) initWithFilePath:(NSString *)path;
/**
 *  Opens the database is if is not already open. The database is automatically opened on class initialization.
 */
- (void) openDatabase;
/**
 *  Closes the database if it is not already closed.
 */
- (void) closeDatabase;
/**
 *  This will queue an update to be processed at the end of the current run loop.
 *
 *  @param statement      On object that conforms to the SQLStatementProtocol (usually SQLStatement)
 *  @param blockToProcess **optional** block to process on completion.
 */
- (void) queueUpdate:(id <SQLStatementProtocol>)statement withBlock:(ExecBlock)blockToProcess;
/**
 *  This will queue a query to be processed at the end of the current run loop and process the results on the main thread using the supplied block.
 *
 *  @param statement      An object that conforms to the SQLStatementProtocol (usually SQLStatement)
 *  @param blockToProcess The block to process the query. The block will be run on the main thread. If this block is not present, the query will not be run since the results can't be returned.
 */
- (void) queueQuery:(id <SQLStatementProtocol>)statement withBlock:(QueueBlock)blockToProcess;
/**
 *  This will queue a query to be processed at the end of the current run loop
 *
 *  @param statement      An object that conforms to the SQLStatementProtocol (usually SQLStatement)
 *  @param rowClass       Normally, a query will return an array of NSMutableDictionary items. If you specify a row class, the query will return an array of that class type.  Make sure the row class responds to keypaths that are the columns in the query, or else an exception will be thrown.
 *  @param blockToProcess The block to process the query. The block will be run on the main thread. If this block is not present, the query will not be run since the results can't be returned.
 */
- (void) queueQuery:(id<SQLStatementProtocol>)statement usingClassForRow:(Class)rowClass withBlock:(QueueBlock)blockToProcess;
/**
 *  This will queue the queries in the provided queue to run at the end of the current run loop.  The queue you submit will be emptied of it's statements.
 *
 *  @param queue The queue of queries you wish to add.
 */
- (void) queueQueries:(SQLQueryQueue *)queue;
/**
 *  This will queue the updates in the provided queue to run at the end of the current run loop.  The queue you submit will be emptied of it's statements.
 *
 *  @param queue The queue of updates you wish to add.
 */
- (void) queueUpdates:(SQLUpdateQueue *)queue;
/**
 *  This will run the update 'immediately' (as possible) but not synchronously.  Note: any pending updates currently being processed will finished before this is run.
 *
 *  @param statement      On object that conforms to the SQLStatementProtocol (usually SQLStatement)
 *  @param blockToProcess **optional** block to process on completion.
 */
- (void) runImmediateUpdate:(id <SQLStatementProtocol>)statement withBlock:(ExecBlock)blockToProcess;
/**
 *  This will run the update 'immediately' (as possible) but not synchronously.  Note: any pending updates currently being processed will finished before this is run.
 *
 *  @param statement      An object that conforms to the SQLStatementProtocol (usually SQLStatement)
 *  @param blockToProcess The block to process the query.  The block will be passed an array of NSMutableDictionary items that correspond to the rows returned from the query. The block will be run on the main thread. If this block is not present, the query will not be run since the results can't be returned.
 */
- (void) runImmediateQuery:(id <SQLStatementProtocol>)statement withBlock:(QueueBlock)blockToProcess;
/**
 *  This will run the update 'immediately' (as possible) but not synchronously.  Note: any pending updates currently being processed will finished before this is run.
 *
 *  @param statement      An object that conforms to the SQLStatementProtocol (usually SQLStatement)
 *  @param rowClass       The Class you wish to use for rows.  If nil, NSMutableDictionary will be used. The class must have keypaths that correspond to the columns in the statement or else an exception will be thrown.
 *  @param blockToProcess The block to process the query.  The block will be passed an array of rowClass items that correspond to the rows returned from the query. The block will be run on the main thread. If this block is not present, the query will not be run since the results can't be returned.
 */
- (void) runImmediateQuery:(id<SQLStatementProtocol>)statement usingRowClass:(Class)rowClass withBlock:(QueueBlock)blockToProcess;
/**
 *  This will process the query queue immediately (as possible) after any currently processing queues are finished.  The queue will be emptied of it's statements.
 *  @see runQueryQueue:withCompletionBlock:
 *
 *  @param queue The queue of queries you with to process.
 */
- (void) runQueryQueue:(SQLQueryQueue *)queue;
/**
 *  This will process the query queue immediately (as possible) after any currently processing queues are finished.  The queue will be emptied of it's statements.
 *
 *  @param queue The queue of queries you with to process.
 *  @param block **optional** Completion block to be run when finished processing.
 */
- (void) runQueryQueue:(SQLQueryQueue *)queue withCompletionBlock:(CompletionBlock)block;
/**
 *  This will process the update queue immediately (as possbile) after any currently processing queues are finished.  The queue will be emptied of it's statements.
 *
 *  @param queue          The update queue you wish to process.
 *  @param blockToProcess **optional** A completion block to be processed after all the updates have been run. If the block returns YES, then all updates were processed.  If the block returns no, then no updates were processed (or the updates were rolled back).  Just because this returns YES doesn't mean all updates were successfull.
 */
- (void) runUpdateQueue:(SQLUpdateQueue *)queue withCompletionBlock:(void (^)(BOOL success))blockToProcess;
/**
 *  This will synchronously run an update.  However, the update is still processed on a dedicated background queue, so whatever thread you call this from will be locked until the processing is complete.  Any current queues processing will be completed *before* this statement is processed.  This means you may be waiting not only for this statment to process, but also for other pending statement to process if there are any.
 *
 *  *A note about the main thread*
 *  It should be safe to call this from the main thread. This class *never* dispatches to the main thread synchronously. So even if you lock the main thread up with this, the background thread will continue un-impeded while the main thread waits.  However, any statements blocks that were dispatched *while* the main thread was locked up will wait until it's available again.  This means if you call this method from the main thread, it will execute the results *before* any previously submitted (non synchronous) statements results are returned even though those statements were run before this one.  Because of this 'out of order' block execution, you should not rely on the results of a "recently submitted" asynchronous processing request. In general, don't mix asynchronous and synchronous requests with a scope... it'll make your life a bit easier.
 *
 *  @param statement The statement you wish to process synchronously.
 *
 *  @return The result of the update. '-1' => fail.  Anything else is success.
 */
- (NSUInteger) runSynchronousUpdate:(id <SQLStatementProtocol>)statement;
/**
 *  This will synchronously run an query.  However, the query is still processed on a dedicated background queue, so whatever thread you call this from will be locked until the processing is complete.  Any current queues processing will be completed *before* this statement is processed.  This means you may be waiting not only for this statment to process, but also for other pending statement to process if there are any.
 *
 *  *A note about the main thread*
 *  It should be safe to call this from the main thread. This class *never* dispatches to the main thread synchronously. So even if you lock the main thread up with this, the background thread will continue un-impeded while the main thread waits.  However, any statements blocks that were dispatched *while* the main thread was locked up will wait until it's available again.  This means if you call this method from the main thread, it will execute the results *before* any previously submitted (non synchronous) statements results are returned even though those statements were run before this one.  Because of this 'out of order' block execution, you should not rely on the results of a "recently submitted" asynchronous processing request. In general, don't mix asynchronous and synchronous requests with a scope... it'll make your life a bit easier.
 *
 *  @param statement The statement you wish to process synchronously.
 *
 *  @return An array of NSMutableDictionary items representing the query row data.
 */
- (NSArray *) runSynchronousQuery:(id <SQLStatementProtocol>)statement;
/**
 *  This will synchronously run an query.  However, the query is still processed on a dedicated background queue, so whatever thread you call this from will be locked until the processing is complete.  Any current queues processing will be completed *before* this statement is processed.  This means you may be waiting not only for this statment to process, but also for other pending statement to process if there are any.
 *
 *  *A note about the main thread*
 *  It should be safe to call this from the main thread. This class *never* dispatches to the main thread synchronously. So even if you lock the main thread up with this, the background thread will continue un-impeded while the main thread waits.  However, any statements blocks that were dispatched *while* the main thread was locked up will wait until it's available again.  This means if you call this method from the main thread, it will execute the results *before* any previously submitted (non synchronous) statements results are returned even though those statements were run before this one.  Because of this 'out of order' block execution, you should not rely on the results of a "recently submitted" asynchronous processing request. In general, don't mix asynchronous and synchronous requests with a scope... it'll make your life a bit easier.
 *
 *  @param statement The statement you wish to process synchronously.
 *  @param rowClass       The Class you wish to use for rows.  If nil, NSMutableDictionary will be used. The class must have keypaths that correspond to the columns in the statement or else an exception will be thrown.
 *
 *  @return An array of rowClass items representing the query row data.
 */
- (NSArray *) runSynchronousQuery:(id<SQLStatementProtocol>)statement usingRowClass:(Class)rowClass;
/**
 *  This will synchronously run the upates in the queue. However, the updates are still processed on a dedicated background queue, so whatever thread you call this from will be locked until the processing is complete.  Any current queues processing will be completed *before* these statement are processed.  This means you may be waiting not only for this statment to process, but also for other pending statement to process if there are any.
 *
 *  *A note about the main thread*
 *  It should be safe to call this from the main thread. This class *never* dispatches to the main thread synchronously. So even if you lock the main thread up with this, the background thread will continue un-impeded while the main thread waits.  However, any statements blocks that were dispatched *while* the main thread was locked up will wait until it's available again.  This means if you call this method from the main thread, it will execute the results *before* any previously submitted (non synchronous) statements results are returned even though those statements were run before this one.  Because of this 'out of order' block execution, all blocks included in the updates will be run *after* this method returns (and the current stack is finished). It is therefore recommended you do not use execution block in the individual updates.  Instead, wait for the updates to finish and then process everything at once using the array of return values.
 *
 *  @param updates The update queue you wish to process.
 *
 *  @return An NSArray of NSNumbers representing the result of each update in the queue (respective of order, of course).  If `nil` is returned, then an update failed which caused a rollback (a setting on the Queue itself).
 */
- (NSArray *) runSynchronousUpdateQueue:(SQLUpdateQueue *)updates;
/**
 *  This will take a statement, compare the columns in that statement to the columns in the database table (also listed in the statement) and add any missing columns listed in the statement to the table. If the table doesn't exist, this will create a new table with the column in the statement.  This *will not* delete columns in the table not present in the statement because, quite frankly, SQLite doesn't allow column deletion.
   This is a synchronous version of the call.
 *
 *  @param statement       The statement you want to use to update the table to.
 *  @param completionBlock **optional** completion block to be run when done.
 */
- (void) updateOrCreateTableToColumnsInStatement:(SQLStatement *)statement;
/**
 *  This will take a statement, compare the columns in that statement to the columns in the database table (also listed in the statement) and add any missing columns listed in the statement to the table. If the table doesn't exist, this will create a new table with the column in the statement.  This *will not* delete columns in the table not present in the statement because, quite frankly, SQLite doesn't allow column deletion.
 *
 *  @param statement       The statement you want to use to update the table to.
 *  @param completionBlock **optional** completion block to be run when done.
 */
- (void) updateOrCreateTableToColumnsInStatement:(SQLStatement *)statement onCompletion:(CompletionBlock)completionBlock;
/**
 *  This will take a statement, compare the columns in that statement to the columns in the database table (also listed in the statement) and add any missing columns listed in the statement to the table.  This *will not* delete columns in the table not present in the statement because, quite frankly, SQLite doesn't allow column deletion.
 *
 *  @param statement       The statement you want to use to update the table to.
 *  @param completionBlock **optional** completion block to be run when done.
 */
- (void) updateTableToColumnsInStatement:(SQLStatement *)statement onCompletion:(CompletionBlock)completionBlock;
/**
 *  Similar to `updateTableToColumnsInStatement:onCompletion` this will update a database table to the columns listed in the statement.  
 *  However, initially, nothing will be done.  Instead, a query will be added to the query queue you provide. When that query is processed, the appropriate updates will be added to the update queue you provide.  You must then process the update queue to effect the approriate updates in the table.
 *  This will allow you to update a large number of tables in an effecient manner by processing all the queries first and then processing all the updates at the same time (in a single transaction).  To be clear: this can be a huge effeciency gain. Use this if you're updating a lot of tables.
 *
 *  @param statement   The statement you want to update the table to.
 *  @param queryQueue  A query queue you previously instantiated.  If you pass 'nil' here, nothing will be processed.
 *  @param updateQueue An update queue you previously instantiated. If you pass 'nil' here, nothing will be processed.
 */
- (void) updateTableToColumnsInStatement:(SQLStatement *)statement usingQueryQueue:(SQLQueryQueue *)queryQueue andUpdateQueue:(SQLUpdateQueue *)updateQueue;

/**
 *  ### Manager Storage
 *
 * Just as there should only be one Database Manager per database file, there often needs a way to ensure only one "sub manager" per Database Manager (for managing a table or set of tables).  This allows you to store a manager based on class to ensure only one is created per database manager.
 *
 *  @param manager The manager you wish to store.  It will be stored using it's class string as a key.
 */
- (void) setManager:(id)manager;
/**
 *  Returns a stored manager for the given class.
 *
 *  @param managerClass The class of the manager you wish to retrieve.
 *
 *  @return returns the manager or nil if there is none.
 */
- (id) getManagerForClass:(Class)managerClass;
@end

/**
 *  The update Queue is a place to store SQL Statements you can then pass on to the SQLDatabaManager for processing.
 */
@interface SQLUpdateQueue : NSObject
/**
 *  If set to yes, all updates in this queue will be rolled back (cancelled) if one of them fails.
 *  Default: NO.
 */
@property BOOL rollbackOnFail;
/**
 *  Adds the statement with corresponding block to the Queue.
 *
 *  @param statement The SQL statement to be processed.
 *  @param block     **optional** The block to process the results of the SQL statement.
 *
 *  @return BOOL value indicating whether the statement was successfully added.  This would fail if you added a Query to this queue instead of an Update.
 */
- (bool) addSQLUpdate:(id <SQLStatementProtocol>)statement withBlock:(ExecBlock)block;
/**
 *  This will append the updates from the provided Queue to this one.
 *
 *  @param updateQueue The update queue you want to append to this one.
 */
- (void) appendUpdatesFromQueue:(SQLUpdateQueue *)updateQueue;
/**
 *  This will, of course, remove all statements from this queue.
 */
- (void) removeAllStatements;

@end

/**
 *  The query Queue is a place to store SQL Statements you can then pass on to the SQLDatabaManager for processing.
 */
@interface SQLQueryQueue : NSObject
/**
 *  Add a new query with corresponding block to the Queue.
 *
 *  @param statement The SQL statement to be processed.
 *  @param block     The block to process the results of the query.  This is not optional. If you don't supply a block, the query will not be run.
 *
 *  @return YES if the statement was added, NO if it was not added. The statement won't be added if the statement is not a query or if you do not supply a block.
 */
- (bool) addSQLQuery:(id <SQLStatementProtocol>)statement withBlock:(QueueBlock)block;
/**
 *  Add a new query with corresponding block to the Queue.
 *
 *  @param statement The SQL statement to be processed.
 *  @param block     The block to process the results of the query.  This is not optional. If you don't supply a block, the query will not be run.
 *  @param rowClass The class to use for row items returned by the query.
 *
 *  @return YES if the statement was added, NO if it was not added. The statement won't be added if the statement is not a query or if you do not supply a block.
 */
- (bool) addSQLQuery:(id <SQLStatementProtocol>)statement usingRowClass:(Class)rowClass withBlock:(QueueBlock)block;
/**
 *  This will append the queries from the provided Queue to this one.
 *
 *  @param queryQueue The query queue you want to append to this one.
 */
- (void) appendQueriesFromQueue:(SQLQueryQueue *)queryQueue;
/**
 *  This will remove all the statement from the queue.
 */
- (void) removeAllStatements;
@end
