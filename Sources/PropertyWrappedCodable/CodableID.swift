//
//  CodableID.swift
//  PropertyWrappedCodable
//
//  Created by Casper Zandbergen on 06/01/2020.
//

import Foundation

public enum CodableIDError: Error {
    case decoderDidNotContainParent
}

/// The key of the current json object.
/// https://stackoverflow.com/questions/58266456/swift-codable-use-a-parents-key-as-as-value
///
/// {
///     "items": {
///         "id_0": { "name": "Casper" },
///         "id_1": { "name": "Zandbergen" }
///     }
/// }
///
/// struct Example: Codable {
///     var items: [String: Item]
/// }
///
/// struct Item: PropertyWrappedCodable {
///     @CodableID() var id: String
///     @CodableValue() var name: String
///
///     init(nonWrappedPropertiesFrom decoder: Decoder) throws { }
/// }
///
@propertyWrapper public struct CodableID: CodableValueProtocol {
    public var wrappedValue: String {
        get { return box.value ?? { fatalError(codableValueOutsidePropertyWrappedCodable) }() }
        set { box = StrongBox(newValue) } // Create new holder so struct mutates
    }
    private var box = StrongBox<String?>(nil)
    
    public init() {}
    
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws {
        if let id = container.codingPath.last?.stringValue {
            box.value = id
        } else {
            throw CodableIDError.decoderDidNotContainParent
        }
    }
    
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws {}
}
