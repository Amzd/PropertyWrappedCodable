@testable import Runtime
@testable import PropertyWrappedCodable

public protocol RuntimePropertyWrappedCodable: Codable {
    /// Warning: Property wrapped values arent available here yet!
    init(nonWrappedValuesFrom decoder: Decoder) throws
}

public extension RuntimePropertyWrappedCodable {
    init(from decoder: Decoder) throws {
        try self.init(propertyWrappedValuesFrom: decoder)
    }
    
    /// Call this when you override `init(from:)`
    init(propertyWrappedValuesFrom decoder: Decoder) throws {
        try self.init(nonWrappedValuesFrom: decoder)
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        
        for prop in try properties(of: Self.self) {
            let value: CodableValueProtocol? = try? prop.get(from: self)
            try value?.initValue(with: prop.name, from: container)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try encode(propertyWrappedValuesTo: encoder)
    }
    
    /// Call this when you override `encode(to:)`
    func encode(propertyWrappedValuesTo encoder: Encoder) throws {
        fatalError()
    }
}


func properties(of type: Any.Type) throws -> [PropertyInfo] {
    
    let kind = Kind(type: type)
    
    switch kind {
    case .struct:
        var metadata = StructMetadata(type: type)
        return metadata.properties()
    case .class:
        var metadata = ClassMetadata(type: type)
        return metadata.properties()
    default:
        throw RuntimeError.couldNotGetTypeInfo(type: type, kind: kind)
    }
}
