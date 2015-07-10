//
//  Swift1.2Ext.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation

extension Dictionary {
    init(_ elements: [Element]){
        self.init()
        for (k, v) in elements {
            self[k] = v
        }
    }
    
    func map<U>(transform: Value -> U) -> [Key : U] {
        return Dictionary<Key, U>(Swift.map(self, { (key, value) in (key, transform(value)) }))
    }
    
    func map<T : Hashable, U>(transform: (Key, Value) -> (T, U)) -> [T : U] {
        return Dictionary<T, U>(Swift.map(self, transform))
    }
    
    func filter(includeElement: Element -> Bool) -> [Key : Value] {
        return Dictionary(Swift.filter(self, includeElement))
    }
    
    func reduce<U>(initial: U, @noescape combine: (U, Element) -> U) -> U {
        return Swift.reduce(self, initial, combine)
    }
}


extension Array {
    func forEach(doThis: (element: T) -> Void) {
        for e in self {
            doThis(element: e)
        }
    }
}
