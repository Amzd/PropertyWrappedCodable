import XCTest
@testable import PropertyWrappedCodable

class Pet: FamilyCodable, Equatable {
    @CodableValue() var name: String
    @CodableValue() private var type: String
    
    var someOtherValue: String
    
    required init(nonWrappedPropertiesFrom decoder: Decoder) throws {
        someOtherValue = "no"
    }
    
    static var discriminatorKey = "type"
    
    final class func familyMember(for value: String) throws -> Codable.Type {
        switch value {
        case "Cat": return Cat.self
        case "Dog": return Dog.self
        default: return Pet.self
        }
    }
    
    static func == (lhs: Pet, rhs: Pet) -> Bool {
        lhs.name == rhs.name && lhs.type == rhs.type
    }
}

class Cat: Pet {
    @CodableValue() var lives: Int
    
    static func == (lhs: Cat, rhs: Cat) -> Bool {
        lhs.lives == rhs.lives && lhs as Pet == rhs as Pet
    }
}

class Dog: Pet {
    func fetch() { }
}

final class FamilyCodableTests: XCTestCase {
    
    func testJson() {
        let petsJson = """
        [
            { "type": "Cat", "name": "Garfield", "lives": 9 },
            { "type": "Dog", "name": "Pluto" }
        ]
        """
        let petsData = petsJson.data(using: .utf8)!
        
        do {
            let pets = try decoder.decode([Pet].self, from: petsData)
            XCTAssert(pets.first is Cat)
            XCTAssert(pets.last is Dog)
            XCTAssert(pets.first?.someOtherValue == "no")
            
            let again = try decoder.decode([Pet].self, from: try encoder.encode(pets))
            XCTAssert(again.first is Cat)
            XCTAssert(again.last is Dog)
            XCTAssert(again == pets)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    static var allTests = [
        ("testJson", testJson),
    ]
}
