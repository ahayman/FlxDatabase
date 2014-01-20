//
//  SQLPredicate.h
//  iDB
//
//  Created by Aaron Hayman on 9/14/12.
//
//

#import <Foundation/Foundation.h>
#import "SQLColumn.h"

typedef NS_ENUM(NSUInteger, SQLOperator){
    SQLLike,
    SQLNotLike,
    SQLEquals,
    SQLGreaterThan,
    SQLLessThan,
    SQLGreaterThanOrEqualTo,
    SQLLessThanOrEqualTo,
    SQLNotEqualTo
};

typedef NS_ENUM(NSUInteger, SQLConnect){
    SQLConnectAnd,
    SQLConnectOr
};
/**
 *  The SQLPredicate is designed to hold the information for one predicate value in a SQL statement.  For example:
 *      WHERE name = "<name>" OR age = <age>
 *
 *  A SQLPredicate contains four values: the column name, the predicate value, the operator and a connect value.  You can simply add predicates to a SQLStatement or you can add predicates to a SQLPredicateGroup (which is added to the statement or another group) which will group together predicates in a set of parenthesis to control precidence. Predicates are parameratized by the SQLStatement.
 */
@interface SQLPredicate : NSObject <NSCopying>
/**
 *  Name of the column.  Yes, it's required for the predicate to work.
 */
@property (copy) NSString *column;
/**
 *  The value by which the predicate is analyzed. If this value is `nil`, the predicate will be analyzed as NULL.
 */
@property (copy) id value;
/**
 *  The predicate operator is how the predicate value is analyzed against the row values. Default: SQLEquals
 *
 *  SQLStatement will add additional predicates if you use any Less than predicate type. By default, SQLite does not include NULL in less than equalities.  If you use a less than equality, SQLStatement will add an aditional equality equal to NULL to include NULL values in the equality. At the moment, this is the preferred behavior (by me), but I may be convinced to add an option to disable this in the future.
 */
@property SQLOperator op;
/**
 *  Connect defines how this predicate is logically "connected" to the previous predicate as part of SQL statement. Your options are: `SQLConnectAnd`, `SQLConnectOr`. This will connect this predicate with the previous predicate using "AND" and "OR", respectively.  Default: SQLConnectAnd.
 *
 *  It should be noted that this property has no effect on the first predicate in a statement.
 *  
 *  In SQLite, the AND operator has precidence over the OR operator.  This can get a little confusing if you are mixing AND/OR operators in a statement.  Instead. consider using the SQLPredicateGroup, which will surround it's contained predicates with a parenthesis, thus controlling precidence.  Since a predicate group can contain predicate groups, you have full control over precidence in an object oriented fashion, which can be very helpful for procedurally generated statements.
 */
@property SQLConnect connect;
/**
 *  This returns the connect string to be used in the SQLStatement for this predicate.
 */
@property (readonly) NSString *connectString;
/**
 *  This returns the operator string to be used in the SQLStatement for this predicate.
 */
@property (readonly) NSString *operatorString;
/**
 *  Convenience init with relevant properties.
 *
 *  @param column  The name of the table column to be searched.
 *  @param value   The value of the predicate.
 *  @param op      The operator by which to judge row values against the predicate value.
 *  @param connect How to connect this predicate with the previous predicate (if any).
 *
 *  @return SQLPredicate
 */
- (id) initWithColumn:(NSString *)column value:(id)value operator:(SQLOperator)op connection:(SQLConnect)connect;
@end

/**
 *  The SQLPredicateGroup allow you to group predicates and other groups together to control how SQLite evalutes the predicate (WHERE) statement. A group will surround all it's contents with parenthesis in the statement. You can add other groups to a SQLPredicateGroup, which give you fine grain control over how your `WHERE` statement is evaluated.
 */
@interface SQLPredicateGroup : NSObject <NSCopying>
/**
 *  This will return a deep copy of all the predicates contained by this group.
 */
@property (copy) NSArray *predicates;
/**
 *  Connect defines how this predicate group is logically "connected" to the previous predicate or group as part of SQL statement. Your options are: `SQLConnectAnd`, `SQLConnectOr`. This will connect this predicate with the previous predicate using "AND" and "OR", respectively.  Default: SQLConnectAnd.
 */
@property SQLConnect connect;
/**
 *  This returns the connect string to be used in the SQLStatement for this predicate.
 */
@property (readonly) NSString *connectString;
/**
 *  Convenience init with a connect and a set of predicates.
 *
 *  @param connect    SQLConnect<And>/<Or> defines how this group is connected with the previous predicate/group in the statement.
 *  @param predicates An array that contains only SQLPredicate or SQLPredicateGroup items.
 *
 *  @return SQLPredicateGroup
 */
- (id) initWithConnection:(SQLConnect)connect predicates:(NSArray *)predicates;
/**
 *  This will add a predicate to the group.
 *
 *  @param predicate SQLPredicate you want to add.
 */
- (void) addPredicate:(SQLPredicate *)predicate;
/**
 *  This will remove the specified predicate from the group.
 *
 *  @param predicate The SQLPredicate you wish to remove from the group.
 */
- (void) removePredicate:(SQLPredicate *)predicate;
/**
 *  This will remove all predicates and groups from the this group, essentially making it empty.
 */
- (void) removeAllPredicates;
/**
 *  This will add the specified predicate group to this group.
 *
 *  @param group The SQLPredicateGroup you wish to add.
 */
- (void) addGroup:(SQLPredicateGroup *)group;
/**
 *  This will remove the specified predicate group from this group if it's contained by this group.
 *
 *  @param group The SQLPredicateGroup you wish to remove.
 */
- (void) removeGroup:(SQLPredicateGroup *)group;
@end
