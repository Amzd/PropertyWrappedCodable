//
//  Throwable.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 11/12/2019.
//

public protocol ThrowableValueProtocol: Decodable {
    associatedtype Wrapped: Decodable
    var result: Result<Wrapped, Error> { get }
}
/// https://stackoverflow.com/a/52070521/3393964
public struct ThrowableValue<T: Decodable>: Decodable, ThrowableValueProtocol {
    public let result: Result<T, Error>

    public init(from decoder: Decoder) throws {
        result = Result(catching: { try T(from: decoder) })
    }
}

// MARK: - Protocols to implement if you want your Collection to work with @CodableCollection

public protocol CollectionWithThrowableType: Collection {
    associatedtype Throwable: Decodable & ThrowableCollection where Throwable.Value == ThrowableValue<Value>, Throwable.Parent == Self
    associatedtype Value: Decodable
}

public protocol ThrowableCollection: Collection where Value: ThrowableValueProtocol {
    associatedtype Parent: Decodable & CollectionWithThrowableType where Parent.Value == Value.Wrapped
    associatedtype Value
    
    func mapThrowableValues(_ transform: (Value) throws -> Parent.Value) rethrows -> Parent
    func compactMapThrowableValues(_ transform: (Value) throws -> Parent.Value?) rethrows -> Parent
}

// MARK: - Dictionary

extension Dictionary: CollectionWithThrowableType where Value: Decodable, Key: Decodable {
    public typealias Throwable = Dictionary<Key, ThrowableValue<Value>>
}

extension Dictionary: ThrowableCollection where Value: ThrowableValueProtocol, Key: Decodable  {
    public typealias Parent = Dictionary<Key, Value.Wrapped>
    
    public func mapThrowableValues(_ transform: (Value) throws -> Value.Wrapped) rethrows -> Parent {
        return try mapValues(transform)
    }

    public func compactMapThrowableValues(_ transform: (Value) throws -> Value.Wrapped?) rethrows -> Parent {
        return try compactMapValues(transform)
    }
}

// MARK: - Array

extension Array: CollectionWithThrowableType where Element: Decodable {
    public typealias Throwable = Array<ThrowableValue<Element>>
    public typealias Value = Element
}

extension Array: ThrowableCollection where Element: ThrowableValueProtocol {
    public typealias Parent = Array<Element.Wrapped>
    
    public func mapThrowableValues(_ transform: (Value) throws -> Value.Wrapped) rethrows -> Parent {
        return try map(transform)
    }

    public func compactMapThrowableValues(_ transform: (Value) throws -> Value.Wrapped?) rethrows -> Parent {
        return try compactMap(transform)
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
