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
import Runes

class PlayerController: GLKViewController {
    @IBOutlet weak var glkView: GLKView!
    @IBOutlet weak var imageView: UIImageView!
    private let layerController = LayerController()
    private let renderer = Renderer()
    var backgroundVideoPath: String! = nil { didSet { if let path = backgroundVideoPath { self.layerController.backgroundPaths = [path] }}}
//    var graphs: [GlyphFragment]?
    var textGen: TextGenerator?
    override func viewDidLoad() {
        var foobar: Foobar? = Foobar()
        foobar = nil
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
        
//        let start = NSDate.timeIntervalSinceReferenceDate()
//        let f = fraction("11%")
//        println("fractionTest 11% = \(f)")
////        let str = "一二三四五六七八九十九八七六五四三二一"
//        let str = "一二三四五六七"//八九十九八七六五四三二一"
//        let font = CTFontCreateWithName("PingFang-SC-Medium", 40, nil)
//        let frame = CGSize(width: 500, height: 300)
//        let animationSet: AnimationSet? = JSONFromFile("json", "anim") >>- decode
//        println("animationSet = \(animationSet)")
//
//        let textLayer = layer {
//            let textGenerator = TextGenerator(eaglContext: self.renderer.eaglContext, str: str, font: font, frame: frame, animationSet: animationSet!, synced: $0.0.syncManager.newSynced())
//            println("outside init")
//            $0.0.updateManager.registerUpdatable(textGenerator)
////            self.graphs = textGenerator.graphs
//            self.textGen = textGenerator
//            return pBackground("CISourceOverCompositing", kCIInputImageKey) <| textGenerator
////
////            return textGenerator
////            return multiply(textGenerator)
//        }
//        self.layerController.vfx.append(textLayer)
        
        
//        renderer.render <| layerController
//        renderer.next()
//        renderer.onDraw = {
////            if let g = self.graphs {
////                g.map{
////                    self.renderer.ciContext.drawImage($0, inRect: $1, fromRect: $1)
////                }
////                g.map{"drawing fake at \($0.extent()) rect \($1)"}.map(println)
////            }
//            
//            if let image = (self.textGen?.filter as? ConcreteFilter)?.outputImage {
//                self.renderer.ciContext.drawImage(image, inRect: image.extent(), fromRect: image.extent())
//            }
//        }
        //        var option = [kCTFontAttributeName : font] as [NSString : AnyObject]
//        let attrString = CFAttributedStringCreate(kCFAllocatorDefault, str, option)
//        let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
//        let path = CGPathCreateWithRect(CGRectMake(0, 0, frame.width, frame.height), nil)
//        let ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, str.length), path, nil)
//        let bounds = getBounds(str, font, frame, ctFrame)
//
//        
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        var bitmapInfo = CGBitmapInfo.ByteOrderDefault
//        bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
//        let cgContext = CGBitmapContextCreate(nil, Int(frame.width), Int(frame.height), 8, 0, rgbColorSpace!, bitmapInfo)!
//        let graphs = drawGlyphFragment(cgContext, ctFrame, frame, bounds)
//        println("str = \(str)")
//        Array(zip(str, bounds)).map{println("bounds for \($0) is \($1)")}
//        println("glyph fragments")
//        
//        Array(zip(str, graphs)).map{println("fragment for \($0) extent = \($1.0.extent())")}
//        println("time = \(NSDate.timeIntervalSinceReferenceDate() - start)")
        
//        let totalFrame = getTextImage(cgContext,str, font, ctFrame, frame)
//        renderer.onDraw = {
////            self.renderer.ciContext.drawImage(totalFrame, inRect: totalFrame.extent(), fromRect: totalFrame.extent())
//            graphs.map{self.renderer.ciContext.drawImage($0.0, inRect: $0.1, fromRect: $0.1)}
//        }
    }
    
    func mp4(name: String) -> String {
        return NSBundle.mainBundle().pathForResource(name, ofType: "mp4")!
    }
    
}

class Foobar {
    let msg = MutableProperty("init")
    let echo = MutableProperty("echo start")
    init(){
        msg.producer |> start(next:{[unowned self] in self.log($0)})
        echo.producer |> start(next:{println("echo \($0)")})
    }
    func log(msg: String){
        println(msg)
    }
    deinit{
        println("deinit")
    }
}