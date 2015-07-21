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
import Cent
import Dollar
import QuartzCore

protocol DurationProv {
    var duration: Double? {get}
    var delay: Double  { get }
    var interpolator: Interpolator? { get }
}


private func forTime(durationProv: DurationProv, time: Double, pDuration: Double) -> Double {
    let t = (time - durationProv.delay) / (durationProv.duration ?? pDuration - durationProv.delay)
    return max(0.0, t)
}

private func interpolate(durationProv: DurationProv, ratio: Double, pInterpolator: Interpolator) -> Double {
    return durationProv.interpolator?(ratio) ?? pInterpolator(ratio)
}

private func ratioForTimeIn(time: Double, pDuration: Double, pInterpolator: Interpolator, durationProv: DurationProv) -> Double {
    let r = forTime(durationProv, time, pDuration)
    return interpolate(durationProv, max(min(r, 1.0), 0.0), pInterpolator)
}

private func getTime(animSet: AnimationSet, time: Double, id: Int) -> Double {
    return animSet.interval * Double(id) + time
}

struct AlphaAnim: Decodable, DurationProv {
    let from: Double
    let to: Double
    let duration: Double?
    let delay: Double
    let interpolator: Interpolator?
    static func alphaAnim(from: Double, to: Double, duration: Double?, _delay: Double?, _interpolator: String?) -> AlphaAnim{
        return AlphaAnim(from: from, to: to, duration: duration, delay: _delay ?? 0, interpolator: nil == _interpolator ? nil : getInterpolator(_interpolator))
    }
    static func decode(j: JSON) -> Decoded<AlphaAnim> {
        return  $.curry <| alphaAnim
                <^> j <| "from"
                <*> j <| "to"
                <*> j <|? "duration"
                <*> j <|? "delay"
                <*> j <|? "interpolator"
    }
    
    static let Identity: Double = 1
    func getValue(ratio: Double) -> Double {
        return $.curry <| atRatio <| from <| to <| ratio
    }
}

enum FractionType: String {
    case Base = "Base", PBase = "PBase"
    static func parse(str: String) -> FractionType{
        return (str =~ ".*[pP]$") ? .PBase : .Base
    }
    func process(str: String) -> String {
        if self == PBase {
            return str.substringWithRange(Range<String.Index>(start: str.startIndex, end: str.endIndex.predecessor()))
        }
        return str
    }
}

enum Order: String{
    case Asc = "ascending", Desc = "descending", Rnd = "random"
    static func parse(str: String?) -> Order {
        return (str >>- { Order(rawValue: $0) }) ?? Asc
    }
    func getIndex(id: Int, count: Int) -> Int{
        switch self {
        case Asc:   return id
        case Desc:  return count - id
        case Rnd:   return Int(arc4random_uniform(UInt32(count)))
        }
    }
}
typealias BFraction = (type: FractionType, value: Double)

private func bFraction(str: String?) -> BFraction{
    if nil == str { return (FractionType.Base, 0)}
    let type = FractionType.parse(str!)
    let a = (type, fraction(type.process(str!)))
    println("created fraction from \(str) value = \(a.1)")
    return a
}

func fraction(str: String) -> Double {
    let (base: Double, doubleStr) = (str =~ ".*%$") ? (100, str[0 ..< str.length]) : (1, str)
    return (doubleStr as NSString).doubleValue / base
}

private func fractionGetX(size: CGSize, pSize: CGSize, frac: BFraction) -> Double {
    return Double((frac.type == .Base ? size : pSize).width) * frac.value
}

private func fractionGetY(size: CGSize, pSize: CGSize, frac: BFraction) -> Double {
    return Double((frac.type == .Base ? size : pSize).height) * frac.value
}

private func atRatio(lp: Double, rp: Double, ratio: Double) -> Double {
    return lp * (1.0 - ratio) + rp * ratio
}

private func effective(time: Double, pDuration: Double, durationProv: DurationProv) -> Bool{
    return time >= durationProv.delay && time <= (durationProv.delay + (durationProv.duration ?? pDuration))
}

private func currElement<T: DurationProv>(animSet: AnimationSet, time: Double, array: [T]) -> T? {
    switch array.count {
    case 0, 1: return array.first
    default:
        let hit = $.curry <| effective <| time <| animSet.duration
        return array[1 ..< array.count].reduce(array[0]){hit($1) ? $1 : $0}
    }
}

struct TranslationAnim: Decodable, DurationProv{
    
    let fromX: BFraction
    let toX: BFraction
    let fromY: BFraction
    let toY: BFraction
    let duration: Double?
    let delay: Double
    let interpolator: Interpolator?
    static func translationAnim(fromX: String?, toX: String?, fromY: String?, toY: String?, duration: Double?, _delay: Double?, _interpolator: String?) -> TranslationAnim {
        return TranslationAnim(
            fromX           : bFraction(fromX),
            toX             : bFraction(toX),
            fromY           : bFraction(fromY),
            toY             : bFraction(toY),
            duration        : duration,
            delay           : _delay ?? 0,
            interpolator    : nil == _interpolator ? nil : getInterpolator(_interpolator)
        )
    }
    
    static func decode(j: JSON) -> Decoded<TranslationAnim> {
        return $.curry <| translationAnim
               <^> j <|? "fromX"
               <*> j <|? "toX"
               <*> j <|? "fromY"
               <*> j <|? "toY"
               <*> j <|? "duration"
               <*> j <|? "delay"
               <*> j <|? "interpolator"
    }
    
    static let Identity: CGPoint = CGPoint(x: 0, y: 0)
    func getValue(ratio: Double, size: CGSize, pSize: CGSize) -> CGPoint {
        let getX = $.curry <| fractionGetX <| size <| pSize
        let getY = $.curry <| fractionGetY <| size <| pSize
        let xAt = $.curry <| atRatio <| getX(fromX) <| getX(toX)
        let yAt = $.curry <| atRatio <| getY(fromY) <| getY(toY)
        return CGPoint(x: xAt(ratio), y: yAt(ratio))
    }
    
}

enum AnimationEndType {
    case None,Repeat, Fill
    static func parse(str: String?) -> AnimationEndType {
        if let s = str?.lowercaseString {
            switch s {
            case "repeat": return .Repeat
            case "fill": return .Fill
            default: return .None
            }
        }
        return .None
    }
}

typealias Interpolator = (Double) -> Double

func getInterpolator(identifier: String?) -> Interpolator {
//    return {sqrt($0)}
    return {$0}
}

struct AnimationSet: Decodable {
    let order: Order
    let endType: AnimationEndType
    let interpolator: Interpolator
    let duration: Double
    let interval: Double
    let alpha: [AlphaAnim]
    let translation: [TranslationAnim]
    static func animationSet(_order: String?, endType: String?, _interpolator: String?, _duration: Double?, _interval: Double?, _alpha: [AlphaAnim]?, _translation: [TranslationAnim]?) -> AnimationSet{
        let duration: Double
        let alpha = _alpha ?? []
        let translation = _translation ?? []
        if nil == _duration {
            let map = {($0 as DurationProv).delay + (($0 as DurationProv).duration ?? 0)}
            duration = (alpha.map{ map($0) } + translation.map{ map($0) }).reduce(0, combine: max)
        } else {
            duration = _duration!
        }
        return AnimationSet(
            order           : Order.parse(_order),
            endType         : AnimationEndType.parse(endType),
            interpolator    : getInterpolator(_interpolator),
            duration        : duration,
            interval        : _interval ?? 0,
            alpha           : alpha,
            translation     : translation)
    }
    static func decode(j: JSON) -> Decoded<AnimationSet> {
        return $.curry <| animationSet
            <^> j <|? "order"
            <*> j <|? "end"
            <*> j <|? "interpolator"
            <*> j <|? "duration"
            <*> j <|? "interval"
            <*> ***(j <||? "alpha")
            <*> ***(j <||? "translation")
    }
}


struct AnimationStatus {
    let visible: Bool
    let translation: CGPoint
    let alpha: Double
    
    static func gen(animSet: AnimationSet, pSize: CGSize, time: Double, size: CGSize, id: Int) -> AnimationStatus {
        let _t = getTime(animSet, time, id)
        let t: Double
        if _t > animSet.duration {
            switch animSet.endType {
            case .None: return Invisible
            case .Fill: t = animSet.duration
            case .Repeat: t = _t % animSet.duration
            }
        } else {
            t = _t
        }
        let getRatio = $.curry <| ratioForTimeIn <| t <| animSet.duration <| animSet.interpolator
        let currTrans = currElement(animSet, t, animSet.translation)
        let trans = nil == currTrans ? TranslationAnim.Identity : currTrans!.getValue(getRatio(currTrans!), size: size, pSize: pSize)
        let currAlpha = currElement(animSet, t, animSet.alpha)
        let alpha = nil == currAlpha ? AlphaAnim.Identity : currAlpha!.getValue(getRatio(currAlpha!))
        return AnimationStatus(visible: true, translation: trans, alpha: alpha)
    }
    
    static var Invisible: AnimationStatus {
        return AnimationStatus(visible: false, translation: TranslationAnim.Identity, alpha: AlphaAnim.Identity)
    }
}

func JSONFromFile(type: String, file: String) -> AnyObject? {
    return NSBundle.mainBundle().pathForResource(file, ofType: type)
        >>- { NSData(contentsOfFile: $0) }
        >>- { NSJSONSerialization.JSONObjectWithData($0, options: nil, error: nil) }
}


prefix operator *** {
}


prefix func *** <T>(t: T) -> T {
    println("logger \(t)")
    return t
}
