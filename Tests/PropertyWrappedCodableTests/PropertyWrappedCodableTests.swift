import XCTest
@testable import PropertyWrappedCodable
import GenericJSON

class WrappedExample: PropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableValue() var id: String = "Default"
    @CodableValue() var dog: String?
    @CodableValue(path: "is_active") var isActive: Bool

    required init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

struct WrappedFastExample: PropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableValue() var id: String = "Default"
    @CodableValue() var dog: String?
    @CodableValue(path: "is_active") var isActive: Bool

    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
    
    var keyPathsForCodableValues: CodableValueKeyPaths? {
        [
            "_name": \Self._name,
            "_id": \Self._id,
            "_dog": \Self._dog,
            "_isActive": \Self._isActive
        ]
    }
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
    @CodableValue() var name: String
    @CodableValue() var id: String = "Default"
    @CodableValue() var dog: String?
    @CodableValue(path: "is_active") var isActive: Bool

    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

struct EchoExample: EchoPropertyWrappedCodable {
    @CodableValue() var name: String
    @CodableValue() var id: String = "Default"
    @CodableValue() var dog: String?
    @CodableValue(path: "is_active") var isActive: Bool

    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
}

//struct ReflectionExample: ReflectionPropertyWrappedCodable {
//    @CodableValue() var name: String
//    @CodableValue() var id: String = "Default"
//    @CodableValue() var dog: String?
//    @CodableValue(path: "is_active") var isActive: Bool
//
//    init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
//}

func == (lhs: WrappedExample, rhs: RuntimeExample) -> Bool {
    lhs.name == rhs.name && lhs.id == rhs.id && lhs.dog == rhs.dog && lhs.isActive == rhs.isActive
}
func == (lhs: WrappedExample, rhs: EchoExample) -> Bool {
    lhs.name == rhs.name && lhs.id == rhs.id && lhs.dog == rhs.dog && lhs.isActive == rhs.isActive
}
//func == (lhs: WrappedExample, rhs: ReflectionExample) -> Bool {
//    lhs.name == rhs.name && lhs.id == rhs.id && lhs.dog == rhs.dog && lhs.isActive == rhs.isActive
//}

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
    
    func testMeasureFastWrapped() {
        /// Baseline: 0.045s
        measure(options: iterate50times) {
            _ = try? decoder.decode([WrappedFastExample].self, from: mockData)
        }
    }
    
    // broken
//    func testMeasureReflection() {
//        /// Baseline: 0.045s
//        measure(options: iterate50times) {
//            _ = try? decoder.decode([ReflectionExample].self, from: mockData)
//        }
//    }

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
        do {
            let wrapped = try decoder.decode([WrappedExample].self, from: mockData)
            let runtime = try decoder.decode([RuntimeExample].self, from: mockData)
            let echo = try decoder.decode([EchoExample].self, from: mockData)
//            let reflection = try decoder.decode([ReflectionExample].self, from: mockData) // broken
            for index in (0..<1000) {
                XCTAssert(wrapped[index] == runtime[index])
                XCTAssert(wrapped[index] == echo[index])
//                XCTAssert(wrapped[index] == reflection[index]) // broken
            }
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testEncodeResultEqual() {
        do {
            let wrapped = try decoder.decode([WrappedExample].self, from: mockData)
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
    
    func testOptionalDefault() {
        struct OptionalDefaultExample: PropertyWrappedCodable {
            @CodableValue() var string: String?
            @CodableValue() var array: [String]?
            
            init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
        }
        
        let json = "{}"
        let data = json.data(using: .utf8)!
        
        do {
            let example = try decoder.decode(OptionalDefaultExample.self, from: data)
            XCTAssert(example.string == nil)
            XCTAssert(example.array == nil)
        } catch let error {
            XCTFail("\(error)")
            return
        }
    }
    
    func testFoundationObjectsUsingJSONSerialization() {
        struct AnyExample: PropertyWrappedCodable {
            @CodableValue() var string: String?
            @CodableValue() var json: JSON
            
            init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
        }
        
        let json = """
        {
            "json": {
                "dict": { "test": 1 },
                "array": [
                    { "type": "Cat", "name": "Garfield", "lives": 9 },
                    { "type": "Dog", "name": "Pluto" },
                ]
            }
            
        }
        """
        let data = json.data(using: .utf8)!
        
        do {
            let example = try decoder.decode(AnyExample.self, from: data)
            XCTAssert(example.string == nil)
            XCTAssert(example.json != nil, "\(example.json)")
        } catch let error {
            XCTFail("\(error)")
            return
        }
    }
    
    func testCustomPath() {
        struct Example: PropertyWrappedCodable {
            @CodableValue(path: "json", "dict", "test") var test: String
            
            init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
        }
        
        let json = """
        {
            "json": {
                "dict": {
                    "test": "Nested"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        
        do {
            let example = try decoder.decode(Example.self, from: data)
            XCTAssert(example.test == "Nested")
            let encoded = try encoder.encode(example)
            let example2 = try decoder.decode(Example.self, from: encoded)
            XCTAssert(example.test == example2.test)
        } catch let error {
            XCTFail("\(error)")
            return
        }
    }
    
    func testID() {
        struct Example: Codable {
            var items: [String: Item]
        }
        
        struct Item: PropertyWrappedCodable {
            @CodableID() var id: String
            @CodableValue() var name: String
            
            init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
        }
        
        let json = """
        {
            "items": {
                "id_0": { "name": "Casper" },
                "id_1": { "name": "Zandbergen" }
            }
        }
        """
        let data = json.data(using: .utf8)!
        
        do {
            let example = try decoder.decode(Example.self, from: data)
            XCTAssert(example.items.count == 2)
            XCTAssert(example.items["id_0"]?.id == "id_0", example.items.first?.value.id ?? "")
        } catch let error {
            XCTFail("\(error)")
            return
        }
    }
    
    func test123() {
        class StrongBox<Value> {
            var value: Value
            init(_ value: Value) {
                self.value = value
            }
        }
        @propertyWrapper
        struct TestWrapper: Decodable {
            var wrappedValue: String {
                get { box.value }
                set { box.value = newValue }
            }
            
            init() {
                print("init", ObjectIdentifier(box), ObjectIdentifier(Self.self))
            }
            
            init(from decoder: Decoder) throws {
                print("init decoder", ObjectIdentifier(box), ObjectIdentifier(Self.self))
            }
            
            public static subscript<EnclosingSelf>(
                _enclosingInstance observed: EnclosingSelf,
                wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, String>,
                storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>//,
//                _line: Int = #line,
//                _function: String = #function
            ) -> String {
                get {
                    print("get", ObjectIdentifier(observed[keyPath: storageKeyPath].box), ObjectIdentifier(Self.self))
                    return observed[keyPath: storageKeyPath].wrappedValue
                }
                set {
                    print("set", #line, #function)
                    observed[keyPath: storageKeyPath].wrappedValue = newValue
                }
            }
            
            private var box = StrongBox<String>("")
        }
        class Test: Decodable {
            @TestWrapper
            var a: String
            @TestWrapper
            var b: String
        }
        
        let json = """
        {
            "a": "Hello",
            "b": "world!"
        }
        """
        let data = json.data(using: .utf8)!
        
        do {
            let example = try decoder.decode(Test.self, from: data)
            XCTAssert(example.a == "")
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
        ("testOptionalDefault", testOptionalDefault),
    ]
}
