# PropertyWrappedCodable

Nice syntax for defaults and custom keys with Codable using Property Wrappers and Mirror. 

**Note:** About 4x slower than normal Codable

```swift
struct WrappedExample: PropertyWrappedCodable {
    @CodableValue var name: String
    @CodableValue var id: String = "Default"
    @CodableValue var dog: String?
    @CodableValue(key: "is_active") var isActive: Bool
    
    init(nonWrappedValuesFrom decoder: Decoder) throws {}
}
```
vs

```swift

struct CodableExample: Codable {
    var name: String
    var id: String
    var dog: String
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case dog
        case isActive = "is_active"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = (try? container.decode(String.self, forKey: .id)) ?? "Default"
        dog = try container.decode(String.self, forKey: .dog)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
}
```
