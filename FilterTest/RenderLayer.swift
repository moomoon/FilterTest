//
//  RenderLayer.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation

protocol RenderLayer {
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph
}

struct MainRenderLayer: RenderLayer {
    let vfx: [RenderLayer]
    let region: ([RenderLayer], [RenderGraph])
    let backgroundEffect: [RenderGraph]
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        var graphs: [RenderGraph] = []
        
        let backgroundGroup: RenderGraph
        
        if backgroundEffect.count > 0 {
            backgroundGroup = RetainGraphGroup(subGraphs: [background[0]] + backgroundEffect, context: context)
        } else {
            backgroundGroup = background[0]
        }
        //this is fed to the vfx layers
        graphs.append(backgroundGroup)
        
        
        if region.0.count > 0 {
            //background is not referenced here, just creating mask graphs
            let regionGroup = sum(region.0.map{ $0.createGraph(context, background: background)})
            let addInput = combine([regionGroup, immutable(BlendWithMaskAddMask())])
            if(region.1.count > 0){
                graphs.append(combine([combine([background[0]] + region.1), addInput]))
            } else {
                graphs.append(combine([background[0], addInput]))
            }
        }
        
        vfx.map{graphs.append($0.createGraph(context, background: [background[0], backgroundGroup]))}
        return combine(graphs)
    }
}

func layer(delegate: (RenderGraphContext, [RenderGraph]) -> RenderGraph) -> RenderLayer {
    return DelegateLayer(delegate: delegate)
}


struct DelegateLayer: RenderLayer {
    let delegate: (RenderGraphContext, [RenderGraph]) -> RenderGraph
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        return delegate(context, background)
    }
}

func concrete(overlay: RenderLayer)(backgroundSelector: Int) -> RenderLayer{
    return layer{ combine($1[backgroundSelector], overlay.createGraph($0, background: $1))}
}


func toonLayerConcrete(backgroundSelector: Int) -> RenderLayer {
    return layer {
        let forEdge = combine($0.1[backgroundSelector], immutable(gaussian(1)), immutable(posterize(3)), immutable(colorControls))
        let posterized = combine($0.1[backgroundSelector], immutable(posterize(5)), immutable(colorControls))
        return multiplyConcrete(monoEdge(forEdge)(level: 1))(rhs: posterized)
    }
}

//func glassDistortionLayerConcrete(inputPath: String)(backgroundSelector: Int) -> RenderLayer {
//    return layer { combine($0.1[backgroundSelector], glassDistortion(video(inputPath, $0.0)))}
//}


func videoLayer(path: String) -> RenderLayer {
    return layer{video(path, $0.0)}
}

func glassDistortionLayer(inputPath: String) -> RenderLayer {
    return layer{glassDistortion(video(inputPath, $0.0))}
}


func normalLayer(backgroundPath: String, maskPath: String) -> RenderLayer {
    return layer { mask(video(backgroundPath, $0.0))(mask: video(maskPath, $0.0)) }
}

func multiplyLayer(path: String) -> RenderLayer {
    return layer{ multiply(video(path, $0.0))}
}


func mask(inputLayer: RenderLayer)(maskLayer: RenderLayer) -> RenderLayer {
    return layer {mask(inputLayer.createGraph($0, background: $1))(mask: maskLayer.createGraph($0, background: $1))}
}


class RetainGraphGroup: RenderGraph, Syncable, Updatable {
    let synced: Synced
    let subGraphs: [RenderGraph]
    init(subGraphs: [RenderGraph], context: RenderGraphContext){
        self.subGraphs = subGraphs
        self.synced = context.syncManager.newSynced()
        context.updateManager.registerUpdatable(self)
    }
    private var _filter: Filter? = nil
    var filter: Filter {
        if let f = self._filter { return f }
        let f = subGraphs / { $0.filter }
        self._filter = f
        return f
    }
    func update() {
        self._filter = nil
        self.synced.notifyUpdated()
    }
}

func sum(graphs: [RenderGraph]) -> RenderGraph {
    return delegateGraphGroup(graphs, sum)
}
