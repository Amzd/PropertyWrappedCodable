//@testable import Reflection
//@testable import PropertyWrappedCodable
//
//public protocol ReflectionPropertyWrappedCodable: Codable {
//    /// Warning: Property wrapped values arent available here yet!
//    init(nonWrappedPropertiesFrom decoder: Decoder) throws
//}
//
//public extension ReflectionPropertyWrappedCodable {
//    init(from decoder: Decoder) throws {
//        try self.init(wrappedPropertiesFrom: decoder)
//    }
//
//    /// Call this when you override `init(from:)`
//    init(wrappedPropertiesFrom decoder: Decoder) throws {
//        try self.init(nonWrappedPropertiesFrom: decoder)
//        let container = try decoder.container(keyedBy: AnyCodingKey.self)
//
//        let children = try properties(self)
//        for child in children {
//            let value = child.value as? CodableValueProtocol
//            try value?.initValue(with: child.key, from: container)
//        }
//    }
//
//    func encode(to encoder: Encoder) throws {
//        try encode(propertyWrappedValuesTo: encoder)
//    }
//    
//    /// Call this when you override `encode(to:)`
//    func encode(propertyWrappedValuesTo encoder: Encoder) throws {
//        fatalError()
//    }
//}
