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
  
  column = statement.columns[@"GUID"];
  XCTAssertEqualObjects(@"GUID", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  
  column = statement.columns[@"SQLCreatedDateTime"];
  XCTAssertEqualObjects(@"SQLCreatedDateTime", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[@"SQLModifiedDateTime"];
  XCTAssertEqualObjects(@"SQLModifiedDateTime", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[@"testInt"];
  XCTAssertEqualObjects(@"testInt", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testDouble"];
  XCTAssertEqualObjects(@"testDouble", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[@"testFloat"];
  XCTAssertEqualObjects(@"testFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[@"testLongLong"];
  XCTAssertEqualObjects(@"testLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testNSNumber"];
  XCTAssertEqualObjects(@"testNSNumber", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  
  column = statement.columns[@"testString"];
  XCTAssertEqualObjects(@"testString", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  
  column = statement.columns[@"testData"];
  XCTAssertEqualObjects(@"testData", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  
  column = statement.columns[@"testBool"];
  XCTAssertEqualObjects(@"testBool", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testUnsignedLong"];
  XCTAssertEqualObjects(@"testUnsignedLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testUnsignedLongLong"];
  XCTAssertEqualObjects(@"testUnsignedLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testShort"];
  XCTAssertEqualObjects(@"testShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testLong"];
  XCTAssertEqualObjects(@"testLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  
  column = statement.columns[@"testUnsignedShort"];
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
    object.GUID = @"TestObjectID";
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
  
  column = statement.columns[@"testInt"];
  XCTAssertEqualObjects(@"testInt", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1, @"Check the column value is correct.");
  
  column = statement.columns[@"testDouble"];
  XCTAssertEqualObjects(@"testDouble", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.05, @"Check the column value is correct.");
  
  column = statement.columns[@"testFloat"];
  XCTAssertEqualObjects(@"testFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.045f, @"Check the column value is correct.");
  
  column = statement.columns[@"testLongLong"];
  XCTAssertEqualObjects(@"testLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @52, @"Check the column value is correct.");
  
  column = statement.columns[@"testNSNumber"];
  XCTAssertEqualObjects(@"testNSNumber", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @42, @"Check the column value is correct.");
  
  column = statement.columns[@"testString"];
  XCTAssertEqualObjects(@"testString", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @"Test String", @"Check the column value is correct.");
  
  column = statement.columns[@"testData"];
  XCTAssertEqualObjects(@"testData", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  XCTAssertEqual(column.value, testData, @"Check the column value is correct.");
  
  column = statement.columns[@"testBool"];
  XCTAssertEqualObjects(@"testBool", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqual(column.value, @YES, @"Check the column value is correct.");
  
  column = statement.columns[@"testUnsignedLong"];
  XCTAssertEqualObjects(@"testUnsignedLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @38, @"Check the column value is correct.");
  
  column = statement.columns[@"testUnsignedLongLong"];
  XCTAssertEqualObjects(@"testUnsignedLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1092, @"Check the column value is correct.");
  
  column = statement.columns[@"testShort"];
  XCTAssertEqualObjects(@"testShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @29, @"Check the column value is correct.");
  
  column = statement.columns[@"testLong"];
  XCTAssertEqualObjects(@"testLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @123, @"Check the column value is correct.");
  
  column = statement.columns[@"testUnsignedShort"];
  XCTAssertEqualObjects(@"testUnsignedShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @23, @"Check the column value is correct.");
}
- (void) testInsert{
  NSData *testData = [[NSData alloc] init];
  TestProtocolClass *testObject = ({
    TestProtocolClass *object = [TestProtocolClass new];
    object.GUID = @"TestObjectID";
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
  
  column = statement.columns[@"testInt"];
  XCTAssertEqualObjects(@"testInt", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1, @"Check the column value is correct.");
  
  column = statement.columns[@"testDouble"];
  XCTAssertEqualObjects(@"testDouble", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.05, @"Check the column value is correct.");
  
  column = statement.columns[@"testFloat"];
  XCTAssertEqualObjects(@"testFloat", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1.045f, @"Check the column value is correct.");
  
  column = statement.columns[@"testLongLong"];
  XCTAssertEqualObjects(@"testLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @52, @"Check the column value is correct.");
  
  column = statement.columns[@"testNSNumber"];
  XCTAssertEqualObjects(@"testNSNumber", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeReal, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @42, @"Check the column value is correct.");
  
  column = statement.columns[@"testString"];
  XCTAssertEqualObjects(@"testString", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeText, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @"Test String", @"Check the column value is correct.");
  
  column = statement.columns[@"testData"];
  XCTAssertEqualObjects(@"testData", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeBlob, @"Check Column Type");
  XCTAssertEqual(column.value, testData, @"Check the column value is correct.");
  
  column = statement.columns[@"testBool"];
  XCTAssertEqualObjects(@"testBool", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqual(column.value, @YES, @"Check the column value is correct.");
  
  column = statement.columns[@"testUnsignedLong"];
  XCTAssertEqualObjects(@"testUnsignedLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @38, @"Check the column value is correct.");
  
  column = statement.columns[@"testUnsignedLongLong"];
  XCTAssertEqualObjects(@"testUnsignedLongLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @1092, @"Check the column value is correct.");
  
  column = statement.columns[@"testShort"];
  XCTAssertEqualObjects(@"testShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @29, @"Check the column value is correct.");
  
  column = statement.columns[@"testLong"];
  XCTAssertEqualObjects(@"testLong", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @123, @"Check the column value is correct.");
  
  column = statement.columns[@"testUnsignedShort"];
  XCTAssertEqualObjects(@"testUnsignedShort", column.name, @"Check Column Name");
  XCTAssertEqual(column.type, SQLColumnTypeInt, @"Check Column Type");
  XCTAssertEqualObjects(column.value, @23, @"Check the column value is correct.");
}
@end
