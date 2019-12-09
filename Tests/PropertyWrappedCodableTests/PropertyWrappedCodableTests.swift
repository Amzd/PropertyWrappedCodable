import XCTest
@testable import PropertyWrappedCodable

struct WrappedExample: PropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableValue() var id: String = "Default"
    @CodableValue() var dog: String?
    @CodableValue(key: "is_active") var isActive: Bool
    
    init(nonWrappedValuesFrom decoder: Decoder) throws {}
}

struct CodableExample: Codable {
    var name: String
    var id: String
    var dog: String
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case dog
        case isActive = "is_active"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = (try? container.decode(String.self, forKey: .id)) ?? "Default"
        dog = try container.decode(String.self, forKey: .dog)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
}

let decoder = JSONDecoder()
let encoder = JSONEncoder()

final class PropertyWrappedCodableTests: XCTestCase {
    func measureWrapped() {
        measure {
            let _ = try? decoder.decode([WrappedExample].self, from: mockData)
        }
    }
    
    func measureCodable() {
        measure {
            let _ = try? decoder.decode([CodableExample].self, from: mockData)
        }
    }
    
    func testEncodeResultEqual() {
        do {
            let wrapped = try decoder.decode([CodableExample].self, from: mockData)
            let codable = try decoder.decode([CodableExample].self, from: mockData)
            XCTAssert(wrapped.count == 1000 && codable.count == 1000)
            let wrappedEncoded = try encoder.encode(wrapped)
            let codableEncoded = try encoder.encode(codable)
            XCTAssert(wrappedEncoded == codableEncoded)
            // result is not equal to mockData because default values are filled
        } catch let error {
            XCTFail("\(error)")
            return
        }
    }
    

    static var allTests = [
        ("measureWrapped", measureWrapped),
        ("measureCodable", measureCodable),
        ("testEncodeResultEqual", testEncodeResultEqual),
    ]
}
