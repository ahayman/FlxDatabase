//
//  SQLStatementConstructor.h
//  FlxDatabase
//
//  Created by Aaron Hayman on 9/4/14.
//  Copyright (c) 2014 Aaron Hayman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQLStatementProtocol.h"
@class SQLStatement;

@interface SQLStatementConstructor : NSObject
/* ***** Actual Constructor **** */
+ (SQLStatement *) constructStatement:(SQLStatementType)statementType fromProtocol:(Protocol *)proto usingTableName:(NSString *)tableName usingValuesFromObject:(id)valueObject;

/* ***** Convenience Constructors ****** */
+ (SQLStatement *) constructStatement:(SQLStatementType)statementType fromProtocol:(Protocol *)proto;
+ (SQLStatement *) constructStatement:(SQLStatementType)statementType fromProtocol:(Protocol *)proto usingTableName:(NSString *)tableName;
+ (SQLStatement *) constructUpdateStatementFromObject:(id)object usingProtocol:(Protocol *)proto;
+ (SQLStatement *) constructUpdateStatementFromObject:(id)object usingProtocol:(Protocol *)proto tableName:(NSString *)tableName;
+ (SQLStatement *) constructInsertStatementFromObject:(id)object usingProtocol:(Protocol *)proto;
+ (SQLStatement *) constructInsertStatementFromObject:(id)object usingProtocol:(Protocol *)proto tableName:(NSString *)tableName;
@end
