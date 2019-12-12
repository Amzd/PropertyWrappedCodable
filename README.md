# PropertyWrappedCodable

Nice syntax for defaults and custom keys with Codable using Property Wrappers and Mirror. 

**Note:** About 5x slower than normal Codable

```swift
// initialising 1000x takes ~ 0.046s
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
// initialising 1000x takes ~ 0.008s
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
    
    static var discriminatorKey = "type"
    
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

## Collection Decoding Strategy

```swift
public enum CollectionDecodingStrategy<V> {
    /// Replaces invalid elements with fallback value:
    /// ["This", null, "That"] -> ["This", "FallbackValue", "That"]
    /// This is the default with `nil` as fallback value if the collection uses an Optional type (eg: [Int?])
    case fallbackValue(V)
    /// Leaves out invalid elements:
    /// [1, 2, "3"] -> [1, 2]
    /// This is the default unless the collection uses an Optional type (eg: [Int?])
    /// Note: Throws when there is no collection! Use default if you don't want that.
    case lossy
}
```
Usage:

```swift
struct Example: PropertyWrappedCodable {
    // defaults to .lossy so failed decoding wont be shown
    @CodableCollection() var ids1: [Int]
    // same as ids1
    @CodableCollection(.lossy) var ids2: [Int]
    
    // defaults fallback to `nil`
    @CodableCollection() var ids3: [Int?]
    // same as ids3
    @CodableCollection(.fallbackValue(nil)) var ids4: [Int?]
    
    // falls back to 0 if decoding fails
    @CodableCollection(.fallbackValue(0)) var ids5: [Int]
    
    init(nonWrappedValuesFrom decoder: Decoder) throws { }
    
    // Optional:
    // If you want to report back that some objects are the wrong structure and couldn't be decoded you can do that like this:
    init(from decoder: Decoder) throws {
        try self.init(propertyWrappedValuesFrom: decoder)
        _ids1.failures.isEmpty ? () : Admin.sendReport("Failed to init some objects: \(_ids1.failures)")
    }
    
    // Optional:
    // If you want to expose the errors you can do this:
    var ids1Failures: [Error] {
        _ids1.failures
    }
}
```
```swift
let json = """
{
    "ids1" : [1, 2, "3"],
    "ids2" : [1, 2, "3"],
    "ids3" : [1, 2, "3"],
    "ids4" : [1, 2, "3"],
    "ids5" : [1, 2, "3"]
}
"""
let data = json.data(using: .utf8)!
let example = try decoder.decode(Example.self, from: data) 
print(example.ids1) // [1, 2]
print(example.ids2) // [1, 2]
print(example.ids3) // [1, 2, nil]
print(example.ids4) // [1, 2, nil]
print(example.ids5) // [1, 2, 0]
```
