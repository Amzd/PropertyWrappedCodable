public protocol FamilyCodable: PropertyWrappedCodable {
    associatedtype DiscriminatorKey: CodingKeyConvertable
    associatedtype DiscriminatorValue: Codable
    /// Returns a family member (subclass) for discriminator value.
    ///  Throw when the discriminator is wrong. This will stop the init.
    ///  Return Self.self if you want to init just the Family class rather than a member class.
    static func familyMember(for value: DiscriminatorValue) throws -> Codable.Type
    /// The key for the family discriminator value
    static var discriminatorKey: DiscriminatorKey { get }
}

public enum FamilyCodableError: Error {
    /// Make sure the returned family member is a subclass of the family class
    case familyMemberIsNotASubclass
}

public extension FamilyCodable {
    init(from decoder: Decoder) throws {
        try self.init(familyFrom: decoder)
    }
    
    /// Call this when you override `init(from:)`
    init(familyFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let key = Self.discriminatorKey.toAnyCodingKey()
        let discriminator = try container.decode(DiscriminatorValue.self, forKey: key)
        let member = try Self.familyMember(for: discriminator)
        if !(member.self is Self.Type) {
            // not a subclass
            throw FamilyCodableError.familyMemberIsNotASubclass
        } else if member.self != Self.self {
            // subclass
            self = try member.init(from: decoder) as! Self
        } else {
            // family class
            try self.init(wrappedPropertiesFrom: decoder)
        }
    }
}

extension Array where Element: FamilyCodable {
    /// Simple compactMap cast to type
    public func ofType<Member>(_ memberType: Member.Type) -> [Member] {
        compactMap { $0 as? Member }
    }
}
