//
//  OptionalType.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 23/12/2019.
//

public protocol OptionalType {
    associatedtype Wrapped
    static var `nil`: Wrapped { get }
}

extension Optional: OptionalType {
    public static var `nil`: Optional<Wrapped> { return .none }
}
