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

#define ColumnCount 16

@protocol TestProtocol <NSObject, SQLStatementObject>
@property int testInt;
@property double testDouble;
@property float testFloat;
@property long long testLongLong;
@property (nonatomic) NSNumber *testNSNumber;
@property (nonatomic) NSString *testString;
@property (nonatomic) NSData *testData;
@property (nonatomic) BOOL testBool;
@property unsigned long testUnsignedLong;
@property unsigned long long testUnsignedLongLong;
@property short testShort;
@property long testLong;
@property unsigned short testUnsignedShort;
@end

@interface TestProtocolClass : NSObject <TestProtocol>
@end
@implementation TestProtocolClass
@synthesize GUID, SQLCreatedDateTime, SQLModifiedDateTime;
@synthesize testInt, testDouble, testFloat, testLongLong, testNSNumber, testString, testData, testBool, testShort, testUnsignedLong, testUnsignedLongLong, testLong, testUnsignedShort;
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
  
  XCTAssertEqual(statement.columns.count, ColumnCount, @"Check the correct number of columns were created.");
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
  XCTAssertEqualObjects(@"testLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
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
  
  column = statement.columns[11];
  XCTAssertEqualObjects(@"testUnsignedLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[12];
  XCTAssertEqualObjects(@"testUnsignedLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[13];
  XCTAssertEqualObjects(@"testShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[14];
  XCTAssertEqualObjects(@"testLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[15];
  XCTAssertEqualObjects(@"testUnsignedShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
}
- (void) testQueryWithCustomTable{
  
  SQLStatement *statement = [SQLStatementConstructor constructStatement:SQLStatementQuery fromProtocol:@protocol(TestProtocol) usingTableName:@"CustomTable" usingValuesFromObject:nil];
  
  XCTAssertEqual(statement.columns.count, ColumnCount, @"Check the correct number of columns were created.");
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
    object.testLongLong = 52;
    object.testNSNumber = @42;
    object.testString = @"Test String";
    object.testData = testData;
    object.testBool = YES;
    object.testUnsignedLong = 38;
    object.testUnsignedLongLong = 1092;
    object.testShort = 29;
    object.testLong = 123;
    object.testUnsignedShort = 23;
    object;
  });
  
  SQLStatement *statement = [SQLStatementConstructor constructUpdateStatementFromObject:testObject usingProtocol:@protocol(TestProtocol)];
  XCTAssertEqual(statement.columns.count, ColumnCount, @"Check the correct number of columns were created.");
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
  XCTAssertEqualObjects(@"testLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @52, @"Check the column value is correct.");
  
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
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqual(column.value, @YES, @"Check the column value is correct.");
  
  column = statement.columns[11];
  XCTAssertEqualObjects(@"testUnsignedLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @38, @"Check the column value is correct.");
  
  column = statement.columns[12];
  XCTAssertEqualObjects(@"testUnsignedLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1092, @"Check the column value is correct.");
  
  column = statement.columns[13];
  XCTAssertEqualObjects(@"testShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @29, @"Check the column value is correct.");
  
  column = statement.columns[14];
  XCTAssertEqualObjects(@"testLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @123, @"Check the column value is correct.");
  
  column = statement.columns[15];
  XCTAssertEqualObjects(@"testUnsignedShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @23, @"Check the column value is correct.");
}
- (void) testInsert{
  NSData *testData = [[NSData alloc] init];
  TestProtocolClass *testObject = ({
    TestProtocolClass *object = [TestProtocolClass new];
    object.testInt = 1;
    object.testDouble = 1.05;
    object.testFloat = 1.045f;
    object.testLongLong = 52;
    object.testNSNumber = @42;
    object.testString = @"Test String";
    object.testData = testData;
    object.testBool = YES;
    object.testUnsignedLong = 38;
    object.testUnsignedLongLong = 1092;
    object.testShort = 29;
    object.testLong = 123;
    object.testUnsignedShort = 23;
    object;
  });
  
  SQLStatement *statement = [SQLStatementConstructor constructInsertStatementFromObject:testObject usingProtocol:@protocol(TestProtocol)];
  XCTAssertEqual(statement.columns.count, ColumnCount, @"Check the correct number of columns were created.");
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
  XCTAssertEqualObjects(@"testLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @52, @"Check the column value is correct.");
  
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
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqual(column.value, @YES, @"Check the column value is correct.");
  
  column = statement.columns[11];
  XCTAssertEqualObjects(@"testUnsignedLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @38, @"Check the column value is correct.");
  
  column = statement.columns[12];
  XCTAssertEqualObjects(@"testUnsignedLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1092, @"Check the column value is correct.");
  
  column = statement.columns[13];
  XCTAssertEqualObjects(@"testShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @29, @"Check the column value is correct.");
  
  column = statement.columns[14];
  XCTAssertEqualObjects(@"testLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @123, @"Check the column value is correct.");
  
  column = statement.columns[15];
  XCTAssertEqualObjects(@"testUnsignedShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @23, @"Check the column value is correct.");
}
@end
