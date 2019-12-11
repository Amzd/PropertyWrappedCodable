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
    
    init(nonWrappedValuesFrom decoder: Decoder) throws { }
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
    
    init(nonWrappedValuesFrom decoder: Decoder) throws { }
}

struct PersonVerbose: PropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableCollection(.lossy, key: "pets") var pets: [Pet]
    @CodableCollection(.fallbackValue(nil), key: "pets") var petsFallback: [Pet?]
    
    init(nonWrappedValuesFrom decoder: Decoder) throws { }
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
        } catch let error {
            XCTFail("\(error)")
        }
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
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
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    static var allTests = [
        ("testPersonExample", testPersonExample),
        ("testCollectionExample", testCollectionExample),
    ]
}
