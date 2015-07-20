//
//  PlayerController.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import GLKit
import CoreImage
import Argo
import Dollar
import ReactiveCocoa

class PlayerController: GLKViewController {
    @IBOutlet weak var glkView: GLKView!
    @IBOutlet weak var imageView: UIImageView!
    private let layerController = LayerController()
    private let renderer = Renderer()
    var backgroundVideoPath: String! = nil { didSet { if let path = backgroundVideoPath { self.layerController.backgroundPaths = [path] }}}
    override func viewDidLoad() {
//        self.imageView.image = hueImage(imageView.bounds.width, imageView.bounds.height)
        self.glkView.context = renderer.eaglContext
        self.backgroundVideoPath = mp4("laser")
//        self.layerController.backgroundEffect.append(immutable <| boxBlur())
//        layerController.backgroundEffect.append <| immutable <| gaussian()
//        layerController.regionLayer.append <| videoLayer <| mp4 <| "Comp 1_2"
//        self.layerController.regionEffect.append(immutable(boxBlur(20)))
//        self.layerController.regionLayer.append(videoLayer(mp4("Comp 1_2")))
//        self.layerController.vfx.append(mask(toonLayer(0))(maskLayer: videoLayer(mp4("Comp 1_2"))))
//        self.layerController.vfx.append(toonLayerConcrete(0))
//        self.layerController.vfx.append(maskedBlurLayer(mp4("Comp 1_2")))
//        self.layerController.vfx.append(normalLayer(mp4("Comp 1_1"), mp4("Comp 1_2")))
//        self.layerController.vfx.append(concrete(glassDistortionLayer(mp4("Comp 1_2")))(backgroundSelector: 1))
//        self.layerController.vfx.append(glassDistortionLayerConcrete(mp4("Comp 1_2"), mp4("Comp 1_1"), 0))
//        self.layerController.vfx.append(glassDistortionLayer(mp4("Comp 1_2")))
        renderer.next <| renderer.render <| layerController
        
        let start = NSDate.timeIntervalSinceReferenceDate()
        let str = "测试我是一个句子，长度不超过20个字"
        let font = CTFontCreateWithName("PingFang-SC-Medium", 40, nil)
        let frame = CGSize(width: 400, height: 400)
        var option = [kCTFontAttributeName : font] as [NSString : AnyObject]
        let attrString = CFAttributedStringCreate(kCFAllocatorDefault, str, option)
        let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPathCreateWithRect(CGRectMake(0, 0, frame.width, frame.height), nil)
        let ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, str.length), path, nil)
        let bounds = getBounds(str, font, frame, ctFrame)
        
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo.ByteOrderDefault
        bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        //[CGImageAlphaInfo.PremultipliedLast].map{$0.rawValue}.reduce(CGBitmapInfo.ByteOrderDefault){$0 | $1}
        let cgContext = CGBitmapContextCreate(nil, Int(frame.width), Int(frame.height), 8, 0, rgbColorSpace!, bitmapInfo)!
        let graphs = drawGlyphFragment(cgContext, ctFrame, frame, bounds)
        println("str = \(str)")
        Array(zip(str, bounds)).map{println("bounds for \($0) is \($1)")}
        println("glyph fragments")
        
        Array(zip(str, graphs)).map{println("fragment for \($0) extent = \($1.0.extent())")}
        println("time = \(NSDate.timeIntervalSinceReferenceDate() - start)")
        
        let totalFrame = getTextImage(cgContext,str, font, ctFrame, frame)
        renderer.onDraw = {
            self.renderer.ciContext.drawImage(totalFrame, inRect: totalFrame.extent(), fromRect: totalFrame.extent())
            graphs.map{self.renderer.ciContext.drawImage($0.0, inRect: $0.1, fromRect: $0.1)}
        }
    }
    
    func mp4(name: String) -> String {
        return NSBundle.mainBundle().pathForResource(name, ofType: "mp4")!
    }
    
}