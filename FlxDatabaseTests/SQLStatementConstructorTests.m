//
//  SQLStatementConstructorTests.m
//  FlxDatabase
//
//  Created by Aaron Hayman on 9/4/14.
//  Copyright (c) 2014 Aaron Hayman. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SQLStatementConstructor.h"
#import "SQLStatement.h"

@protocol TestProtocol <NSObject, SQLStatementObject>
@property int testInt;
@property double testDouble;
@property float testFloat;
@property CGFloat testCGFloat;
@property (nonatomic) NSNumber *testNSNumber;
@property (nonatomic) NSString *testString;
@property (nonatomic) NSData *testData;
@property (nonatomic) BOOL testBool;
@end

@interface TestProtocolClass : NSObject <TestProtocol>
@end
@implementation TestProtocolClass
@synthesize GUID, SQLCreatedDateTime, SQLModifiedDateTime;
@synthesize testInt, testDouble, testFloat, testCGFloat, testNSNumber, testString, testData, testBool;
@end

@interface SQLStatementConstructorTests : XCTestCase

@end

@implementation SQLStatementConstructorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testQueryStatement{
  SQLStatement *statement = [SQLStatementConstructor constructStatement:SQLStatementQuery fromProtocol:@protocol(TestProtocol) usingTableName:nil usingValuesFromObject:nil];
  
  XCTAssertEqual(statement.columns.count, 11, @"Check the correct number of columns were created.");
  XCTAssertEqual(statement.SQLType, SQLStatementQuery, @"Check the Statement type is correct.");
  XCTAssertEqualObjects(statement.tableName, @"TestProtocol", @"Check the table name");
  
  SQLColumn *column;
  
  column = statement.columns[0];
  XCTAssertEqualObjects(@"GUID", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  
  column = statement.columns[1];
  XCTAssertEqualObjects(@"SQLCreatedDateTime", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[2];
  XCTAssertEqualObjects(@"SQLModifiedDateTime", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[3];
  XCTAssertEqualObjects(@"testInt", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[4];
  XCTAssertEqualObjects(@"testDouble", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[5];
  XCTAssertEqualObjects(@"testFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[6];
  XCTAssertEqualObjects(@"testCGFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[7];
  XCTAssertEqualObjects(@"testNSNumber", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[8];
  XCTAssertEqualObjects(@"testString", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  
  column = statement.columns[9];
  XCTAssertEqualObjects(@"testData", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  
  column = statement.columns[10];
  XCTAssertEqualObjects(@"testBool", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
}
- (void) testQueryWithCustomTable{
  
  SQLStatement *statement = [SQLStatementConstructor constructStatement:SQLStatementQuery fromProtocol:@protocol(TestProtocol) usingTableName:@"CustomTable" usingValuesFromObject:nil];
  
  XCTAssertEqual(statement.columns.count, 11, @"Check the correct number of columns were created.");
  XCTAssertEqual(statement.SQLType, SQLStatementQuery, @"Check the Statement type is correct.");
  XCTAssertEqualObjects(statement.tableName, @"CustomTable", @"Check the table name");
}
- (void) testUpdate{
  NSData *testData = [[NSData alloc] init];
  TestProtocolClass *testObject = ({
    TestProtocolClass *object = [TestProtocolClass new];
    object.testInt = 1;
    object.testDouble = 1.05;
    object.testFloat = 1.045f;
    object.testCGFloat = 1.098f;
    object.testNSNumber = @42;
    object.testString = @"Test String";
    object.testData = testData;
    object.testBool = YES;
    object;
  });
  
  SQLStatement *statement = [SQLStatementConstructor constructUpdateStatementFromObject:testObject usingProtocol:@protocol(TestProtocol)];
  XCTAssertEqual(statement.columns.count, 11, @"Check the correct number of columns were created.");
  XCTAssertEqual(statement.SQLType, SQLStatementUpdate, @"Check the Statement type is correct.");
  XCTAssertEqualObjects(statement.tableName, @"TestProtocol", @"Check the table name");
  
  SQLColumn *column;
  
  column = statement.columns[3];
  XCTAssertEqualObjects(@"testInt", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1, @"Check the column value is correct.");
  
  column = statement.columns[4];
  XCTAssertEqualObjects(@"testDouble", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.05, @"Check the column value is correct.");
  
  column = statement.columns[5];
  XCTAssertEqualObjects(@"testFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.045f, @"Check the column value is correct.");
  
  column = statement.columns[6];
  XCTAssertEqualObjects(@"testCGFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.098f, @"Check the column value is correct.");
  
  column = statement.columns[7];
  XCTAssertEqualObjects(@"testNSNumber", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @42, @"Check the column value is correct.");
  
  column = statement.columns[8];
  XCTAssertEqualObjects(@"testString", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @"Test String", @"Check the column value is correct.");
  
  column = statement.columns[9];
  XCTAssertEqualObjects(@"testData", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  XCTAssertEqual(column.value, testData, @"Check the column value is correct.");
  
  column = statement.columns[10];
  XCTAssertEqualObjects(@"testBool", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  XCTAssertEqual(column.value, @YES, @"Check the column value is correct.");
}
- (void) testInsert{
  NSData *testData = [[NSData alloc] init];
  TestProtocolClass *testObject = ({
    TestProtocolClass *object = [TestProtocolClass new];
    object.testInt = 1;
    object.testDouble = 1.05;
    object.testFloat = 1.045f;
    object.testCGFloat = 1.098f;
    object.testNSNumber = @42;
    object.testString = @"Test String";
    object.testData = testData;
    object.testBool = YES;
    object;
  });
  
  SQLStatement *statement = [SQLStatementConstructor constructInsertStatementFromObject:testObject usingProtocol:@protocol(TestProtocol)];
  XCTAssertEqual(statement.columns.count, 11, @"Check the correct number of columns were created.");
  XCTAssertEqual(statement.SQLType, SQLStatementInsert, @"Check the Statement type is correct.");
  XCTAssertEqualObjects(statement.tableName, @"TestProtocol", @"Check the table name");
  
  SQLColumn *column;
  
  column = statement.columns[3];
  XCTAssertEqualObjects(@"testInt", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1, @"Check the column value is correct.");
  
  column = statement.columns[4];
  XCTAssertEqualObjects(@"testDouble", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.05, @"Check the column value is correct.");
  
  column = statement.columns[5];
  XCTAssertEqualObjects(@"testFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.045f, @"Check the column value is correct.");
  
  column = statement.columns[6];
  XCTAssertEqualObjects(@"testCGFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.098f, @"Check the column value is correct.");
  
  column = statement.columns[7];
  XCTAssertEqualObjects(@"testNSNumber", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @42, @"Check the column value is correct.");
  
  column = statement.columns[8];
  XCTAssertEqualObjects(@"testString", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @"Test String", @"Check the column value is correct.");
  
  column = statement.columns[9];
  XCTAssertEqualObjects(@"testData", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  XCTAssertEqual(column.value, testData, @"Check the column value is correct.");
  
  column = statement.columns[10];
  XCTAssertEqualObjects(@"testBool", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  XCTAssertEqual(column.value, @YES, @"Check the column value is correct.");
}
@end
