public protocol PropertyWrappedCodable: Codable {
    /// Warning: Property wrapped values arent available here yet!
    init(nonWrappedPropertiesFrom decoder: Decoder) throws
    typealias CodableValueKeyPaths = [String: AnyKeyPath]
    /// Implement if you dont want to use Mirror. This is way faster than using Mirror.
    var keyPathsForCodableValues: CodableValueKeyPaths? { get }
}

public extension PropertyWrappedCodable {
    var keyPathsForCodableValues: CodableValueKeyPaths? { nil }
    
    init(from decoder: Decoder) throws {
        try self.init(wrappedPropertiesFrom: decoder)
    }
    
    /// Call this when you override `init(from:)`
    init(wrappedPropertiesFrom decoder: Decoder) throws {
        try self.init(nonWrappedPropertiesFrom: decoder)
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        
        if let keyPaths = keyPathsForCodableValues {
            for (label, keyPath) in keyPaths {
                let value = self[keyPath: keyPath] as? CodableValueProtocol
                try value?.initValue(with: label, from: container)
            }
        } else {
            var optionalMirror: Mirror? = Mirror(reflecting: self)
            while let mirror = optionalMirror {
                for child in mirror.children {
                    let value = child.value as? CodableValueProtocol
                    try value?.initValue(with: child.label!, from: container)
                }
                optionalMirror = mirror.superclassMirror
            }
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

extension AnyKeyPath {
    /// Returns key path represented as a string
    var asString: String? {
        return _kvcKeyPathString?.description
    }
}
