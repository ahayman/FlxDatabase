//
//  SQLStatementConstructor.m
//  FlxDatabase
//
//  Created by Aaron Hayman on 9/4/14.
//  Copyright (c) 2014 Aaron Hayman. All rights reserved.
//

#import "SQLStatementConstructor.h"
#import "SQLStatement.h"
#import <objc/runtime.h>

@interface SQLPropertyObject : NSObject
@property (nonatomic) SQLColumnType propertyColumn;
@property (nonatomic) NSString *propertyName;
@end
@implementation SQLPropertyObject
@end

@implementation SQLStatementConstructor
#pragma mark - Private
+ (SQLPropertyObject *) propertyObjectFromProperty:(objc_property_t)property{
  
  const char *attribute = property_getAttributes(property);
  //The attributes must start with 'T', or else something is wrong.
  unsigned long attributeLen = strlen(attribute);
  if (attribute[0] != 'T') return nil;
  SQLPropertyObject *propertyObj = [SQLPropertyObject new];
  
  switch (attribute[1]) {
    case 'd':
    case 'f':
      propertyObj.propertyColumn = SQLColumnTypeReal;
      break;
    case 'i':
    case 'q':
    case 'Q':
    case 'l':
    case 'L':
    case 'I':
    case 'B':
    case 's':
    case 'S':
      propertyObj.propertyColumn = SQLColumnTypeInt;
      break;
    case '@':
      if (attribute[2] == '"'){
        unsigned long classNameLen = 3;
        //Get the class name length by finding the closing quote
        while (attribute[classNameLen] != '"' && classNameLen < attributeLen){
          classNameLen++;
        };
        //We only need the length
        classNameLen -= 3;
        //Copy the class name
        char *className = malloc(sizeof(classNameLen));
        strncpy(className, &attribute[3], classNameLen);
        Class propertyClass = NSClassFromString([[NSString alloc] initWithBytes:className length:classNameLen encoding:NSUTF8StringEncoding]);
        
        //Find out if we can use this class type
        if ([propertyClass isSubclassOfClass:[NSString class]]){
          propertyObj.propertyColumn = SQLColumnTypeText;
        } else if ([propertyClass isSubclassOfClass:[NSNumber class]]){
          propertyObj.propertyColumn = SQLColumnTypeReal;
        } else if ([propertyClass isSubclassOfClass:[NSData class]]){
          propertyObj.propertyColumn = SQLColumnTypeBlob;
        } else {
          //We don't recognize the class, so we can't use the property
          propertyObj = nil;
        }
        
        free(className);
        
      } else {
        propertyObj.propertyColumn = SQLColumnTypeNone;
      }
      break;
    default:
      propertyObj = nil;
      break;
  }
  
  
  if (propertyObj){
    const char *propertyName = property_getName(property);
    propertyObj.propertyName = [[NSString alloc] initWithBytes:propertyName length:strlen(propertyName) encoding:NSUTF8StringEncoding];
  }
  
  if (!propertyObj.propertyName) return nil;
  
  return propertyObj;
}
+ (NSString *) tableNameFromProtocol:(Protocol *)proto{
  if (!proto) return nil;
  const char *protoName = protocol_getName(proto);
  return [[NSString alloc] initWithBytes:protoName length:strlen(protoName) encoding:NSUTF8StringEncoding];
}
#pragma mark - Desginated Constructor
+ (SQLStatement *) constructStatement:(SQLStatementType)statementType fromProtocol:(Protocol *)proto usingTableName:(NSString *)tableName usingValuesFromObject:(id)valueObject{
  if (!proto) return nil;
  if (!tableName){
    tableName = [self tableNameFromProtocol:proto];
  }
  
  //Construct the properties
  NSArray *protocolProperties = ({
    unsigned int propertyCount;
    objc_property_t *properties = protocol_copyPropertyList(proto, &propertyCount);
    NSMutableArray *propertyObjects = [NSMutableArray new];
    for (unsigned int i = 0; i < propertyCount; i++){
      SQLPropertyObject *propertyObject = [self propertyObjectFromProperty:properties[i]];
      if (propertyObject){
        [propertyObjects addObject:propertyObject];
      }
    }
    
    free(properties);
    propertyObjects;
  });
  
  return ({
    BOOL appendValues = (valueObject != nil && (statementType == SQLStatementInsert || statementType == SQLStatementUpdate));
    SQLStatement *statement = [SQLStatement statementType:statementType forTable:tableName];
    if (protocol_conformsToProtocol(proto, @protocol(SQLStatementObject))){
      [statement addDefaultColumns];
    }
    for (SQLPropertyObject *prop in protocolProperties){
        [statement addColumn:prop.propertyName ofColumnType:prop.propertyColumn].value = (appendValues) ? [valueObject valueForKey:prop.propertyName] : nil;
    }
    statement;
  });
  
}
#pragma mark - Convenience Constructors
+ (SQLStatement *) constructStatement:(SQLStatementType)statementType fromProtocol:(Protocol *)proto{
  return [SQLStatementConstructor constructStatement:statementType fromProtocol:proto usingTableName:[SQLStatementConstructor tableNameFromProtocol:proto]];
}
+ (SQLStatement *) constructStatement:(SQLStatementType)statementType fromProtocol:(Protocol *)proto usingTableName:(NSString *)tableName{
  return [self constructStatement:statementType fromProtocol:proto usingTableName:tableName usingValuesFromObject:nil];
}
+ (SQLStatement *) constructUpdateStatementFromObject:(id)object usingProtocol:(Protocol *)proto{
  return [self constructStatement:SQLStatementUpdate fromProtocol:proto usingTableName:nil usingValuesFromObject:object];
}
+ (SQLStatement *) constructUpdateStatementFromObject:(id)object usingProtocol:(Protocol *)proto tableName:(NSString *)tableName{
  return [self constructStatement:SQLStatementUpdate fromProtocol:proto usingTableName:tableName usingValuesFromObject:object];
}
+ (SQLStatement *) constructInsertStatementFromObject:(id)object usingProtocol:(Protocol *)proto{
  return [self constructStatement:SQLStatementInsert fromProtocol:proto usingTableName:nil usingValuesFromObject:object];
}
+ (SQLStatement *) constructInsertStatementFromObject:(id)object usingProtocol:(Protocol *)proto tableName:(NSString *)tableName{
  return [self constructStatement:SQLStatementInsert fromProtocol:proto usingTableName:tableName usingValuesFromObject:object];
}
@end
