//
//  JsonTest.swift
//  FilterTest
//
//  Created by Jia Jing on 7/16/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Argo
import Runes
import Foundation
import Curry

struct AlphaAnim: Decodable {
    let from: Double
    let to: Double
    let duration: Double?
    static func alphaAnim(from: Double, to: Double, duration: Double?) -> AlphaAnim{
        return AlphaAnim(from: from, to: to, duration: duration)
    }
    static func decode(j: JSON) -> Decoded<AlphaAnim> {
        return  curry <| alphaAnim
                <^> j <| "from"
                <*> j <| "to"
                <*> j <|? "duration"
    }
}

enum FractionType {case Base, PBase}
typealias BFraction = (type: FractionType, value: Double)
func bFraction(str: String) -> BFraction {
    let type = 
}
func fraction(str: String) -> Double {
    return 0
}
struct TranslationAnim {
    let fromX: BFraction
    let toX: BFraction
    let fromY: BFraction
    let toY: BFraction
    let duration: Double?
    
}


