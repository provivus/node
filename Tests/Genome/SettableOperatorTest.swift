//
//  SettableOperatorTest.swift
//  Genome
//
//  Created by Logan Wright on 9/22/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import XCTest

@testable import Genome

class SettableOperatorTest: XCTestCase {
    
    struct Person: MappableObject, Hashable {
        
        let firstName: String
        let lastName: String
        
        init(firstName: String, lastName: String) {
            self.firstName = firstName
            self.lastName = lastName
        }
        
        init(with map: Map) throws {
            try firstName = map.extract("first_name")
            try lastName = map.extract("last_name")
        }
        
        mutating func sequence(_ map: Map) throws -> Void {
            try firstName ~> map["first_name"]
            try lastName ~> map["last_name"]
        }
        
        var hashValue: Int {
            return firstName.hashValue ^ lastName.hashValue
        }
        
    }
    
    let strings: Node = [
        "one",
        "two",
        "tre"
    ]
    
    let joeObject = Person(firstName: "Joe", lastName: "Fish")
    let joeNode: Node = [
        "first_name" : "Joe",
        "last_name" : "Fish"
    ]
    
    let janeObject = Person(firstName: "Jane", lastName: "Bear")
    let janeNode: Node = [
        "first_name" : "Jane",
        "last_name" : "Bear"
    ]
    
    let justinObject = Person(firstName: "Justin", lastName: "Badger")
    let justinNode: Node = [
        "first_name" : "Justin",
        "last_name" : "Badger"
    ]
    
    let philObject = Person(firstName: "Phil", lastName:"Viper")
    let philNode: Node = [
        "first_name" : "Phil",
        "last_name" : "Viper"
    ]
    
    lazy var node: Node = [
        "int" : 272,
        "strings" : self.strings,
        "person" : self.joeNode,
        "people" : [self.joeNode, self.janeNode],
        "duplicated_people" : [self.joeNode, self.joeNode, self.janeNode],
        "relationships" : [
            "best_friend" : self.philNode,
            "cousin" : self.justinNode
        ],
        "groups" : [
            "boys" : [self.joeNode, self.justinNode, self.philNode],
            "girls" : [self.janeNode]
        ],
        "ordered_groups" : [
            [self.joeNode, self.justinNode, self.philNode],
            [self.janeNode]
        ]
    ]
    
    lazy var map: Map! = Map(node: self.node)
    
    override func tearDown() {
        map = nil
    }
    
    func testBasicTypes() {
        let int: Int = try! map.extract("int")
        XCTAssert(int == 272)
        
        let optionalInt: Int? = try! map.extract("int")
        XCTAssert(optionalInt! == 272)
        
        let strings: [String] = try! map.extract("strings")
        XCTAssert(strings == self.strings.arrayValue!.flatMap { $0.stringValue })
        
        let optionalStrings: [String]? = try! map.extract("strings")
        XCTAssert(optionalStrings! == self.strings.arrayValue!.flatMap { $0.stringValue })
        
        let stringInt: String = try! <~map["int"]
            .transformFromNode { (nodeValue: Int) in
                return "\(nodeValue)"
        }
        XCTAssert(stringInt == "272")
        
        let emptyInt: Int? = try! map.extract("i_dont_exist")
        XCTAssert(emptyInt == nil)
        
        let emptyStrings: [String]? = try! map.extract("i_dont_exist")
        XCTAssert(emptyStrings == nil)
    }
    
    func testMappableObject() {
        let person: Person = try! map.extract("person")
        XCTAssert(person == self.joeObject)
        
        let optionalPerson: Person? = try! map.extract("person")
        XCTAssert(optionalPerson == self.joeObject)
        
        let emptyPerson: Person? = try! map.extract("i_dont_exist")
        XCTAssert(emptyPerson == nil)
    }
    
    func testMappableArray() {
        let people: [Person] = try! map.extract("people")
        XCTAssert(people == [self.joeObject, self.janeObject])
        
        let optionalPeople: [Person]? = try! <~map["people"]
        XCTAssert(optionalPeople! == [self.joeObject, self.janeObject])
        
        let singleValueToArray: [Person] = try! map.extract("person")
        XCTAssert(singleValueToArray == [self.joeObject])
        
        let emptyPersons: [Person]? = try! <~map["i_dont_exist"]
        XCTAssert(emptyPersons == nil)
    }
    
    func testMappableArrayOfArrays() {
        let orderedGroups: [[Person]] = try! map.extract("ordered_groups")
        let optionalOrderedGroups: [[Person]]? = try! map.extract("ordered_groups")
        
        for orderGroupsArray in [orderedGroups, optionalOrderedGroups!] {
            XCTAssert(orderGroupsArray.count == 2)
            
            let firstGroup = orderGroupsArray[0]
            XCTAssert(firstGroup == [self.joeObject, self.justinObject, self.philObject])
            
            let secondGroup = orderGroupsArray[1]
            XCTAssert(secondGroup == [self.janeObject])
        }
        
        let arrayValueToArrayOfArrays: [[Person]] = try! map.extract("people")
        XCTAssert(arrayValueToArrayOfArrays.count == 1)
        XCTAssert(arrayValueToArrayOfArrays.first! == [self.joeObject, self.janeObject])
        
        let emptyArrayOfArrays: [[Person]]? = try! <~map["i_dont_exist"]
        XCTAssert(emptyArrayOfArrays == nil)
    }
    
    func testMappableDictionary() {
        let expectedRelationships = [
            "best_friend": self.philObject,
            "cousin": self.justinObject
        ]
        
        let relationships: [String : Person] = try! map.extract("relationships")
        XCTAssert(relationships == expectedRelationships)
        
        let optionalRelationships: [String : Person]? = try! map.extract("relationships")
        XCTAssert(optionalRelationships! == expectedRelationships)
        
        let emptyDictionary: [String : Person]? = try! <~map["i_dont_exist"]
        XCTAssert(emptyDictionary == nil)
    }
    
    func testMappableDictionaryOfArrays() {
        let groups: [String : [Person]] = try! map.extract("groups")
        let optionalGroups: [String : [Person]]? = try! map.extract("groups")
        
        for groupsArray in [groups, optionalGroups!] {
            XCTAssert(groupsArray.count == 2)
            
            let boys = groupsArray["boys"]!
            XCTAssert(boys == [self.joeObject, self.justinObject, self.philObject])
            
            let girls = groupsArray["girls"]!
            XCTAssert(girls == [self.janeObject])
        }
        
        let emptyDictionaryOfArrays: [String : [Person]]? = try! <~map["i_dont_exist"]
        XCTAssert(emptyDictionaryOfArrays == nil)
    }
    
    func testMappableSet() {
        let people: Set<Person> = try! map.extract("duplicated_people")
        let optionalPeople: Set<Person>? = try! <~map["duplicated_people"]
        
        for peopleSet in [people, optionalPeople!] {
            XCTAssert(peopleSet.count == 2)
            XCTAssert(peopleSet.contains(self.joeObject))
            XCTAssert(peopleSet.contains(self.janeObject))
        }
        
        let singleValueToSet: Set<Person> = try! map.extract("person")
        XCTAssert(singleValueToSet.count == 1)
        XCTAssert(singleValueToSet.contains(self.joeObject))
        
        let emptyPersons: [Person]? = try! <~map["i_dont_exist"]
        XCTAssert(emptyPersons == nil)
    }
    
    func testThatValueExistsButIsNotTheTypeExpectedNonOptional() {
        // Unexpected Type - Basic
        do {
            let _: String = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch NodeConvertibleError.UnableToConvert(_) {
//            XCTAssert(key == Key.KeyPath("int"))
//            if case NodeConvertibleError.UnableToConvert(node: _, to: _) = error { }
//            else {
//                XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
//            }
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
        }
        
        // Unexpected Type - Mappable Object
        do {
            let _: Person = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.foundNil(_) {
//            XCTAssert(key == Key.KeyPath("int"))
//            if case Error.SequenceError.foundNil(_) = error { }
//            else {
//                XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
//            }
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Unexpected Type - Mappable Array
        do {
            let _: [Person] = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.unexpected)")
        }

        // Unexpected Type - Mappable Array of Arrays
        do {
            let _: [[Person]] = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.unexpected)")
        }

        // Unexpected Type - Mappable Dictionary
        do {
            let _: [String : Person] = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.unexpected(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.unexpected)")
        }

        // Unexpected Type - Mappable Dictionary of Arrays
        do {
            let _: [String : [Person]] = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.unexpected(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.unexpected)")
        }
        
        // Unexpected Type - Transformable
        do {
            // Transformer expects string, but is passed an int
            let _: String = try <~map["int"]
                .transformFromNode { (input: String) in
                    return "Hello: \(input)"
            }
            XCTFail("Incorrect type should throw error")
        } catch NodeConvertibleError.UnableToConvert(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
        }
    }
    
    // If a value exists, but is the wrong type, it should throw error
    func testThatValueExistsButIsNotTheTypeExpectedOptional() {
        // Unexpected Value - Basic
        do {
            let _: String? = try map.extract("int")
            XCTFail("Incorrect type should throw error")
        } catch NodeConvertibleError.UnableToConvert(_) {
//            if case NodeConvertibleError.UnableToConvert(node: _, to: _) = error { }
//            else {
//                XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
//            }
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
        }

        // Unexpected Value - Mappable Object
        do {
            let _: Person? = try map.extract("int")
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.foundNil(_) {
//            XCTAssert(key == Key.KeyPath("int"))
//            if case Error.SequenceError.foundNil(_) = error { }
//            else {
//                XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
//            }
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        // Unexpected Value - Mappable Array
        do {
            let _: [Person]? = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Unexpected Value - Mappable Array of Arrays
        do {
            let _: [[Person]]? = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Unexpected Value - Mappable Dictionary
        do {
            let _: [String : Person]? = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.unexpected(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Unexpected Value - Mappable Dictionary of Arrays
        do {
            let _: [String : [Person]]? = try <~map["int"]
            XCTFail("Incorrect type should throw error")
        } catch Error.SequenceError.unexpected(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }

        // Unexpected Input Type (nil) - Transformable
        do {
            // Transformer expects string, but is passed an int
            let _: String? = try <~map["int"]
                .transformFromNode { (input: String?) in
                    return "Hello: \(input)"
            }
            XCTFail("Incorrect type should throw error")
        } catch NodeConvertibleError.UnableToConvert(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(NodeConvertibleError.UnableToConvert)")
        }
        
    }
    
    // Expected Something, Got Nothing
    func testThatValueDoesNotExistNonOptional() {
        // Expected Non-Nil - Basic
        do {
            let _: String = try <~map["asdf"]
            XCTFail("nil value should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Expected Non-Nil - Mappable
        do {
            let _: Person = try <~map["asdf"]
            XCTFail("nil value should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Expected Non-Nil - Mappable Array
        do {
            let _: [Person] = try <~map["asdf"]
            XCTFail("nil value should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Expected Non-Nil - Mappable Array of Arrays
        do {
            let _: [[Person]] = try <~map["asdf"]
            XCTFail("nil value should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Expected Non-Nil - Mappable Dictionary
        do {
            let _: [String : Person] = try <~map["asdf"]
            XCTFail("nil value should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Expected Non-Nil - Mappable Dictionary of Arrays
        do {
            let _: [String : [Person]] = try <~map["asdf"]
            XCTFail("nil value should throw error")
        } catch Error.SequenceError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(Error.SequenceError.foundNil)")
        }
        
        // Expected Non-Nil - Transformable
        do {
            // Transformer expects string, but is passed an int
            let _: String = try <~map["asdf"]
                .transformFromNode { (input: String) in
                    return "Hello: \(input)"
            }
            XCTFail("nil value should throw error")
        } catch TransformationError.foundNil(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(TransformationError.foundNil)")
        }
    }
    
    func testMapType() {
        do {
            let map = Map()
            let _: String = try <~map["a"]
            XCTFail("Inproper map type should throw error")
        } catch MappingError.UnexpectedOperationType(_) {
            
        } catch {
            XCTFail("Incorrect Error: \(error) Expected: \(MappingError.UnexpectedOperationType)")
        }
    }
    
}

// MARK: Operators

func ==(lhs: SettableOperatorTest.Person, rhs: SettableOperatorTest.Person) -> Bool {
    return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
}