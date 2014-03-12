    //
    //  ISDatabase.m
    //  GroceryList
    //
    //  Created by Aaron Hayman on 2/3/11.
    //  Copyright 2011 __MyCompanyName__. All rights reserved.
    // pg 159

#import "SQLDatabase.h"
#import "FlxToolkit.h"

@implementation SQLDatabase {
    NSString *pathToDatabase;
	sqlite3 *database;
}

@synthesize pathToDatabase;

#pragma mark - Initialization
- (id) initWithPath:(NSString *)filePath{
    /* Initialization with full path
     - set the pathToDatabase varialbe
     - call open to open the database 
     */
    if ((self = [super init])){
        self.pathToDatabase = filePath;
        [self open];
    }
    return self;
}
- (id) initWithFileName:(NSString *)fileName{
    /* Initialization with filename only.  
     - Get the appropariate path for the Documents Directoy
     - append the filename to the path and return 
     */
    return [self initWithPath:[DocumentDirectory stringByAppendingPathComponent:fileName]];
}
- (void) close{
    /* Close database or raise exception */
    int rc = 0;
    if((rc = sqlite3_close(database)) != SQLITE_OK){
        [self sqlError:@"Failed to close database with message '%S'." errorCode:rc critical:NO];
    }
}
- (void) open{
    /* Opens the database
     - opens the database or raises exception if it fails
     (note: apparently sqlite3_open will create a new database if the file doesn't exist)
     */
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    int rc = 0;
    if((rc = sqlite3_open([self.pathToDatabase UTF8String], &database)) != SQLITE_OK){
        sqlite3_close(database);
        [self sqlError:@"Failed to open database with message '%S'." errorCode:rc critical:YES];
    } else {
        //Limiting the cache to zero to reduce memory footprint.  Might reenable if performance ever becomes a problem.
        const char *pragmaSql = "PRAGMA cache_size = 0";
        if (sqlite3_exec(database, pragmaSql, NULL, NULL, NULL) != SQLITE_OK) {
            FlxAssert(NO, @"Error: failed to execute pragma statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    
}
#pragma mark - mark Execution
- (NSArray *) executeQuery:(NSString *)sql{
    /* this is a simplified executeSQL method that used when there are no parameters */
    return [self executeQuery:sql withParameters:nil];
}
- (NSArray *) columnNamesForStatement:(sqlite3_stmt *)statement{
    /* Given a sqlite3_stmt, this will return an array of the column names */
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *columnNames = [NSMutableArray array];
    for (int i = 0; i < columnCount; i++){
        [columnNames addObject:[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]];
    }
    return columnNames;
}
- (NSArray *) executeQuery:(NSString *)sql withParameters:(NSArray *)parameters{
    return [self executeQuery:sql withParameters:parameters withClassForRow:nil];
}
- (NSArray *) executeQuery:(NSString *)sql withParameters:(NSArray *)parameters withClassForRow:(Class)rowClass{
    if (!rowClass) rowClass = [NSMutableDictionary class];
    if (!sql.length) return nil;
    /* Main executeSQL method.  Takes a sql statement with parameters and returns an array.  Note, the sql statement does not need parameters to function.  Simply set parameters to nil to execute statement without parameters. */
        //Dictionary to store queryInfo
    NSMutableDictionary *queryInfo = [NSMutableDictionary dictionary];
        //Add the sql statement and parameters 
    [queryInfo setObject:sql forKey:@"sql"];
    if (parameters) [queryInfo setObject:parameters forKey:@"parameters"];
        //rows will be returned by the method
    NSMutableArray *rows = [NSMutableArray array];
//    if (logging) FlxLog(@"SQL: %@ \n Parameters: %@", sql, parameters);
    
        //Begin iteration through the sql results
    sqlite3_stmt *statement = nil;
    int rc = 0;
    if ((rc = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL)) == SQLITE_OK){
            //This will only bind parameters if parameters exist
        if (parameters) [self bindArguments: parameters toStatement:statement queryInfo:queryInfo];
            //Arrays to store column names and types.  BOOL is used to get column information only once.  WARNING: sqlite3 can store variable data types in a single column.  This implementation ASSUMES that all data types within a column are the same.  This speeds the code by not fetching data types for each individual row, but may throw an exception or simply crash if the information stored isn't the correct type.
        BOOL needsToFetchColumnTapesAndName = YES;
        NSArray *columnTypes = nil;
        NSArray *columnNames = nil;
            //Iteration call several class methods, see those methods for details
        while (sqlite3_step(statement) == SQLITE_ROW){
            if(needsToFetchColumnTapesAndName){
                columnTypes = [self columnTypesForStatement: statement];
                columnNames = [self columnNamesForStatement: statement];
                needsToFetchColumnTapesAndName = NO;
            }
                //rowClass is generally of class type NSMutableDictionary
            id row = [rowClass new];
            [self copyValuesFromStatement:statement toRow:row queryInfo:queryInfo columnTypes:columnTypes columnNames:columnNames];
            [rows addObject:row];
        }
    } else {
        sqlite3_finalize(statement);
        [self sqlError:[$(@"Failed to execute statement: '%@' with message: ", sql) stringByAppendingString:@"%S"] errorCode:rc critical:NO];
    }
    sqlite3_finalize(statement);
    return rows;
}
- (NSInteger) executeUpdate:(NSString *)sql{
    return [self executeUpdate:sql withParameters:nil];
}
- (NSInteger) executeUpdate:(NSString *)sql withParameters:(NSArray *)parameters{
    if (!sql.length) return -1;
    NSMutableDictionary *queryInfo = [NSMutableDictionary dictionary];
    [queryInfo setObject:sql forKey:@"sql"];
    if (parameters) [queryInfo setObject:parameters forKey:@"parameters"];
    sqlite3_stmt *statement = nil;
    int rc = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (rc == SQLITE_OK){
        if (parameters) [self bindArguments:parameters toStatement:statement queryInfo:queryInfo];
        rc = sqlite3_step(statement);
        if (rc != SQLITE_DONE && rc != SQLITE_ROW){
            sqlite3_finalize(statement);
            [self sqlError:$(@"SQL Update Error: %@", sql) errorCode:rc critical:YES];
            return -1;
        }
        sqlite3_finalize(statement);
        NSInteger rowid = (NSInteger)sqlite3_last_insert_rowid(database);
        return rowid;
    } else {
        sqlite3_finalize(statement);
        [self sqlError:$(@"SQL Update: %@", sql) errorCode:rc critical:YES];
        return -1;
    }
}
#pragma mark - Argument Binding
- (void) bindArguments:(NSArray *)arguments toStatement:(sqlite3_stmt *)statement queryInfo:(NSDictionary *)queryInfo{
    /* This method binds arguments to the sql statement.  Takes an array of objects. And a pointer to the statement */
    int expectedArguments = sqlite3_bind_parameter_count(statement);
        //The number of arguments must match the parameter count in the statement.
    FlxAssert(expectedArguments == [arguments count], @"Number of bound parameters does not match for sql: %@ \n Parameters: %@'", [queryInfo objectForKey:@"sql"], [queryInfo objectForKey:@"parameters"]);
    id argument;
        //Bind each argument to the statement depending on class type
    for (int i=1; i <= expectedArguments; i++){
        argument = [arguments objectAtIndex:i-1];
        if ([argument isKindOfClass:[UIImage class]]){
            argument = UIImagePNGRepresentation((UIImage *)argument);
        }
        if([argument isKindOfClass:[NSString class]])
            sqlite3_bind_text(statement, i, [argument UTF8String], -1, SQLITE_TRANSIENT);
        else if ([argument isKindOfClass:[NSData class]])
            sqlite3_bind_blob(statement, i, [argument bytes], (int)[argument length], SQLITE_TRANSIENT);
        else if ([argument isKindOfClass:[NSDate class]])
            sqlite3_bind_double(statement, i, [argument timeIntervalSinceReferenceDate]);
        else if ([argument isKindOfClass:[NSNumber class]]) {
            if (strcmp([argument objCType], @encode(BOOL)) == 0) {
                sqlite3_bind_int(statement, i, ([argument boolValue] ? 1 : 0));
            }
            else if (strcmp([argument objCType], @encode(int)) == 0) {
                
                sqlite3_bind_int64(statement, i, [argument longValue]);
            }
            else if (strcmp([argument objCType], @encode(long)) == 0) {
                sqlite3_bind_int64(statement, i, [argument longValue]);
            }
            else if (strcmp([argument objCType], @encode(long long)) == 0) {
                sqlite3_bind_int64(statement, i, [argument longLongValue]);
            }
            else if (strcmp([argument objCType], @encode(float)) == 0) {
                sqlite3_bind_double(statement, i, [argument floatValue]);
            }
            else if (strcmp([argument objCType], @encode(double)) == 0) {
                sqlite3_bind_double(statement, i, [argument doubleValue]);
            }
            else {
                sqlite3_bind_text(statement, i, [[argument description] UTF8String], -1, SQLITE_STATIC);
            }
        }
        
        else if ([argument isKindOfClass:[NSNull class]])
            sqlite3_bind_null(statement, i);
        else {
            sqlite3_finalize(statement);
            [NSException raise:@"Unrecognized object type" format:@"Active Record doesn't know how to handle object: '%@' bound to sql: %@ position: %i", argument, [queryInfo objectForKey:@"sql"], i];
        }
    }
    
}
- (NSArray *) columnTypesForStatement:(sqlite3_stmt *)statement{
    /* Returns an array of column types for a given statement */
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *columnTypes = [NSMutableArray array];
    for (int i = 0; i < columnCount; i++){
        [columnTypes addObject:[NSNumber numberWithInt:[self typeForStatement:statement column:i]]];
    }
    return columnTypes;
}
- (int) typeForStatement: (sqlite3_stmt *) statement column: (int) column{
    /*returns the column type for a specific column in a statement */
    const char *columnType = sqlite3_column_decltype(statement, column);
    if (columnType != NULL){
        return [self columnTypeToInt:[[NSString stringWithUTF8String:columnType] uppercaseString]];
    }
    return sqlite3_column_type(statement, column);
}
- (int)columnTypeToInt:(NSString *)columnType{
    /* column types are mapped to ints, this returns the appropriate int for a give column type */
    if ([columnType isEqualToString:@"INTEGER"]){
        return SQLITE_INTEGER;
    } else if ([columnType isEqualToString:@"REAL"]){
        return SQLITE_FLOAT;
    } else if ([columnType isEqualToString:@"TEXT"]){
        return SQLITE_TEXT;
    } else if ([columnType isEqualToString:@"BLOB"]){
        return SQLITE_BLOB;
    } else if ([columnType isEqualToString:@"NULL"]){
        return SQLITE_NULL;
    }
    return SQLITE_TEXT;
}
- (NSArray *) columnsForTableName:(NSString *)tableName{
    NSArray *results = [self executeQuery:[NSString stringWithFormat:@"pragma table_info(%@)", tableName]];
    return [results valueForKey:@"name"];
}
#pragma mark -
#pragma mark Value Copying
- (void) copyValuesFromStatement:(sqlite3_stmt *)statement toRow:(id)row queryInfo:(NSDictionary *)queryInfo columnTypes:(NSArray *)columnTypes columnNames:(NSArray *)columnNames{
        // Copys values from a prepared statement that is being iterated through to a class type (row) by iterating through each column.  Depends on self method valueFromStatement to provide correct return data types given data column data types.
    int columnCount = sqlite3_column_count(statement);
    for (int i=0; i < columnCount; i++){
        id value = [self valueFromStatement:statement column:i queryInfo:queryInfo columnTypes:columnTypes];
        if (value){
            if ([row isKindOfClass:[NSMutableDictionary class]]){
                [row setValue:value forKey:columnNames[i]];
            } else {
                [row setValue:value forKeyPath:columnNames[i]];
            }
        }
    }
}
- (id) valueFromStatement:(sqlite3_stmt *)statement column:(int)column queryInfo:(NSDictionary *)queryInfo columnTypes:(NSArray *)columnTypes{
    /* Returns data for a specific column in an iterated statement given columnTyes.  */
    int columnType = sqlite3_column_type(statement, column);
        //Force conversion to the declared type using sql conversions; this saves some problems with NSNull being assigned to non-object values
    if (columnType == SQLITE_INTEGER){
        return [NSNumber numberWithInt:sqlite3_column_int(statement, column)];
    } else if (columnType == SQLITE_FLOAT){
        return [NSNumber numberWithDouble:sqlite3_column_double(statement, column)];
    } else if (columnType == SQLITE_TEXT){
        const char *text = (const char *)sqlite3_column_text(statement, column);
        if (text){
            return [NSString stringWithUTF8String:text];
        } else {
            return @"";
        }
    } else if (columnType == SQLITE_BLOB){
            //create an NSData object with the same size as the blob
        return [NSData dataWithBytes:sqlite3_column_blob(statement, column) length:sqlite3_column_bytes(statement, column)];
    } else if (columnType == SQLITE_NULL){
        return nil;
    }
    FlxLog(@"Unrecognized SQL column type: %i for sql: %@", columnType, [queryInfo objectForKey:@"sql"]);
    return nil;
}
#pragma mark -
#pragma mark Convenience Methods
- (NSArray *) tables{
        //Returns the current tables in the database
    return [self executeQuery:@"SELECT * FROM sqlite_master WHERE type = 'table'"];
}
- (NSArray *) tableNames{
        //Grabs tableNames
    return [[self tables] valueForKey:@"name"];
}
- (NSUInteger) lastInsertRowId{
    return (NSUInteger) sqlite3_last_insert_rowid(database);
}
- (void) beginImmediateTransaction{
    [self executeQuery:@"BEGIN IMMEDIATE TRANSACTION;"];
}
- (void) beginExclusiveTransaction{
    [self executeQuery:@"BEGIN EXCLUSIVE TRANSACTION;"];
}
- (void)beginReadTransaction{
    [self executeQuery:@"BEGIN TRANSACTION;"];  
}
- (void) commit{
    [self executeQuery:@"COMMIT TRANSACTION;"];
}
- (void) rollback{
    [self executeQuery:@"ROLLBACK TRANSACTION;"];
}
- (NSString *) dbVersion{
    return [NSString stringWithUTF8String:sqlite3_libversion()];
}
#pragma mark -
#pragma mark Error Handling
- (void) sqlError:(NSString *)errorMessage errorCode:(int)errorCode critical:(BOOL)critical{
    NSString *error = $(@"%@ : Error: %@", [self sqliteError:errorCode], errorMessage);
    FlxTry(NO, error, NO, {
        if (critical){
            [FlxAlert displayAlertWithTitle:@"Database Error" message:$(@"Woah!  There seems to be an internal database error!  The error is already being sent to us so we can work to prevent this in the future. However, we must close the app in order to prevent data corruption.  We're really sorry about this but once you tap OK the app will be closed. \n\nError:\n%@", [self sqliteError:errorCode]) completion:^(NSUInteger index) {
                [NSException raise:error format:nil];
            }];
        }
    })
}
- (NSString *) sqliteError:(int)error{
    switch (error) {
        case SQLITE_ERROR:          return $(@" SQL error or missing database : error code %i", error); break;
        case SQLITE_INTERNAL:       return $(@" Internal logic error in SQLite : error code %i", error); break;
        case SQLITE_PERM:           return $(@" Access permission denied : error code %i", error); break;
        case SQLITE_ABORT:          return $(@" Callback routine requested an abort : error code %i", error); break;
        case SQLITE_BUSY:           return $(@" The database file is locked : error code %i", error); break;
        case SQLITE_LOCKED:         return $(@" A table in the database is locked : error code %i", error); break;
        case SQLITE_NOMEM:          return $(@" A malloc() failed : error code %i", error); break;
        case SQLITE_READONLY:       return $(@" Attempt to write a readonly database : error code %i", error); break;
        case SQLITE_INTERRUPT:      return $(@" Operation terminated by sqlite3_interrupt(): error code %i", error); break;
        case SQLITE_IOERR:          return $(@" Some kind of disk I/O error occurred : error code %i", error); break;
        case SQLITE_CORRUPT:        return $(@" The database disk image is malformed : error code %i", error); break;
        case SQLITE_NOTFOUND:       return $(@" Unknown opcode in sqlite3_file_control() : error code %i", error); break;
        case SQLITE_FULL:           return $(@" Insertion failed because database is full : error code %i", error); break;
        case SQLITE_CANTOPEN:       return $(@" Unable to open the database file : error code %i", error); break;
        case SQLITE_PROTOCOL:       return $(@" Database lock protocol error : error code %i", error); break;
        case SQLITE_EMPTY:          return $(@" Database is empty : error code %i", error); break;
        case SQLITE_SCHEMA:         return $(@" The database schema changed : error code %i", error); break;
        case SQLITE_TOOBIG:         return $(@" String or BLOB exceeds size limit : error code %i", error); break;
        case SQLITE_CONSTRAINT:     return $(@" Abort due to constraint violation : error code %i", error); break;
        case SQLITE_MISMATCH:       return $(@" Data type mismatch : error code %i", error); break;
        case SQLITE_MISUSE:         return $(@" Library used incorrectly : error code %i", error); break;
        case SQLITE_NOLFS:          return $(@" Uses OS features not supported on host : error code %i", error); break;
        case SQLITE_AUTH:           return $(@" Authorization denied : error code %i", error); break;
        case SQLITE_FORMAT:         return $(@" Auxiliary database format error : error code %i", error); break;
        case SQLITE_RANGE:          return $(@" 2nd parameter to sqlite3_bind out of range : error code %i", error); break;
        case SQLITE_NOTADB:         return $(@" File opened that is not a database file : error code %i", error); break;
        case SQLITE_ROW:            return $(@" sqlite3_step() has another row ready : error code %i", error); break;
        case SQLITE_DONE:           return $(@" sqlite3_step() has finished executing : error code %i", error); break;
        default:                    return $(@" SQLite database error has occurred: error code %i", error); break;
    }
}
@end