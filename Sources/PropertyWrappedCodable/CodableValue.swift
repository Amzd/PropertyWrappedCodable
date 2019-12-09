protocol CodableValueProtocol {
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws
}

@propertyWrapper public struct CodableValue<Value: Codable>: CodableValueProtocol {
    private class Holder<Value> {
        var value: Value?
        init(_ value: Value? = nil) {
            self.value = value
        }
    }
    
    public var wrappedValue: Value {
        get { return holder.value ?? { fatalError("Use inside PropertyWrappedCodable or FamilyCodable not Codable!") }() }
        set { holder = Holder(newValue) } // Create new holder so struct mutates
    }
    
    private var key: String?
    private var holder = Holder<Value>()
    
    // MARK: - Custom key
    
    public init(wrappedValue: Value, key: String) {
        self.key = key
        self.wrappedValue = wrappedValue
    }
    public init(key: String) {
        self.key = key
    }
    
    // MARK: - Infered key
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    public init() {}
    
    // MARK: - CodableValueProtocol
    
    func initValue(with label: String, from container: KeyedDecodingContainer<AnyCodingKey>) throws {
        // label always starts with an underscore
        assert(label.first == "_")
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        
        if holder.value == nil {
            holder.value = try container.decode(Value.self, forKey: codingKey)
        } else if let value = try? container.decode(Value.self, forKey: codingKey) {
            holder.value = value
        }
    }
    
    func encodeValue(with label: String, to container: inout KeyedEncodingContainer<AnyCodingKey>) throws {
        let codingKey = AnyCodingKey(stringValue: key ?? String(label.dropFirst()))
        try container.encode(wrappedValue, forKey: codingKey)
    }
}
