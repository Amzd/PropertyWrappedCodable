//
//  CodableValue.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 10/12/2019.
//

let codableValueOutsidePropertyWrappedCodable = "Use inside PropertyWrappedCodable or FamilyCodable not Codable!"

protocol CodableValueProtocol {
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws
}

internal class StrongBox<Value> {
    var value: Value
    init(_ value: Value) {
        self.value = value
    }
}

/// A property wrapper that adds suport for inline default value and custom coding key for Codable.
/// Note: Must be used inside PropertyWrappedCodable or FamilyCodable.
@propertyWrapper public struct CodableValue<Value: Codable>: CodableValueProtocol {
    public var wrappedValue: Value {
        get { return box.value ?? { fatalError(codableValueOutsidePropertyWrappedCodable) }() }
        set { box = StrongBox(newValue) } // Create new holder so struct mutates
    }
    
    /// The Error if CodableValue fell back to the provided default value
    public var failure: Error? {
        return failureBox.value
    }
    
    private var hasDefault = false
    private var path: [String]?
    private var box = StrongBox<Value?>(nil)
    private var failureBox = StrongBox<Error?>(nil)
    
    // MARK: - Custom path
    
    public init(wrappedValue: Value, path: String...) {
        self.path = path
        self.hasDefault = true
        self.wrappedValue = wrappedValue
    }
    public init(path: String...) {
        self.path = path
    }
    
    // MARK: - Infered path
    
    public init(wrappedValue: Value) {
        self.hasDefault = true
        self.wrappedValue = wrappedValue
    }
    public init() {}
    
    // MARK: - CodableValueProtocol
    
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws {
        // label always starts with an underscore
        assert(label.first == "_")
        
        var container = container
        try path?.dropLast().forEach { step in
            container = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(stringValue: step))
        }
        
        let codingKey = AnyCodingKey(stringValue: path?.last ?? String(label.dropFirst()))
        
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
        var container = container
        path?.dropLast().forEach { step in
            container = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(stringValue: step))
        }
        let codingKey = AnyCodingKey(stringValue: path?.last ?? String(label.dropFirst()))
        try container.encode(wrappedValue, forKey: codingKey)
    }
}


// MARK: - Default to nil when using an Optional value
// eg: in `@CodableValue() var name: String?` default is nil

extension CodableValue where Value: OptionalType, Value.Wrapped == Value {
    public init(path: String...) {
        self.init(wrappedValue: .nil)
        self.path = path
    }
    public init() {
        self.init(wrappedValue: .nil)
    }
}
import Foundation

