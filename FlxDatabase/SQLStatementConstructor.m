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
      if (attributeLen > 3 && attribute[2] == '"'){
        NSString *attributeString = [[NSString alloc] initWithBytes:&attribute[3] length:attributeLen - 3 encoding:NSUTF8StringEncoding];
        NSUInteger endIndex = [attributeString rangeOfString:@"\""].location;
        attributeString = [attributeString substringToIndex:endIndex];
        
        Class propertyClass = NSClassFromString(attributeString);
        
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
  return NSStringFromProtocol(proto);
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
  return [self constructUpdateStatementFromObject:object usingProtocol:proto onKey:GUIDKey tableName:[self tableNameFromProtocol:proto]];
}
+ (SQLStatement *) constructUpdateStatementFromObject:(id)object usingProtocol:(Protocol *)proto tableName:(NSString *)tableName{
  return [self constructUpdateStatementFromObject:object usingProtocol:proto onKey:GUIDKey tableName:tableName];
}
+ (SQLStatement *) constructUpdateStatementFromObject:(id)object usingProtocol:(Protocol *)proto onKey:(NSString *)key tableName:(NSString *)tableName{
  if (!object) return nil;
  if (!key) key = GUIDKey;
  if (![object respondsToSelector:NSSelectorFromString(key)]) return nil;
  id value = [object valueForKey:key];
  if (!value) return nil;
  
  SQLStatement *statement = [self constructStatement:SQLStatementUpdate fromProtocol:proto usingTableName:tableName usingValuesFromObject:object];
  [statement addPredicate:value forColumn:key];
  
  return statement;
}
+ (SQLStatement *) constructInsertStatementFromObject:(id)object usingProtocol:(Protocol *)proto{
  return [self constructInsertStatementFromObject:object usingProtocol:proto tableName:nil];
}
+ (SQLStatement *) constructInsertStatementFromObject:(id)object usingProtocol:(Protocol *)proto tableName:(NSString *)tableName{
  SQLStatement *statement = [self constructStatement:SQLStatementInsert fromProtocol:proto usingTableName:tableName usingValuesFromObject:object];
  NSString *GUID = nil;
  if ([object respondsToSelector:@selector(GUID)] && (GUID = [object GUID])){
    statement.GUID = GUID;
  }
  return statement;
}
+ (SQLStatement *) constructDeleteStatementFromObject:(id)object usingProtocol:(Protocol *)proto{
  return [self constructDeleteStatementFromObject:object onKey:GUIDKey usingProtocol:proto tableName:nil];
}
+ (SQLStatement *) constructDeleteStatementFromObject:(id)object usingProtocol:(Protocol *)proto onKey:(NSString *)key{
  return [self constructDeleteStatementFromObject:object onKey:key usingProtocol:proto tableName:nil];
}
+ (SQLStatement *) constructDeleteStatementFromObject:(id)object onKey:(NSString *)key usingProtocol:(Protocol *)proto tableName:(NSString *)tableName{
  if (!tableName && !proto) return nil;
  if (!tableName) tableName = [self tableNameFromProtocol:proto];
  if (!object) return nil;
  if (!key) key = GUIDKey;
  if (![object respondsToSelector:NSSelectorFromString(key)]) return nil;
  id value = [object valueForKey:key];
  if (!value) return nil;
  
  SQLStatement *statement = [SQLStatement statementType:SQLStatementDelete forTable:tableName];
  [statement addPredicate:value forColumn:key];
  return statement;
}
@end
