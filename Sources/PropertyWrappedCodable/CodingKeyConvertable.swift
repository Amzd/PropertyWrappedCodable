//
//  CodingKeyConvertable.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 10/12/2019.
//

import Foundation

public typealias CodingKey = Swift.CodingKey & CodingKeyConvertable

public protocol CodingKeyConvertable {
    var stringValue: String { get }
    var intValue: Int? { get }
}

extension CodingKeyConvertable {
    func toAnyCodingKey() -> AnyCodingKey {
        return AnyCodingKey(stringValue: stringValue, intValue: intValue)
    }
}

extension String: CodingKeyConvertable {
    public var stringValue: String {
        return self
    }
    
    public var intValue: Int? {
        return nil
    }
}

extension Int: CodingKeyConvertable {
    public var stringValue: String {
        return "\(self)"
    }
    
    public var intValue: Int? {
        return self
    }
}
