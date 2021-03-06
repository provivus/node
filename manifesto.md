# Node Manifesto

Node is a data encapsulation enum that facilities transformations from one type to another in Swift. 

## Reasoning

If you are working in an environment that requires converting between data types, especially where those conversions may required intermediate types, Node will be invaluable. Working on the web, for instance, commonly requires conversions from formats like JSON or XML to database formats like MySQL or Mongo. Instead of creating explicit conversions for each permutation of your supported types, you just conform each data type to Node once. Any type that conforms to Node's protocols can be converted to any other type that also conforms. Visually, this looks like:

### Without Node

```
XML --> MySQL
Form --> MySQL
MySQL --> JSON
XML --> Mongo
Form --> Mongo
Mongo --> JSON
```

Six conformances conversions required for six conversion use cases.

### With Node

```
    ---              ---
XML    |            |    XML
JSON   |            |   JSON
Form    > - Node - <    Form
MySQL  |            |  MySQL
Mongo  |            |  Mongo
    ---              ---
```

Five conversions required for 25 conversion use cases.

## Usage

In this simple example, you can see one conformance to `NodeConvertible` for the class `Log` provides compatibility with the MySQL database and JSON REST API.

```swift
final class Log: Model {
    let message: String

    // MARK: NodeConvertible

    init(node: Node, in context: Context) throws {
        message = try node.get("message")
    }

    func makeNode(in context: Context) throws {
        var node = Node()
        try node.set("message", message)
        return node
    }
}

let log = try Log.find(1)
let json = try log.makeJSON()
```

### Advanced

In cases where the serialization or parsing for a given conformance varies, Node is still a powerful tool.

In the following example, the User conforms manually to the `RowConvertible` and `JSONConvertible` types. 
However, since both `Row` and `JSON` are `NodeConvertible` types, Node conveniences of `.get` and `.set` are available.

```swift
final class User: Model {
    let name: Name
    let age: Int
    let organizationId: Node

    var organization: Parent<User, Organization> {
        return parent(id: organizationId)
    }

    init(row: Row) throws {
        name = try row.get() // uses whole node to init Name
        age = try row.get("age") // converts row to Int
        organizationId = try row.get(Organization.foreignIdKey) // converts row to ID
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(name) // merges Name row into current row
        try row.set("age", age) // converts Int to Row
        try row.set(Organization.foreignIdKey, organizationId) // converts ID to Row
        return row
    }
}

// MARK: JSON

extension User: JSONConvertible {
    init(json: JSON) throws {
        name = try json.get("name") // uses Node at key `"name"` to init Name with json init
        age = try json.get("age") // converts JSON to Int
        organizationId = try json.get("organization.id") // converts JSON to Id
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", id) // converts ID to JSON
        try json.set("name", name) // calls `makeJSON` on name and sets to key `"name"`
        try json.set("age", age) // converts Int to JSON
        try json.set("organization", organization) // automatically calls `.get()` and converts organization to JSON
        return json
    }
}
```

### Custom Types

Users can declare their own `NodeConvertible` types to take advantage of the `Initializable` + `Representable` = `Convertible` pattern.

```swift
struct InternalFormat {
    // proprietary stuff here
}

extension InternalFormat: NodeConvertible {
   // only need to conform once 
}
```

```swift
protocol InternalFormatInitializable { 
    init(internalFormat: InternalFormat) throws
}

protocol InternalFormatRepresentable { 
    func makeInternalFormat() throws -> InternalFormat
}

protocol InternalFormatConvertible: InternalFormatInitializable, InternalFormatRepresentable { }
```

```swift
extension User: InternalFormatConvertible {
    init(internalFormat: InternalFormat) throws {
        name = try internalFormat.get("name") // calls `Name.init(internalFormat: ...)` if exists, or `Name.init(..., context: InternalFormatContext())`
        age = try internalFormat.get("age") // automatically converts InternalFormat to Int
        organizationId = try internalFormat.get("orgId") // automatically converts InternalFormat to ID
    }
    
    func makeInternalFormat() throws -> InternalFormat {
        let i = InternalFormat()
        try i.set("name", name) // calls `Name.makeInternalFormat()` if exists, or `Name.makeNode(in: InternalFormatContext())`
        try i.set("age", age) // automatically converts Int to InternalFormat
        try i.set("orgId", organizationId) // automatically converts ID to InternalFormat
        return i
    }
}
```
