import XCTest
@testable import PropertyWrappedCodable

struct WrappedExample: PropertyWrappedCodable {
    @CodableValue var name: String
    @CodableValue var id: String = "Default"
    @CodableValue var dog: String?
    @CodableValue(key: "is_active") var isActive: Bool

    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
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

struct RuntimeExample: RuntimePropertyWrappedCodable {
    @CodableValue var name: String
    @CodableValue var id: String = "Default"
    @CodableValue var dog: String?
    @CodableValue(key: "is_active") var isActive: Bool

    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

struct EchoExample: EchoPropertyWrappedCodable {
    @CodableValue var name: String
    @CodableValue var id: String = "Default"
    @CodableValue var dog: String?
    @CodableValue(key: "is_active") var isActive: Bool

    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

func == (lhs: WrappedExample, rhs: RuntimeExample) -> Bool {
    lhs.name == rhs.name && lhs.id == rhs.id && lhs.dog == rhs.dog && lhs.isActive == rhs.isActive
}

let decoder = JSONDecoder()
let encoder = JSONEncoder()

let iterate50times: XCTMeasureOptions = {
    let options = XCTMeasureOptions.default
    options.iterationCount = 50
    return options
}()

@available(OSX 10.15, *)
final class PropertyWrappedCodableTests: XCTestCase {
    func testMeasureWrapped() {
        /// Baseline: 0.045s
        measure(options: iterate50times) {
            _ = try? decoder.decode([WrappedExample].self, from: mockData)
        }
    }

    func testMeasureCodable() {
        /// Baseline: 0.0086s
        measure(options: iterate50times) {
            _ = try? decoder.decode([CodableExample].self, from: mockData)
        }
    }
    
    func testMeasureRuntime() {
        /// Baseline: 0.053s
        measure(options: iterate50times) {
            _ = try? decoder.decode([RuntimeExample].self, from: mockData)
        }
    }
    
    func testMeasureEcho() {
        /// Baseline: 0.093s
        measure(options: iterate50times) {
            _ = try? decoder.decode([EchoExample].self, from: mockData)
        }
    }
    
    func testRuntimeEqualsWrapped() {
        let runtime = try! decoder.decode([RuntimeExample].self, from: mockData)
        let wrapped = try! decoder.decode([WrappedExample].self, from: mockData)
        for index in (0..<1000) {
            XCTAssert(wrapped[index] == runtime[index])
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
        ("testMeasureWrapped", testMeasureWrapped),
        ("testMeasureCodable", testMeasureCodable),
        ("testMeasureRuntime", testMeasureRuntime),
        ("testMeasureEcho", testMeasureEcho),
        ("testEncodeResultEqual", testEncodeResultEqual),
    ]
}
