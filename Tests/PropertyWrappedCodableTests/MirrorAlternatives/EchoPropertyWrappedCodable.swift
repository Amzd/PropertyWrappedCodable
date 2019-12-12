@testable import Echo
@testable import PropertyWrappedCodable

public protocol EchoPropertyWrappedCodable: Codable {
    /// Warning: Property wrapped values arent available here yet!
    init(nonWrappedValuesFrom decoder: Decoder) throws
}

public extension EchoPropertyWrappedCodable {
    init(from decoder: Decoder) throws {
        try self.init(propertyWrappedValuesFrom: decoder)
    }
    
    /// Call this when you override `init(from:)`
    init(propertyWrappedValuesFrom decoder: Decoder) throws {
        try self.init(nonWrappedValuesFrom: decoder)
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            let value = child.value as? CodableValueProtocol
            try value?.initValue(with: child.label!, from: container)
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
