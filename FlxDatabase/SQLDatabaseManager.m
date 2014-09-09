//
//  SQLExecutionManager.m
//  GroceryList
//
//  Created by Aaron Hayman on 2/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SQLDatabaseManager.h"
#import "SQLStatement.h"

#define DBQueue "SQLExecutionQueue"
#define DBOperation "SQLOperationQueue"
#define DocumentDirectory (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject)

@interface WeakContainer : NSObject
@property (weak) id object;
+ (instancetype) contain:(__weak id)object;
@end
@implementation WeakContainer
+ (instancetype) contain:(__weak id)object{
  WeakContainer *container = [WeakContainer new];
  container.object = object;
  return container;
}
@end

@interface SQLUpdateBlock : NSObject
@property  (readonly) id <SQLStatementProtocol> statement;
@property (readonly) ExecBlock block;
@property NSUInteger result;
- (id) initWithConstructor:(id <SQLStatementProtocol> )statement block:(ExecBlock)block;
@end

@implementation SQLUpdateBlock
- (id) initWithConstructor:(id <SQLStatementProtocol> )statement block:(ExecBlock)block{
  if (self = [super init]){
    _block = [block copy];
    _statement = statement;
  }
  return self;
}
@end

@interface SQLQueryBlock : NSObject
@property (readonly) id <SQLStatementProtocol> statement;
@property (readonly) QueueBlock block;
@property (readonly) Class rowClass;
- (id) initWithConstructor:(id <SQLStatementProtocol> )statement block:(QueueBlock)block rowClass:(Class)rowClass;
@end

@implementation SQLQueryBlock
- (id) initWithConstructor:(id <SQLStatementProtocol> )statement block:(QueueBlock)block rowClass:(__unsafe_unretained Class)rowClass{
  if (self = [super init]){
    _block = [block copy];
    _statement = statement;
    _rowClass = rowClass;
  }
  return self;
}
@end

@interface SQLQueryQueue () <NSFastEnumeration>
@property (readonly) NSArray *blocks;
@property (readonly) NSUInteger count;
+ (SQLQueryQueue *) queueWithQueue:(SQLQueryQueue *)queue;
- (SQLQueryBlock *) queryBlockAtIndex:(NSUInteger)index;
@end

@interface SQLUpdateQueue () <NSFastEnumeration>
@property (readonly) NSArray *blocks;
@property (readonly) NSUInteger count;
+ (SQLUpdateQueue *) queueWithQueue:(SQLUpdateQueue *)queue;
- (SQLUpdateBlock *) updateBlockAtIndex:(NSUInteger)index;
@end

@interface SQLDatabaseManager (private)
- (void) processPendingQueue;
@end

static NSMutableDictionary *DBManagers(){
  static NSMutableDictionary *managers = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    managers = [NSMutableDictionary new];
  });
  return managers;
}

@implementation SQLDatabaseManager{
  SQLUpdateQueue *_updateQueue;
  SQLQueryQueue *_queryQueue;
  SQLDatabase *_database;
  BOOL _dbOpen;
  BOOL _queriesNeedProcessing;
  BOOL _updatesNeedProcessing;
  dispatch_queue_t _databaseQueue;
  dispatch_queue_t _operationsQueue;
  
  NSMutableDictionary *_managers;
}

#pragma mark - Init/Singleton Methods
- (id) initWithFileName:(NSString *)fileName{
  return [self initWithFilePath:[DocumentDirectory stringByAppendingPathComponent:fileName]];
}
- (id) initWithFilePath:(NSString *)path{
  if (!path.length) return nil;
  //Only one manager can be instantiated for an individual path
  NSMutableDictionary *managers = DBManagers();
  SQLDatabaseManager *manager = [managers[path] object];
  if (!manager){
    if (self = [super init]){
      _updateQueue = [[SQLUpdateQueue alloc] init];
      _queryQueue = [[SQLQueryQueue alloc] init];
      
      _database = [[SQLDatabase alloc] initWithPath:path];
      _dbOpen = YES;
      _queriesNeedProcessing = NO;
      _updatesNeedProcessing = NO;
      _databaseQueue = dispatch_queue_create(DBQueue, DISPATCH_QUEUE_SERIAL);
      _operationsQueue = dispatch_get_main_queue();
      
      _managers = [NSMutableDictionary new];
    }
    managers[path] = [WeakContainer contain:self];
    return self;
  } else {
    return manager;
  }
}
#pragma mark -  Private Methods
- (void) setQueryNeedsProcessing{
  if (!_queriesNeedProcessing){
    _queriesNeedProcessing = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSelector:@selector(processPendingQueries) withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
    });
  }
}
- (void) setUpdateNeedsProcessing{
  if (!_updatesNeedProcessing){
    _updatesNeedProcessing = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSelector:@selector(processPendingUpdates) withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
    });
  }
}
- (void) processPendingUpdates{
  _updatesNeedProcessing = NO;
  if ([_updateQueue count] > 0)
    [self runUpdateQueue:_updateQueue withCompletionBlock:nil];
}
- (void) processPendingQueries{
  _queriesNeedProcessing = NO;
  if ([_queryQueue count] > 0)
    [self runQueryQueue:_queryQueue];
}
#pragma mark - Protocol Methods
- (id) copyWithZone:(NSZone *)zone{
  return self;
}
#pragma mark - Property Methods
- (BOOL) databaseOpen{
  return _dbOpen;
}
- (NSString *) databasePath{
  return _database.pathToDatabase;
}
#pragma mark - Standard Methods
- (void) openDatabase{
  if (!_dbOpen){
    [_managers removeAllObjects];
    [_database open];
    _dbOpen = YES;
  }
}
- (void) closeDatabase{
  if (_dbOpen){
    [_database close];
    _dbOpen = NO;
  }
}
- (void) queueUpdate:(id <SQLStatementProtocol> )statement withBlock:(ExecBlock)blockToProcess{
  [_updateQueue addSQLUpdate:statement withBlock:blockToProcess];
  [self setUpdateNeedsProcessing];
}
- (void) queueQuery:(id <SQLStatementProtocol> )statement withBlock:(QueueBlock)blockToProcess{
  [_queryQueue addSQLQuery:statement withBlock:blockToProcess];
  [self setQueryNeedsProcessing];
}
- (void) queueQuery:(id<SQLStatementProtocol>)statement usingClassForRow:(Class)rowClass withBlock:(QueueBlock)blockToProcess{
  [_queryQueue addSQLQuery:statement usingRowClass:rowClass withBlock:blockToProcess];
  [self setQueryNeedsProcessing];
}
- (void) queueQueries:(SQLQueryQueue *)queue{
  [_queryQueue appendQueriesFromQueue:queue];
  [queue removeAllStatements];
  [self setQueryNeedsProcessing];
}
- (void) queueUpdates:(SQLUpdateQueue *)queue{
  [_updateQueue appendUpdatesFromQueue:queue];
  [queue removeAllStatements];
  [self setUpdateNeedsProcessing];
}
- (void) runImmediateUpdate:(id <SQLStatementProtocol> )statement withBlock:(ExecBlock)blockToProcess{
  SQLUpdateQueue *queue = [[SQLUpdateQueue alloc] init];
  [queue addSQLUpdate:statement withBlock:blockToProcess];
  [self runUpdateQueue:queue withCompletionBlock:nil];
}
- (void) runImmediateQuery:(id <SQLStatementProtocol> )statement withBlock:(QueueBlock)blockToProcess{
  SQLQueryQueue *queue = [[SQLQueryQueue alloc] init];
  [queue addSQLQuery:statement withBlock:blockToProcess];
  [self runQueryQueue:queue];
}
- (void) runImmediateQuery:(id<SQLStatementProtocol>)statement usingRowClass:(Class)rowClass withBlock:(QueueBlock)blockToProcess{
  SQLQueryQueue *queue = [SQLQueryQueue new];
  [queue addSQLQuery:statement usingRowClass:rowClass withBlock:blockToProcess];
  [self runQueryQueue:queue];
}
- (void) runUpdateQueue:(SQLUpdateQueue *)queue withCompletionBlock:(void (^)(BOOL success))blockToProcess{
  if (!_dbOpen) return;
  if (queue == _updateQueue) {
    _updateQueue = [SQLUpdateQueue new];
  }
  
  if ([queue count] > 0){
    dispatch_async(_databaseQueue, ^{
      if (queue.rollbackOnFail){
        BOOL rollback = NO;
        [_database beginImmediateTransaction];
        for (SQLUpdateBlock *block in queue) {
          id <SQLStatementProtocol> statement = block.statement;
          if (statement.SQLType == SQLStatementQuery) continue;
          NSInteger sqlResult = [_database executeUpdate:statement.newStatement withParameters:statement.parameters];
          block.result = sqlResult;
          if (sqlResult == -1 && queue.rollbackOnFail){
            rollback = YES;
            break;
          }
        }
        if (rollback){
          [_database rollback];
          if (blockToProcess) {
            blockToProcess(NO);
          }
        } else {
          [_database commit];
          for (SQLUpdateBlock *block in queue){
            ExecBlock currentBlock = block.block;
            if (currentBlock){
              dispatch_async(_operationsQueue, ^{
                currentBlock(block.result);
                block.statement.GUID = nil;
              });
            } else {
              block.statement.GUID = nil;
            }
          }
          if (blockToProcess) {
            blockToProcess(YES);
          }
          [queue removeAllStatements];
        }
      } else {
        [_database beginImmediateTransaction];
        for (SQLUpdateBlock *block in queue) {
          id <SQLStatementProtocol> statement = block.statement;
          if (statement.SQLType == SQLStatementQuery) continue;
          NSInteger sqlResult = [_database executeUpdate:statement.newStatement withParameters:statement.parameters];
          ExecBlock currentBlock = block.block;
          if (currentBlock){
            dispatch_async(_operationsQueue, ^{
              currentBlock(sqlResult);
              statement.GUID = nil;
            });
          } else {
            statement.GUID = nil;
          }
        }
        [_database commit];
        if (blockToProcess) {
          blockToProcess(YES);
        }
        [queue removeAllStatements];
      }
    });
  }
}
- (void) runQueryQueue:(SQLQueryQueue *)queue{
  [self runQueryQueue:queue withCompletionBlock:nil];
}
- (void) runQueryQueue:(SQLQueryQueue *)queue withCompletionBlock:(CompletionBlock)block{
  if (!_dbOpen) return;
  if (queue == _queryQueue){
    _queryQueue = [SQLQueryQueue new];
  }
  
  if ([queue count] > 0){
    dispatch_async(_databaseQueue, ^{
      [_database beginReadTransaction];
      for (SQLQueryBlock *block in queue){
        id <SQLStatementProtocol> statement = block.statement;
        if (statement.SQLType != SQLStatementQuery) continue;
        QueueBlock currentBlock = block.block;
        if (!currentBlock) continue;
        NSArray *sqlResult = [_database executeQuery:statement.newStatement withParameters:statement.parameters withClassForRow:block.rowClass];
        dispatch_async(_operationsQueue, ^{
          currentBlock(sqlResult); 
        });
      }
      [_database commit];
      if (block) {
        dispatch_async(_operationsQueue, block);
      }
      [queue removeAllStatements];
    });
  }
}
- (NSArray *) runSynchronousQuery:(id <SQLStatementProtocol> )statement{
  if (!_dbOpen) return nil;
  __block NSArray *sqlResult = nil;
  dispatch_sync(_databaseQueue, ^{
    [_database beginReadTransaction];
    sqlResult = [_database executeQuery:statement.newStatement withParameters:statement.parameters];
    [_database commit];
  });
  
  return sqlResult;
}
- (NSArray *) runSynchronousQuery:(id<SQLStatementProtocol>)statement usingRowClass:(Class)rowClass{
  if (!_dbOpen) return nil;
  __block NSArray *sqlResult = nil;
  dispatch_sync(_databaseQueue, ^{
    [_database beginReadTransaction];
    sqlResult = [_database executeQuery:statement.newStatement withParameters:statement.parameters withClassForRow:rowClass];
    [_database commit];
  });
  return sqlResult;
}
- (NSUInteger) runSynchronousUpdate:(id <SQLStatementProtocol> )statement{
  if (!_dbOpen) return -1;
  __block NSUInteger result = 0;
  dispatch_sync(_databaseQueue, ^{
    [_database beginImmediateTransaction];
    result = [_database executeUpdate:statement.newStatement withParameters:statement.parameters];
    [_database commit];
    statement.GUID = nil;
  });
  return result;
}
- (NSArray *) runSynchronousUpdateQueue:(SQLUpdateQueue *)updates{
  __block NSMutableArray *results = [NSMutableArray new];
  dispatch_sync(_databaseQueue, ^{
    if (updates.rollbackOnFail){
      BOOL rollback = NO;
      [_database beginImmediateTransaction];
      for (SQLUpdateBlock *update in updates){
        NSInteger result = [_database executeUpdate:update.statement.newStatement withParameters:update.statement.parameters];
        if (result == -1 && updates.rollbackOnFail){
          rollback = YES;
          break;
        }
        update.result = result;
        update.statement.GUID = nil;
      }
      if (rollback){
        [_database rollback];
        results = nil;
      } else {
        for (SQLUpdateBlock *update in updates){
          [results addObject:@(update.result)];
          if (update.block){
            dispatch_async(_operationsQueue, ^{
              update.block(update.result);
            });
          }
        }
        [_database commit];
        [updates removeAllStatements];
      }
    } else {
      [_database beginImmediateTransaction];
      for (SQLUpdateBlock *update in updates){
        NSInteger result = [_database executeUpdate:update.statement.newStatement withParameters:update.statement.parameters];
        [results addObject:@(result)];
        update.statement.GUID = nil;
        if (update.block){
          dispatch_async(_operationsQueue, ^{
            update.block(result);
          });
        }
      }
      [_database commit];
      [updates removeAllStatements];
    }
  });
  return results;
}

- (void) updateOrCreateTableToColumnsInStatement:(SQLStatement *)statement{
  NSString *tableName = statement.tableName;
  if (!tableName) return;
  
  NSArray *results = [self runSynchronousQuery:[SQLStatement getAllTables]];
  
  BOOL tableExists = ({
    BOOL tableFound = NO;
    for (id table in results){
      NSString *tName = [table isKindOfClass:[NSString class]] ? table :
      [table isKindOfClass:[NSDictionary class]] ? table[@"name"] : nil;
      if ([tName isEqualToString:tableName]){
        tableFound = YES;
        break;
      }
    }
    tableFound;
  });
  
  if (tableExists){
    statement.tableInfo = YES;
    NSArray *tableResults = [self runSynchronousQuery:statement];
    BOOL found = NO;
    NSMutableArray *results = [NSMutableArray arrayWithArray:tableResults];
    SQLUpdateQueue *updates = [SQLUpdateQueue new];
    for (SQLColumn *column in statement.columns) if (![column.name isEqualToString:@"*"]){
      for (NSDictionary *dict in results) if ([column.name isEqualToString:[dict objectForKey:@"name"]]){
        [results removeObject:dict];
        found = YES;
        break;
      }
      if (found == NO){
        SQLStatement *addColumn = [[SQLStatement alloc] initWithType:SQLStatementAddColumn forTable:statement.tableName];
        [addColumn addSQLColumn:column];
        [updates addSQLUpdate:addColumn withBlock:nil];
      }
      found = NO;
    }
    if (updates.count){
      [self runSynchronousUpdateQueue:updates];
    }
    statement.tableInfo = NO;
  } else {
    SQLStatement *createStatement = [statement copy];
    createStatement.SQLType = SQLStatementCreate;
    [self runSynchronousUpdate:createStatement];
  }
}
- (void) updateOrCreateTableToColumnsInStatement:(SQLStatement *)statement onCompletion:(CompletionBlock)completionBlock{
  NSString *tableName = statement.tableName;
  if (!tableName) return;
  
  [self runImmediateQuery:[SQLStatement getAllTables] withBlock:^(NSArray *results) {
    BOOL tableExists = ({
      BOOL tableFound = NO;
      for (id table in results){
        NSString *tName = [table isKindOfClass:[NSString class]] ? table :
        [table isKindOfClass:[NSDictionary class]] ? table[@"name"] : nil;
        if ([tName isEqualToString:tableName]){
          tableFound = YES;
          break;
        }
      }
      tableFound;
    });
    
    if (tableExists){
      statement.tableInfo = YES;
      [self runImmediateQuery:statement withBlock:^(NSArray *tableResults){
        BOOL found = NO;
        NSMutableArray *results = [NSMutableArray arrayWithArray:tableResults];
        SQLUpdateQueue *updates = [SQLUpdateQueue new];
        for (SQLColumn *column in statement.columns) if (![column.name isEqualToString:@"*"]){
          for (NSDictionary *dict in results) if ([column.name isEqualToString:[dict objectForKey:@"name"]]){
            [results removeObject:dict];
            found = YES;
            break;
          }
          if (found == NO){
            SQLStatement *addColumn = [[SQLStatement alloc] initWithType:SQLStatementAddColumn forTable:statement.tableName];
            [addColumn addSQLColumn:column];
            [updates addSQLUpdate:addColumn withBlock:nil];
          }
          found = NO;
        }
        if (updates.count){
          [self runUpdateQueue:updates withCompletionBlock:^(BOOL success) {
            if (completionBlock) completionBlock();
          }];
        } else {
          if (completionBlock) completionBlock();
        }
        statement.tableInfo = NO;
      }];
    } else {
      SQLStatement *createStatement = [statement copy];
      createStatement.SQLType = SQLStatementCreate;
      [self runImmediateUpdate:createStatement withBlock:^(NSInteger result) {
        if (completionBlock) completionBlock();
      }];
    }
  }];
}
- (void) updateTableToColumnsInStatement:(SQLStatement *)statement onCompletion:(CompletionBlock)completionBlock{
  statement.tableInfo = YES;
  [self runImmediateQuery:statement withBlock:^(NSArray *tableResults){
    BOOL found = NO;
    NSMutableArray *results = [NSMutableArray arrayWithArray:tableResults];
    SQLUpdateQueue *updates = [SQLUpdateQueue new];
    for (SQLColumn *column in statement.columns) if (![column.name isEqualToString:@"*"]){
      for (NSDictionary *dict in results) if ([column.name isEqualToString:[dict objectForKey:@"name"]]){
        [results removeObject:dict];
        found = YES;
        break;
      }
      if (found == NO){
        SQLStatement *addColumn = [[SQLStatement alloc] initWithType:SQLStatementAddColumn forTable:statement.tableName];
        [addColumn addSQLColumn:column];
        [updates addSQLUpdate:addColumn withBlock:nil];
      }
      found = NO;
    }
    if (updates.count){
      [self runUpdateQueue:updates withCompletionBlock:^(BOOL success) {
        if (completionBlock) completionBlock();
      }];
    } else {
      if (completionBlock) completionBlock();
    }
    statement.tableInfo = NO;
  }];
}
- (void) updateTableToColumnsInStatement:(SQLStatement *)statement usingQueryQueue:(SQLQueryQueue *)queryQueue andUpdateQueue:(SQLUpdateQueue *)updateQueue{
  if (!queryQueue || ! updateQueue) return;
  statement = [statement copy];
  statement.tableInfo = YES;
  
  [queryQueue addSQLQuery:statement withBlock:^(NSArray *tableResults) {
    BOOL found = NO;
    NSMutableArray *results = [NSMutableArray arrayWithArray:tableResults];
    SQLStatement *addColumn;
    for (SQLColumn *column in statement.columns) if (![column.name isEqualToString:@"*"]){
      for (NSDictionary *dict in results) if ([column.name isEqualToString:[dict objectForKey:@"name"]]){
        [results removeObject:dict];
        found = YES;
        break;
      }
      if (found == NO){
        addColumn = [[SQLStatement alloc] initWithType:SQLStatementAddColumn forTable:statement.tableName];
        [addColumn addSQLColumn:column];
        [updateQueue addSQLUpdate:addColumn withBlock:nil];
      }
      found = NO;
    }
  }];
}
#pragma mark - Manager Store
- (void) setManager:(id)manager{
  if (!manager) return;
  NSString *key = NSStringFromClass([manager class]);
  _managers[key] = manager;
}
- (id) getManagerForClass:(Class)class{
  return _managers[NSStringFromClass(class)];
}
#pragma mark - Overridden Methods
- (void) dealloc{
  if (self.databaseOpen){
    [self closeDatabase];
  }
  if (_databaseQueue){
    dispatch_release(_databaseQueue);
    _databaseQueue = nil;
  }
}
@end


@implementation SQLUpdateQueue{
@private
  NSMutableArray *_blocks;
  NSUInteger _sqlConflict;
  bool _conformConflict;
}
#pragma mark - Private Methods
- (void) addUpdateBlock:(SQLUpdateBlock *)block{
  [_blocks addObject:block];
}
#pragma mark - Init Methods
+ (SQLUpdateQueue *) queueWithQueue:(SQLUpdateQueue *)queue{
  if ([queue count] < 1) return nil;
  SQLUpdateQueue *returnedQueue = [[self alloc] init];
  for (int i = 0; i < [queue count]; i++) {
    [returnedQueue addUpdateBlock:[queue updateBlockAtIndex:i]];
  }
  returnedQueue.rollbackOnFail = queue.rollbackOnFail;
  return returnedQueue;
}
- (id) init{
  if((self = [super init])){
    _blocks = [[NSMutableArray alloc] init];
    _sqlConflict = SQLConflictIgnore;
    _conformConflict = NO;
  }
  return self;
}
#pragma mark - Standard Methods
- (void) setSqlConflict:(NSUInteger)newSqlConflict{
  if (_sqlConflict != newSqlConflict){
    if (newSqlConflict > 4) newSqlConflict = SQLConflictIgnore;
    _sqlConflict = newSqlConflict;
  }
}
- (bool) addSQLUpdate:(id <SQLStatementProtocol> )statement withBlock:(ExecBlock)block{
  if (statement && statement.SQLType != SQLStatementQuery){
    [_blocks addObject:[[SQLUpdateBlock alloc] initWithConstructor:statement block:block]];
    return YES;
  }
  return NO;
}
- (NSUInteger) count{
  return [_blocks count];
}
- (SQLUpdateBlock *) updateBlockAtIndex:(NSUInteger)index{
  return _blocks[index];
}
- (void) appendUpdatesFromQueue:(SQLUpdateQueue *)updateQueue{
  [_blocks addObjectsFromArray:updateQueue.blocks];
}
- (void) removeAllStatements{
  [_blocks removeAllObjects];
}
#pragma mark - Protocol Methods
- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len{
  return [_blocks countByEnumeratingWithState:state objects:buffer count:len];
}
@end

@implementation SQLQueryQueue{
@private
  NSMutableArray *_blocks;
}
#pragma mark - Private Methods
- (void) addQueryBlock:(SQLQueryBlock *)block{
  [_blocks addObject:block];
}
#pragma mark - Init Methods
+ (SQLQueryQueue *) queueWithQueue:(SQLQueryQueue *)queue{
  if ([queue count] < 1) return nil;
  SQLQueryQueue *returnedQueue = [[self alloc] init];
  for (int i = 0; i < [queue count]; i++) {
    [returnedQueue addQueryBlock:[queue queryBlockAtIndex:i]];
  }
  return returnedQueue;
}
- (id) init{
  if ((self = [super init])){
    _blocks = [[NSMutableArray alloc] init];
  }
  return self;
}
#pragma mark - Standard Methods
- (bool) addSQLQuery:(id <SQLStatementProtocol> )statement withBlock:(QueueBlock)block{
  return [self addSQLQuery:statement usingRowClass:nil withBlock:block];
}
- (bool) addSQLQuery:(id <SQLStatementProtocol>)statement usingRowClass:(Class)rowClass withBlock:(QueueBlock)block{
  if (block && statement && statement.SQLType == SQLStatementQuery){
    [_blocks addObject:[[SQLQueryBlock alloc] initWithConstructor:statement block:block rowClass:rowClass]];
    return YES;
  }
  return NO;
}
- (NSUInteger) count{
  return [_blocks count];
}
- (SQLQueryBlock *) queryBlockAtIndex:(NSUInteger)index{
  return _blocks[index];
}
- (void) appendQueriesFromQueue:(SQLQueryQueue *)queryQueue{
  [_blocks addObjectsFromArray:queryQueue.blocks];
}
- (void) removeAllStatements{
  [_blocks removeAllObjects];
}
#pragma mark - Protocol Methods
- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len{
  return [_blocks countByEnumeratingWithState:state objects:buffer count:len];
}
@end