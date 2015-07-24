//
//  TextGenerator.swift
//  FilterTest
//
//  Created by Jia Jing on 7/21/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import QuartzCore
import CoreText
import Dollar
import Argo
import ReactiveCocoa
import Cent


class TextGenerator: Updatable, Syncable, RenderGraph {
    private var _filter: Filter?
    let synced: Synced
    let animationSet: AnimationSet
    private let frameRate: Double = 30
    private var frameCount: Int = 0 {
        didSet {
            self.currTime.put(Double(self.frameCount) / self.frameRate)
        }
    }
    let graphs: [(GlyphFragment, Int)]
    private var currTime = MutableProperty(Double(0))
    var filter: Filter {
        return nil == _filter ? DummyFilter() : _filter!
    }
    
    init(eaglContext: EAGLContext, str: String, font: CTFont, frame: CGSize, animationSet: AnimationSet, synced: Synced){
        self.synced = synced
        self.animationSet = animationSet
        let option = [kCTFontAttributeName : font, kCTForegroundColorAttributeName: UIColor.whiteColor()] as [NSString : AnyObject]
        let attrString = CFAttributedStringCreate(kCFAllocatorDefault, str, option)
        let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPathCreateWithRect(CGRectMake(0, 0, frame.width, frame.height), nil)
        let ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, str.length), path, option)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo.ByteOrderDefault | CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let cgContext = CGBitmapContextCreate(nil, Int(frame.width), Int(frame.height), 8, 0, rgbColorSpace, bitmapInfo)
        let frags = drawGlyphFragment(eaglContext, cgContext, ctFrame, frame, getBounds(str, font, frame, ctFrame))
        self.graphs = Array(zip(frags, (0 ..< frags.count).map{animationSet.order.getIndex($0, count: frags.count)}))
        currTime.producer |> map($.curry <| AnimationStatus.gen <| animationSet <| frame)
            |> skip(1)
            |> start(next:onNewAnim)
    }
    
    private func onNewAnim(statusGen: CGSize -> Int -> AnimationStatus){
        let animated: [ConcreteFilter] = self.graphs.map {
            let status = statusGen($0.1.size)($1)
            return ConcreteImage(outputImage: animateGlyphFragment($0, status))
        }
        self._filter = sum(animated)
        self.synced.notifyUpdated()
    }
    
    func update() {
        self.frameCount++
    }
}