public protocol EmptyInitialiser {
    init()
}

public extension PropertyWrappedCodable where Self: EmptyInitialiser {
    init(nonWrappedPropertiesFrom decoder: Decoder) throws {
        self.init()
    }
}
