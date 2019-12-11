//
//  CodableCollection.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 10/12/2019.
//

import Foundation

public enum CollectionDecodingStrategy<V> {
    /// Replaces invalid elements with fallback value:
    /// ["This", null, "That"] -> ["This", "FallbackValue", "That"]
    /// This is the default with `nil` as fallback value if the collection uses an Optional type (eg: [Int?])
    case fallbackValue(V)
    /// Leaves out invalid elements:
    /// [1, 2, "3"] -> [1, 2]
    /// This is the default unless the collection uses an Optional type (eg: [Int?])
    /// Note: Throws when there is no collection! Use default if you don't want that.
    case lossy
}

@propertyWrapper public struct CodableCollection<Value: ThrowableCollection & Codable>: CodableValueProtocol {
    public typealias Strategy = CollectionDecodingStrategy<Value.Value>
    
    public var wrappedValue: Value {
        get { return box.value ?? { fatalError("Use inside PropertyWrappedCodable or FamilyCodable not Codable!") }() }
        set { box = StrongBox(newValue) } // Create new holder so struct mutates
    }
    
    private var strategy: Strategy
    private var key: String?
    private var box = StrongBox<Value>()
    
    // MARK: - Custom key
    
    public init(wrappedValue: Value, _ strategy: Strategy = .lossy, key: String) {
        self.strategy = strategy
        self.key = key
        self.wrappedValue = wrappedValue
    }
    public init(_ strategy: Strategy = .lossy, key: String) {
        self.strategy = strategy
        self.key = key
    }
    
    // MARK: - Infered key
    
    public init(wrappedValue: Value, _ strategy: Strategy = .lossy) {
        self.strategy = strategy
        self.wrappedValue = wrappedValue
    }
    public init(_ strategy: Strategy = .lossy) {
        self.strategy = strategy
    }
    
    // MARK: - CodableValueProtocol
    
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws {
        // label always starts with an underscore
        assert(label.first == "_")
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        
        func decode() throws -> Value {
            switch strategy {
            case .fallbackValue(let fallback):
                return try container.decode(Value.Throwable.self, forKey: codingKey).mapValues {
                    (try? $0.result.get()) ?? fallback
                }
            case .lossy:
                return try container.decode(Value.Throwable.self, forKey: codingKey).compactMapValues {
                    try? $0.result.get()
                }
            }
        }
        
        if box.value == nil {
            box.value = try decode()
        } else if let value = try? decode() {
            box.value = value
        }
    }
    
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws {
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        try container.encode(wrappedValue, forKey: codingKey)
    }
}

// MARK: - Default fallback to nil when using an Optional value in the collection
// eg: in `@CodableCollection() var pets: [Pet?]` failed Pet objects will fallback to nil

public protocol OptionalType {
    associatedtype Wrapped
    static var `nil`: Wrapped { get }
}

extension Optional: OptionalType {
    public static var `nil`: Optional<Wrapped> { return .none }
}

extension CodableCollection where Value.Value: OptionalType, Value.Value.Wrapped == Value.Value {
    public init(wrappedValue: Value, key: String) {
        self.strategy = .fallbackValue(.nil)
        self.key = key
        self.wrappedValue = wrappedValue
    }
    public init(key: String) {
        self.strategy = .fallbackValue(.nil)
        self.key = key
    }
    public init(wrappedValue: Value) {
        self.strategy = .fallbackValue(.nil)
        self.wrappedValue = wrappedValue
    }
    public init() {
        self.strategy = .fallbackValue(.nil)
    }
}