# Flexile Database

The Flexile Database is a set of classes to help manage information in a SQLite database (iPhone only at the moment) in an object oriented fasion. The header files are fully documented, so you can learn a lot about usage there.

The is one dependency: [FlxToolkit](https://github.com/ahayman/FlexileToolkit). It a collection of classes, defines, functions, etc I use in most of my projects.

**Warning:** At the moment, while these classes handle just about all types of updates you can do on a SQLite database, they only handle single-table queries. I intend on adding joined queries in the near future... as soon as I can get to it.

## Structure
There are two main aspects to how this works: `SQLDatabaseManager` and `SQLStatement`. You first construct the SQLStatement by setting it's type and adding to it columns, predicates, orders, etc. You then pass the SQLStatement to the `SQLDatabaseManager`, which will run the SQL statement on the database and return the results either directly or in a block (for asynchronous calls). All SQL statements are run in a background queue and results are normally passed back on the main queue using a return block (which varies depending on whether it's a query or update). SQL statements can be submitted synchronously, but generally it's preferred to keep as many of your queries asynchronous as possible. See the header files for more info.

## Features

1. SQL Statement can be constructed in a full object-oriented manner, allowing you to reuse columns, predicates, statements, etc.  Absolutely no "string splicing" required :).
1. Full support for aggregates, grouping and column aliases.
1. SQLPredicate groups allow you to create and manage complex predicates in a tree-like structure.
1. SQLStatement can be deep copied. This allows you to keep an instance as a template and re-use it.
1. Fully managed database access with both block-based asynchronous queries/updates as well as synchronous access. SQL statements can be grouped together into a queue and processed as a single transaction for efficiency (also with rollback support for updates).
1. Auto-table updating can take a SQL statement and update the underlying table by adding the appropriate columns.
1. Per-file singleton behavior. Only one SQLDatabaseManager can be instantiated per database file, ensuring conflicts don't occur between managers.
1. Table manager registration allows you to register specific classes with the database manager and return only a single instance of the manager, which is useful for ensuring only one instance is instantiated per database manager.
1. Be default, queries return a NSArray of NSMutableDictionary items. However, you can also pass in a row class and receive back a NSArray of any class type you wish (so long as the class responds to the column names as key paths).

## Development
I use this system in my production app, so bug fixes and additional features will be ongoing. If you want a feature or have a suggestion, let me know and I'll see what I can do:

[aaron@flexile.co](mailto:aaron@flexile.co)
