public protocol PropertyWrappedCodable: Codable {
    /// Warning: Property wrapped values arent available here yet!
    init(nonWrappedPropertiesFrom decoder: Decoder) throws
}

public extension PropertyWrappedCodable {
    init(from decoder: Decoder) throws {
        try self.init(wrappedPropertiesFrom: decoder)
    }
    
    /// Call this when you override `init(from:)`
    init(wrappedPropertiesFrom decoder: Decoder) throws {
        try self.init(nonWrappedPropertiesFrom: decoder)
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        var optionalMirror: Mirror? = Mirror(reflecting: self)
        while let mirror = optionalMirror {
            for child in mirror.children {
                let value = child.value as? CodableValueProtocol
                try value?.initValue(with: child.label!, from: container)
            }
            optionalMirror = mirror.superclassMirror
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try encode(propertyWrappedValuesTo: encoder)
    }
    
    /// Call this when you override `encode(to:)`
    func encode(propertyWrappedValuesTo encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        var optionalMirror: Mirror? = Mirror(reflecting: self)
        while let mirror = optionalMirror {
            for child in mirror.children {
                let value = child.value as? CodableValueProtocol
                try value?.encodeValue(with: child.label!, to: &container)
            }
            optionalMirror = mirror.superclassMirror
        }
    }
}
