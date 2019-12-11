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

class CodableCollectionTests: XCTestCase {
    func testExample() {
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
}
