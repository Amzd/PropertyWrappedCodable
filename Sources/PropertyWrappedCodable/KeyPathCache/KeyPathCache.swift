////
////  KeyPathCache.swift
////  CEcho
////
////  Created by Casper Zandbergen on 20/01/2020.
////
//
//import Foundation
//
//typealias CodableValueKeyPath = AnyKeyPath // KeyPath<Any, CodableValueProtocol>
//
//extension PropertyWrappedCodable {
//    var keyPaths: [String: CodableValueKeyPath] {
//        return KeyPathCache.keyPaths(for: self)
//    }
//    
//    fileprivate static var identifier: ObjectIdentifier {
//        return ObjectIdentifier(Self.self)
//    }
//  
//    fileprivate subscript(checkedMirrorDescendant key: String) -> Any {
//        let hashedType = ObjectIdentifier(type(of: self))
//        return KeyPathCache.mirrors[hashedType]!.descendant(key)!
//    }
//}
//
//class KeyPathCache {
//    fileprivate static var mirrors: [ObjectIdentifier: Mirror] = .init()
//    
//    private static var items: [ObjectIdentifier: [String: CodableValueKeyPath]] = .init()
//    
//    static func keyPaths<C: PropertyWrappedCodable>(for codable: C) -> [String: CodableValueKeyPath] {
//        return items[C.identifier] ?? register(codable)
//    }
//    
//    private static func register<C: PropertyWrappedCodable>(_ codable: C) -> [String: CodableValueKeyPath] {
//        let id = C.identifier
//        
//        if mirrors.keys.contains(id) {
//            fatalError("This shouldnt happen")
//            return [:]
//        }
//        
//        var mirror: Mirror? = Mirror(reflecting: codable)
//        
//        mirrors[id] = mirror
//        
//        var keyPathsDictionary: [String: CodableValueKeyPath] = .init()
//        
//        while let currentMirror = mirror {
//            for case (let key?, _) in currentMirror.children {
//                keyPathsDictionary[key] = \C.[checkedMirrorDescendant: key] as PartialKeyPath
//            }
//            mirror = currentMirror.superclassMirror
//        }
//        
//        
//        
//        items[id] = keyPathsDictionary
//        
//        return keyPathsDictionary
//    }
//}
//
