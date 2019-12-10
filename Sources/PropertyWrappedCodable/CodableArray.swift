//
//  CodableArray.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 10/12/2019.
//

import Foundation

public enum ArrayDecodingStrategy<V> {
    /// Throws when any elements is incorrect (default decoding behaviour)
    case exact
    /// Replaces invalid elements with fallback value:
    /// ["This", null, "That"] -> ["This", "FallbackValue", "That"]
    case fallbackValue(V)
    /// Leaves out invalid elements:
    /// [1, 2, "3"] -> [1, 2]
    /// Note: Throws when there is no array! Use default if you don't want this.
    case compacted
}

/// https://stackoverflow.com/a/52070521/3393964
struct Throwable<T: Decodable>: Decodable {
    let result: Result<T, Error>

    init(from decoder: Decoder) throws {
        result = Result(catching: { try T(from: decoder) })
    }
}

@propertyWrapper public struct CodableArray<Element: Codable>: CodableValueProtocol {
    public typealias Value = Array<Element>
    typealias ThrowableValue = Array<Throwable<Element>>
    public typealias Strategy = ArrayDecodingStrategy<Element>
    
    public var wrappedValue: Value {
        get { return box.value ?? { fatalError("Use inside PropertyWrappedCodable or FamilyCodable not Codable!") }() }
        set { box = StrongBox(newValue) } // Create new holder so struct mutates
    }
    
    private var strategy: Strategy
    private var key: String?
    private var box = StrongBox<Value>()
    
    // MARK: - Custom key
    
    public init(wrappedValue: Value, strategy: Strategy, key: String) {
        self.strategy = strategy
        self.key = key
        self.wrappedValue = wrappedValue
    }
    public init(strategy: Strategy, key: String) {
        self.strategy = strategy
        self.key = key
    }
    
    // MARK: - Infered key
    
    public init(wrappedValue: Value, strategy: Strategy) {
        self.strategy = strategy
        self.wrappedValue = wrappedValue
    }
    public init(strategy: Strategy) {
        self.strategy = strategy
    }
    
    // MARK: - CodableValueProtocol
       
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws {
        // label always starts with an underscore
        assert(label.first == "_")
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        
        func decode() throws -> Value {
            switch strategy {
            case .exact:
                return try container.decode(Value.self, forKey: codingKey)
            case .fallbackValue(let fallback):
                return try container.decode(ThrowableValue.self, forKey: codingKey).map {
                    (try? $0.result.get()) ?? fallback
                }
            case .compacted:
                return try container.decode(ThrowableValue.self, forKey: codingKey).compactMap {
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
