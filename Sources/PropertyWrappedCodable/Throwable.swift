//
//  Throwable.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 11/12/2019.
//

/// https://stackoverflow.com/a/52070521/3393964
public struct ThrowableValue<T: Decodable>: Decodable {
    let result: Result<T, Error>

    public init(from decoder: Decoder) throws {
        result = Result(catching: { try T(from: decoder) })
    }
}

/// Implement this if you want your Collection to work with @CodableCollection
public protocol ThrowableCollection: Collection {
    associatedtype Throwable: Decodable & ThrowableCollection where Throwable.Value == ThrowableValue<Value>
    associatedtype Value: Decodable
    func mapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value) rethrows -> T
    func compactMapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value?) rethrows -> T
}

extension Dictionary: ThrowableCollection where Value: Decodable, Key: Decodable {
    public typealias Throwable = Dictionary<Key, ThrowableValue<Value>>
    
    public func mapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value) rethrows -> T {
        return try mapValues(transform) as! T
    }
    
    public func compactMapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value?) rethrows -> T {
        return try compactMapValues(transform) as! T
    }
}

extension Array: ThrowableCollection where Element: Decodable {
    public typealias Throwable = Array<ThrowableValue<Element>>
    public typealias Value = Element
    
    public func mapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value) rethrows -> T {
        return try map(transform) as! T
    }
    
    public func compactMapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value?) rethrows -> T {
        return try compactMap(transform) as! T
    }
}

// Need to make ThrowableValue hashable for this to work
//extension Set: ThrowableCollection where Element: Decodable {
//    public typealias Throwable = Set<ThrowableValue<Element>>
//    public typealias Value = Element
//
//    public func mapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value) rethrows -> T {
//        return try map {
//            try transform($0)
//        } as! T
//    }
//
//    public func compactMapValues<T: ThrowableCollection>(_ transform: (Value) throws -> T.Value?) rethrows -> T {
//        return try compactMap {
//            try transform($0)
//        } as! T
//    }
//}
