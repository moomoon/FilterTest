//
//  Renderer.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import Box
import AVFoundation
import CoreImage
import Argo
import ReactiveCocoa

class Renderer {
    private var renderGraph: RenderGraph? = nil {
        didSet{
            renderGraphContext.onSynchronize = {
                // draw here
//                println("**********************")
                let startComp = NSDate.timeIntervalSinceReferenceDate()
                if let ciImage = (self.renderGraph?.filter as? ConcreteFilter)?.outputImage {
                    let startRender = NSDate.timeIntervalSinceReferenceDate()
//                    println("composing filter cost \(startRender - startComp)")
                    self.ciContext.drawImage(ciImage, inRect: ciImage.extent(), fromRect: ciImage.extent())
                    let finishRender = NSDate.timeIntervalSinceReferenceDate()
//                    println("render cost \(finishRender - startRender)")
//                    println("total frame time \(finishRender - self.t)")
                    self.t = finishRender
                }
                self.onDraw?()
            }
        }
    }
    private var t = NSDate.timeIntervalSinceReferenceDate()
    private let renderGraphContext: RenderGraphContext
    let eaglContext: EAGLContext
    let ciContext: CIContext
    var onDraw: (()->Void)?
    init(){
        //set fps here
        let context = RenderGraphContext()
        self.renderGraphContext = context
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        eaglContext.multiThreaded = true
        let option = [kCIContextWorkingColorSpace: NSNull.new()]
        let ciContext = CIContext(EAGLContext: eaglContext, options: option)
        self.eaglContext = eaglContext
        self.ciContext = ciContext
    }
    
    func render(mainLayer: MainRenderLayer, background: [RenderLayer]){
        self.renderGraphContext.clear()
        let backgroundGraph = background.map{ $0.createGraph(self.renderGraphContext, background:[])}
        println("created background render graphs")
        self.renderGraph = mainLayer.createGraph(self.renderGraphContext, background: backgroundGraph)
        println("created renderGraphs")
    }
    
    func render(controller: LayerController){
        render(controller.mainLayer, background: controller.background)
    }
    
    func next(){
        self.renderGraphContext.updateManager.next()
    }
    
}

class VideoGenerator: SimpleUpdatable, Syncable, RenderGraph {
    static let DecodeOptions = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
    let path: String
    let synced: Synced
    var filter: Filter = DummyFilter()
    private var output: AVAssetReaderOutput! = nil
    private var avAssetReader: AVAssetReader! = nil
    private var cvBuffer: CVPixelBufferRef?
    private let asset: AVAsset
    init(path: String, synced: Synced) {
        self.synced = synced
        self.path = path
        let movieUrl = NSURL(fileURLWithPath: path)
        let avAsset = AVURLAsset(URL: movieUrl, options: nil)!
        self.asset = avAsset
        createReader()
    }
    
    func createReader(){
        var error : NSError?
        let avAssetReader = AVAssetReader(asset: asset, error: &error)!
        for track in self.asset.tracks {
            if let track = track as? AVAssetTrack {
                if track.mediaType != AVMediaTypeVideo { continue }
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: VideoGenerator.DecodeOptions)!
                avAssetReader.addOutput(output)
                self.output = output
                break
            }
        }
        avAssetReader.startReading()
        self.avAssetReader = avAssetReader
    }
    
    func update() {
        while(!advance()){}
        emit()
    }
    func advance() -> Bool {
        if let cmSampleBuffer = self.output.copyNextSampleBuffer() {
            if CMSampleBufferDataIsReady(cmSampleBuffer) == 0 { return false }
            if let cvImageBufferRef = CMSampleBufferGetImageBuffer(cmSampleBuffer){
                self.cvBuffer = cvImageBufferRef
                let ciImage = CIImage(CVPixelBuffer: cvImageBufferRef)
                self.filter = ConcreteImage(outputImage: ciImage)
            }
            return true
        } else {
            self.avAssetReader.cancelReading()
            createReader()
            return advance()
        }
    }
    func emit() {
        self.synced.notifyUpdated()
    }
    
}

func video(path: String, context: RenderGraphContext) -> RenderGraph {
    let gen = VideoGenerator(path: path, synced: context.syncManager.newSynced())
    context.updateManager.registerUpdatable(gen)
    return gen
}

protocol RenderGraph {
    var filter: Filter { get }
}

struct ImmutableGraph: RenderGraph {
    let filter: Filter
}

struct DelegateGraphGroup: RenderGraph{
    let subGraphs: [RenderGraph]
    let delegate: ([Filter]) -> ConcreteFilter
    var filter: Filter{ return delegate(subGraphs.map{$0.filter})}
}

func delegateGraphGroup(subGraphs: [RenderGraph], delegate:([Filter]) -> ConcreteFilter) -> DelegateGraphGroup {
    return DelegateGraphGroup(subGraphs: subGraphs, delegate: delegate)
}
func combine(subGraphs: [RenderGraph]) -> RenderGraph{
    subGraphs.map{println("combining \($0)")}
    let g = DelegateGraphGroup(subGraphs: subGraphs, delegate: FilterGroup.reduceFilters)
    println("finished creating DelegateGroup")
    return g
}

func combine(a: RenderGraph)(_ b: RenderGraph) -> RenderGraph{
    return combine([b, a])
}

//func <|<F, T> (lhs: () -> (), rhs: F -> T) -> F -> T {
//    return { let t = rhs($0); lhs(); return t }
//}

func <| <F, T>(lhs: F -> T, rhs: F) ->T {
    return lhs(rhs)
}

func <| <A, B, C>(lhs: B -> C, rhs: A -> B) -> A -> C{
    return { lhs(rhs($0)) }
}

func <| (lhs: RenderGraph, rhs: RenderGraph) -> RenderGraph{
    return combine(lhs)(rhs)
}

func <| (lhs: Filter, rhs: RenderGraph) -> RenderGraph {
    return combine(immutable(lhs))(rhs)
}


func <| <A> (lhs: RenderGraph, rhs: A -> RenderGraph) -> A -> RenderGraph{
    return { lhs <| rhs($0)}
}

func <| <A> (lhs: Filter, rhs: A -> RenderGraph) -> A -> RenderGraph{
    return {lhs <| rhs($0)}
}

//func <| <A> (lhs: Filter, rhs: A -> Filter) -> A -> RenderGraph{
//    return {lhs <| rhs($0)}
//}
//
//func <| <A> (lhs: RenderGraph, rhs: A -> Filter) -> A -> RenderGraph{
//    return {lhs <| rhs($0)}
//}
//
//func |> <F, T> (lhs: F, rhs: F -> T) -> T {
//    return rhs(lhs)
//}

//func |> <A, B, C> (lhs: A -> B, rhs: B -> C) -> A -> C {
//    return { rhs(lhs($0)) }
//}

func |> (lhs: RenderGraph, rhs: RenderGraph) -> RenderGraph {
    return combine <| rhs <| lhs
}

func |> (lhs: RenderGraph, rhs: Filter) -> RenderGraph {
    return immutable <| rhs <| lhs
}









func monoEdge(level: Int)(graph: RenderGraph) -> RenderGraph {
    return [0...level].reduce(monoEdge(graph)){ multiply <| monoEdge <| $0.0 <| $0.0 }
}

func glassDistortion(texture: RenderGraph) -> RenderGraph {
    return pInput("CIGlassDistortion","inputTexture") <| texture
}

func mask(input: RenderGraph, mask: RenderGraph) -> RenderGraph {
    return pBackground("CIBlendWithMask", kCIInputImageKey, kCIInputMaskImageKey) <| input <| mask
}

func multiply(graph: RenderGraph) -> RenderGraph {
    return pBackground("CIMultiplyCompositing", kCIInputImageKey) <| graph
}

func alphaCompose(graph: RenderGraph) -> RenderGraph {
    return pBackground("CIBlendWithAlphaMask", kCIInputImageKey, kCIInputMaskImageKey) <| graph <| graph
}

func monoEdge(graph: RenderGraph) -> RenderGraph {
    return graph |> edges |> mono |> invert
}


func maskedBlur(mask: RenderGraph) -> RenderGraph {
    return maskedBlur() <| mask
}


class RenderGraphContext{
    let syncManager: SynchronizedUpon
    let updateManager: UpdateManager
    private let _onSynchronized: MutableBox<(() -> Void)?>
    var onSynchronize: (() -> Void)? {
        get{ return _onSynchronized.value }
        set(newValue){_onSynchronized.value = newValue }
    }
    init(){
        let onSynchronized = MutableBox<(() -> Void)?>(nil)
        let updateManager = UpdateManager()
        var t = NSDate.timeIntervalSinceReferenceDate()
        let syncManager = SynchronizedUpon{
            let finishDecode = NSDate.timeIntervalSinceReferenceDate()
//            println("decode cost \(finishDecode - t)") 
            onSynchronized.value?()
            t = NSDate.timeIntervalSinceReferenceDate()
            updateManager.next()
        }
        self.updateManager = updateManager
        self.syncManager = syncManager
        self._onSynchronized = onSynchronized
    }
    func clear(){}
}

