//
//  CodableValue.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 10/12/2019.
//

protocol CodableValueProtocol {
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws
}

/// A property wrapper that adds suport for inline default value and custom coding key for Codable.
/// Note: Must be used inside PropertyWrappedCodable or FamilyCodable.
@propertyWrapper public struct CodableValue<Value: Codable>: CodableValueProtocol {
    public var wrappedValue: Value {
        get { return box.value ?? { fatalError("Use inside PropertyWrappedCodable or FamilyCodable not Codable!") }() }
        set { box = StrongBox(newValue) } // Create new holder so struct mutates
    }
    
    /// The Error if CodableValue fell back to the provided default value
    public var failure: Error? {
        return failureBox.value
    }
    
    private var hasDefault = false
    private var key: String?
    private var box = StrongBox<Value?>(nil)
    private var failureBox = StrongBox<Error?>(nil)
    
    // MARK: - Custom key
    
    public init(wrappedValue: Value, key: String) {
        self.key = key
        self.hasDefault = true
        self.wrappedValue = wrappedValue
    }
    public init(key: String) {
        self.key = key
    }
    
    // MARK: - Infered key
    
    public init(wrappedValue: Value) {
        self.hasDefault = true
        self.wrappedValue = wrappedValue
    }
    public init() {}
    
    // MARK: - CodableValueProtocol
    
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws {
        // label always starts with an underscore
        assert(label.first == "_")
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        
        do {
            box.value = try container.decode(Value.self, forKey: codingKey)
        } catch let error {
            if hasDefault {
                failureBox.value = error
            } else {
                throw error
            }
        }
    }
    
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws {
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        try container.encode(wrappedValue, forKey: codingKey)
    }
}

internal class StrongBox<Value> {
    var value: Value
    init(_ value: Value) {
        self.value = value
    }
}

// MARK: - Default to nil when using an Optional value
// eg: in `@CodableValue() var name: String?` default is nil

extension CodableValue where Value: OptionalType, Value.Wrapped == Value {
    public init(key: String) {
        self.init(wrappedValue: .nil, key: key)
    }
    public init() {
        self.init(wrappedValue: .nil)
    }
}
