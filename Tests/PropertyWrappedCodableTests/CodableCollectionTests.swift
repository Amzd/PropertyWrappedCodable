//
//  CodableCollectionTests.swift
//  PropertyWrappedCodableTests
//
//  Created by Casper Zandbergen on 11/12/2019.
//

import XCTest
@testable import PropertyWrappedCodable

struct Person: PropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableCollection(key: "pets") var pets: [Pet]
    @CodableCollection(key: "pets") var petsFallback: [Pet?]
    
    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

// The exact same as Person
struct PersonVerbose: PropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableCollection(.lossy, key: "pets") var pets: [Pet]
    @CodableCollection(.fallbackValue(nil), key: "pets") var petsFallback: [Pet?]
    
    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

struct CollectionExample: PropertyWrappedCodable {
    // defaults to .lossy so failed decoding wont be shown
    @CodableCollection() var ids1: [Int]
    // same as ids1
    @CodableCollection(.lossy) var ids2: [Int]
    
    // defaults fallback to `nil`
    @CodableCollection() var ids3: [Int?]
    // same as ids3
    @CodableCollection(.fallbackValue(nil)) var ids4: [Int?]
    
    // falls back to 0 if decoding fails
    @CodableCollection(.fallbackValue(0)) var ids5: [Int]
    
    var errors: [Error] {
        _ids1.failures + _ids2.failures + _ids3.failures + _ids4.failures + _ids5.failures
    }
    
    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

class CodableCollectionTests: XCTestCase {
    func testPersonExample() {
        let data = """
        {
            "name": "Casper",
            "pets": [
                { "type": "Cat", "name": "Garfield", "lives": 9 },
                { "name": "No type so this won't decode but the rest of the array will" },
                { "type": "Dog", "name": "Pluto" }
            ]
        }
        """.data(using: .utf8)!
        do {
            let person = try JSONDecoder().decode(Person.self, from: data)
            
            XCTAssert(person.pets.count == 2)
            XCTAssert(person.pets.first is Cat)
            XCTAssert(person.pets.last is Dog)
            
            XCTAssert(person.petsFallback.count == 3)
            XCTAssert(person.petsFallback.first is Cat)
            XCTAssert(person.petsFallback[1] == nil)
            XCTAssert(person.petsFallback.last is Dog)
            
            let personEncoded = try encoder.encode(person)
            let again = try decoder.decode(Person.self, from: personEncoded)
            XCTAssert(try encoder.encode(again) == personEncoded)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testCollectionExample() {
        let json = """
        {
            "ids1" : [1, 2, "3"],
            "ids2" : [1, 2, "3"],
            "ids3" : [1, 2, "3"],
            "ids4" : [1, 2, "3"],
            "ids5" : [1, 2, "3"]
        }
        """
        let data = json.data(using: .utf8)!
        do {
            let example = try decoder.decode(CollectionExample.self, from: data)
            XCTAssert(example.ids1 == [1, 2])
            XCTAssert(example.ids2 == [1, 2])
            XCTAssert(example.ids3 == [1, 2, nil])
            XCTAssert(example.ids4 == [1, 2, nil])
            XCTAssert(example.ids5 == [1, 2, 0])
            XCTAssert(example.errors.count == 5) // the string values throw errors
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testCollectionExample2() {
        struct CollectionExample2: PropertyWrappedCodable, EmptyInitialiser {
            @CodableCollection() var array: [Int]
            @CodableCollection() var dict: [String: Int]
            @CodableCollection() var set: Set<Int>
            
            var errors: [Error] {
                _array.failures + _dict.failures
            }
            
//            init(nonWrappedPropertiesFrom decoder: Decoder) { }
        }
        
        let json = """
        {
            "array" : [1, 2, "3"],
            "dict" : {
                "1" : 1,
                "2" : 2,
                "3" : "3"
            },
            "set" : [1, 2, "3"]
        }
        """
        let data = json.data(using: .utf8)!
        do {
            let example = try decoder.decode(CollectionExample2.self, from: data)
            XCTAssert(example.array == [1, 2])
            XCTAssert(example.dict == ["1": 1, "2": 2])
            XCTAssert(example.set == Set([1, 2]))
            XCTAssert(example.errors.count == 2) // the string values throw errors
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    static var allTests = [
        ("testPersonExample", testPersonExample),
        ("testCollectionExample", testCollectionExample),
        ("testCollectionExample2", testCollectionExample2),
    ]
}
