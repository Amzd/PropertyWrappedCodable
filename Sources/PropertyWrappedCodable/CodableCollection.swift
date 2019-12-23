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

/// A property wrapper that changes the decoding strategy from the default of throwing when a single value is incorrect to a custom CollectionDecodingStrategy.
/// Note: Use CodableValue if the default behaviour is prefered.
@propertyWrapper public struct CodableCollection<Collection: CollectionWithThrowableType & Encodable>: CodableValueProtocol {
    public typealias Strategy = CollectionDecodingStrategy<Collection.Value>
    
    public var wrappedValue: Collection {
        get { return box.value ?? { fatalError("Use inside PropertyWrappedCodable or FamilyCodable not Codable!") }() }
        set { box = StrongBox(newValue) } // Create new holder so struct mutates
    }
    
    public var failures: [Error] {
        return failureBox.value
    }
    
    private var strategy: Strategy
    private var key: String?
    private var box = StrongBox<Collection?>(nil)
    private var failureBox = StrongBox<[Error]>([])
    
    // MARK: - Custom key
    
    public init(wrappedValue: Collection, _ strategy: Strategy = .lossy, key: String) {
        self.strategy = strategy
        self.key = key
        self.wrappedValue = wrappedValue
    }
    public init(_ strategy: Strategy = .lossy, key: String) {
        self.strategy = strategy
        self.key = key
    }
    
    // MARK: - Infered key
    
    public init(wrappedValue: Collection, _ strategy: Strategy = .lossy) {
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
        
        func decode() throws -> Collection {
            func getResultOrSaveError(from throwable: Collection.Throwable.Value) -> Collection.Value? {
                do {
                    return try throwable.result.get()
                } catch let error {
                    failureBox.value.append(error)
                    return nil
                }
            }
            
            switch strategy {
            case .fallbackValue(let fallback):
                return try container.decode(Collection.Throwable.self, forKey: codingKey).mapThrowableValues {
                    getResultOrSaveError(from: $0) ?? fallback
                }
            case .lossy:
                return try container.decode(Collection.Throwable.self, forKey: codingKey).compactMapThrowableValues {
                    getResultOrSaveError(from: $0)
                }
            }
        }
        
        do {
            box.value = try decode()
        } catch let error {
            if box.value == nil {
                throw error
            } else {
                failureBox.value.append(error)
            }
        }
    }
    
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws {
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        try container.encode(wrappedValue, forKey: codingKey)
    }
}

// MARK: - Default fallback to nil when using an Optional value in the collection
// eg: in `@CodableCollection() var pets: [Pet?]` failed Pet objects will fallback to nil

extension CodableCollection where Collection.Value: OptionalType, Collection.Value.Wrapped == Collection.Value {
    public init(wrappedValue: Collection, key: String) {
        self.init(wrappedValue: wrappedValue, .fallbackValue(.nil), key: key)
    }
    public init(key: String) {
        self.init(.fallbackValue(.nil), key: key)
    }
    public init(wrappedValue: Collection) {
        self.init(wrappedValue: wrappedValue, .fallbackValue(.nil))
    }
    public init() {
        self.init(.fallbackValue(.nil))
    }
}
