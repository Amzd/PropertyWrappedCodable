#if canImport(EchoMirror) || canImport(Echo)
    #if canImport(EchoMirror)
        @testable import EchoMirror
    #elseif canImport(Echo)
        @testable import Echo
        typealias EchoMirror = Echo.Mirror
    #endif

    @testable import PropertyWrappedCodable

    public protocol EchoPropertyWrappedCodable: Codable {
        /// Warning: Property wrapped values arent available here yet!
        init(nonWrappedPropertiesFrom decoder: Decoder) throws
    }

    public extension EchoPropertyWrappedCodable {
        init(from decoder: Decoder) throws {
            try self.init(wrappedPropertiesFrom: decoder)
        }
        
        /// Call this when you override `init(from:)`
        init(wrappedPropertiesFrom decoder: Decoder) throws {
            try self.init(nonWrappedPropertiesFrom: decoder)
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            
            let mirror = EchoMirror(reflecting: self)
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
#endif
