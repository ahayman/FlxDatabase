# Flexile Database

The Flexile Database is a set of classes to help manage information in a SQLite database (iPhone only at the moment) in an object oriented fashion. I use the library primarily in my own app [Flexile](http://flexile.co). The header files are fully documented, so you can learn a lot about usage there.

There is one dependency: [FlexileToolkit](https://github.com/ahayman/FlexileToolkit). It a collection of classes, defines, functions, etc I use in most of my projects.

**Warning:** At the moment, while these classes handle just about all types of updates you can do on a SQLite database, they only handle single-table queries. I intend on adding joined queries in the near future... as soon as I can get to it.

## Features

1. `SQLStatement` can be constructed in a full object-oriented manner, allowing you to reuse columns, predicates, statements, etc.  Absolutely no "string splicing" required :).
1. Full support for aggregates, grouping and column aliases.
1. `SQLPredicate` groups allow you to create and manage complex predicates in a tree-like structure.
1. `SQLStatement` and all its objects can be deep copied. This allows you to keep an instance as a template and re-use it.
1. Flexile Database uses a globally unique identifier system (GUID... as I like to call it). It's a standard 36 char string that's used as the primary key. While it can be argued (successfully) that using a GUID makes lookup less efficient, it also makes the database much more compatible with syncing, merging, etc.
1. Fully managed database access with both block-based asynchronous queries/updates as well as synchronous access. SQL statements can be grouped together into a queue and processed as a single transaction for efficiency (also with rollback support for updates).
1. Auto-table updating can take a `SQLStatement` and update the underlying table by adding the appropriate columns.
1. Per-file singleton behavior. Only one `SQLDatabaseManager` can be instantiated per database file, ensuring conflicts don't occur between managers.
1. Table manager registration allows you to register specific classes with the database manager and return only a single instance of the manager, which is useful for ensuring only one instance is instantiated per database manager.
1. Specialized `SQLStatement` constructors for grabbing database and table meta information.
1. Be default, queries return a `NSArray` of `NSMutableDictionary` items. However, you can also pass in a row class and receive back a `NSArray` of any class type you wish (so long as the class responds to the column names as key paths).
1. Can handle the following data types: `NSString`, `NSNumber`, `NSDate`, `UIImage` and `NSData`.

## Structure
There are two main aspects to how this works: `SQLDatabaseManager` and `SQLStatement`. You first construct the `SQLStatement` by setting it's type and adding to it columns, predicates, orders, etc. You then pass the `SQLStatement` to the `SQLDatabaseManager`, which will run the SQL statement on the database and return the results either directly or in a block (for asynchronous calls). All SQL statements are run in a background queue and results are normally passed back on the main queue using a return block (which varies depending on whether it's a query or update). SQL statements can be submitted synchronously, but generally it's preferred to keep as many of your queries asynchronous as possible. See the header files for more info.

## SQLStatement
The `SQLStatement` is currently the main object that constructs the sql statement and parameters supplied to the `SQLDatabaseManager` for processing. It uses a variety of objects that represent the major portions of a SQL statement. Not all objects (nor their properties) are used in all situations, but those objects that don't apply are simply ignored. This makes it easy to convert a SQL query to and update by simply changing the `SQLStatementType`.

- `SQLColumn`: This represents the basic column in a SQL statement. The `SQLColumn` has a bunch of attributes, many of which apply only in certain types of queries/updates. You'll want to take a look at the header file for more information on how to use this class.
- `SQLOrder`: This represents an ordering of a table column for queries. Doesn't apply to updates.
- `SQLPredicate` & `SQLPredicateGroup`: The `SQLPredicate` represents a single evaluation in a "WHERE" statement. Ex: `name = "Aaron"` or `name LIKE "Hayman"`. There are a variety of operators you can use (less than, greater than, not equal to, equal, etc). The `SQLStatement` also adds additional functionality for the "less than" types by including `NULL` values in those operations. The `SQLPredicateGroup` can be used to group together predicates *and* nest them (a group can contain another group). This gives you full control over how the predicates are evaluated (groups are automatically surrounded by parenthesis in the statement).  It also allows you to organize your predicates in a "modular" fashion.

## SQLDatabase.h/.m
I do not use the FMDB wrapper. To be honest, this wasn't a strategic decision as much as a desire to become a little more intimately associated with SQLite. From what I've seen of the FMDB wrapper, my comparable class `SQLDatabase` is fairly similar. I think I do a few things differently, much of it tailored to work with `SQLDatabaseManager` and probably a bit simpler in functionality, but overall the idea is pretty much the same.

## Ongoing Development
I use this system in my production app [Flexile](http://flexile.co), so bug fixes and additional features will be ongoing. If you want a feature or have a suggestion, let me know and I'll see what I can do:

[aaron@flexile.co](mailto:aaron@flexile.co)

I have several features I've currently got planned. Again, I don't know when I will get to them, but since I use this system daily it probably won't take forever:

1. Multi-table/Joined Queries. This would, I believe, round out the capabilities of the Flexile Database.
1. Create an `SQLStatement` (or perhaps column list) from a `Class`.
1. Also related to the previous: Submit an object to the `FlxDatabaseManager` as an update (it would auto-create the appropriate `SQLStatement`). This would require that submitted objects at least have the property: `@property (strong) NSString *GUID`.
