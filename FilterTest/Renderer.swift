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

class Renderer {
    private var renderGraph: RenderGraph? = nil {
        didSet{
            renderGraphContext.onSynchronize = {
                // draw here
                println("**********************")
                if let ciImage = (self.renderGraph?.filter as? ConcreteFilter)?.outputImage {
                    self.ciContext.drawImage(ciImage, inRect: ciImage.extent(), fromRect: ciImage.extent())
                    
                }
                self.onDraw?()
            }
        }
    }
    private let renderGraphContext: RenderGraphContext
    let eaglContext: EAGLContext
    private let ciContext: CIContext
    var onDraw: (()->Void)?
    init(){
        //set fps here
        let context = RenderGraphContext()
        self.renderGraphContext = context
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        eaglContext.multiThreaded = true
        let ciContext = CIContext(EAGLContext: eaglContext)
        self.eaglContext = eaglContext
        self.ciContext = ciContext
    }
    
    func render(mainLayer: MainRenderLayer, background: [RenderLayer]){
        self.renderGraphContext.clear()
        let backgroundGraph = background.map{ $0.createGraph(self.renderGraphContext, background:[])}
        self.renderGraph = mainLayer.createGraph(self.renderGraphContext, background: backgroundGraph)
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
    return DelegateGraphGroup(subGraphs: subGraphs, delegate: FilterGroup.reduceFilters)
}

func combine(graphs: RenderGraph...) -> RenderGraph {
    return combine(graphs)
}

func monoEdge(graph: RenderGraph)(level: Int) -> RenderGraph {
    return [0...level].reduce(monoEdge(graph)){multiplyConcrete(monoEdge($0.0))(rhs: $0.0)}
}

func glassDistortion(input: RenderGraph) -> RenderGraph {
    return combine(input, immutable(glassDistortionAddTexture()))
}

func mask(input: RenderGraph)(mask: RenderGraph) -> RenderGraph {
    return combine(input, combine(mask, immutable(BlendWithMaskAddMask())))
}

func multiply(graph: RenderGraph) -> RenderGraph {
    return combine(graph, immutable(MultiplyCompositingAddInput()))
}

func multiplyConcrete (lhs: RenderGraph)(rhs: RenderGraph) -> RenderGraph {
    return combine(lhs, multiply(rhs))
}

func monoEdge(graph: RenderGraph) -> RenderGraph {
    return combine(graph, immutable(edges), immutable(mono), immutable(invert))
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
        let syncManager = SynchronizedUpon{ onSynchronized.value?(); updateManager.next()}
        self.updateManager = updateManager
        self.syncManager = syncManager
        self._onSynchronized = onSynchronized
    }
    func clear(){}
}

