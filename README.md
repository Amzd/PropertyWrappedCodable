# PropertyWrappedCodable

Nice syntax for defaults and custom keys with Codable using Property Wrappers and Mirror. 

**Note:** About 4x slower than normal Codable

```swift
// initialising 1000x takes ~ 0.04s
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
// initialising 1000x takes ~ 0.01s
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

## FamilyCodable

Let the data decide the type

```swift
class Pet: FamilyCodable {
    @CodableValue() var name: String
    @CodableValue() private var type: String
    
    required init(nonWrappedValuesFrom decoder: Decoder) throws { }
    
    static var discriminatorKey: CodingKey = AnyCodingKey(stringValue: "type")
    
    final class func familyMember(for value: String) throws -> Codable.Type {
        switch value {
        case "Cat": return Cat.self
        case "Dog": return Dog.self
        default: return Pet.self
        }
    }
}

class Cat: Pet {
    @CodableValue() var lives: Int
}

class Dog: Pet {
    func fetch() { }
}
```
```swift
let petsJson = """
[{ "type": "Cat", "name": "Garfield", "lives": 9 },
 { "type": "Dog", "name": "Pluto" }]
"""
let petsData = petsJson.data(using: .utf8)!
let pets = try decoder.decode([Pet].self, from: petsData) // [Cat, Dog]
```
