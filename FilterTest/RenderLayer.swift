//
//  RenderLayer.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage
import Argo
import ReactiveCocoa
import Cent
import Dollar

protocol RenderLayer {
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph
}

struct MainRenderLayer: RenderLayer {
    let vfx: [RenderLayer]
    let region: ([RenderLayer], [RenderGraph])
    let backgroundEffect: [RenderGraph]
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        println("creating main layer")
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
            if(region.1.count > 0){
                graphs.append($.curry <| mask <| combine([background[0]] + region.1) <| regionGroup)
            } else {
                graphs.append($.curry <| mask <| background[0] <| regionGroup)
            }
        }
        
        println("before creating vfx layers")
        vfx.map{graphs.append($0.createGraph(context, background: [background[0], backgroundGroup]))}
        println("before comine")
        let a =  combine(graphs)
        println("created main layer \(a)")
        return a
    }
}

func layer(delegate: (RenderGraphContext, [RenderGraph]) -> RenderGraph) -> RenderLayer {
    println("entering creating layer")
    let l = DelegateLayer(delegate: delegate)
    println("created textLayer")
    return l
}


struct DelegateLayer: RenderLayer {
    let delegate: (RenderGraphContext, [RenderGraph]) -> RenderGraph
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        return delegate(context, background)
    }
}

func concrete(overlay: RenderLayer)(backgroundSelector: Int) -> RenderLayer{
    return layer{ overlay.createGraph($0, background: $1) <| $1[backgroundSelector] }
}


func toonLayerConcrete(backgroundSelector: Int) -> RenderLayer {
    return layer {
        let forEdge = $0.1[backgroundSelector] |> gaussian(1) |> posterize(3) |> colorControls
        let posterized = $0.1[backgroundSelector] |> posterize(5) |> colorControls
        return multiply <| (monoEdge <| 1 <| forEdge) <| posterized
    }
}



func videoLayer(path: String) -> RenderLayer {
    return layer{video(path, $0.0)}
}

func glassDistortionLayerConcrete(dewMask: String, solidMask: String, backgroundSelector: Int) -> RenderLayer {
    return layer{
        let dewVideo = video(dewMask, $0.0)
        let solidVideo = video(solidMask, $0.0)
        let background = $0.1[backgroundSelector]
        let blur = gaussian <| 10 <| background
        let dew = glassDistortion <| background <| dewVideo
        let solidGraph = $.curry <| mask <| background <| solidVideo <| blur
        return $.curry <| mask <| dew <| dewVideo <| solidGraph
    }
}


func maskedBlurLayer(maskPath: String) -> RenderLayer {
    return layer{ maskedBlur <| video(maskPath, $0.0) }
}

func glassDistortionLayer(inputPath: String) -> RenderLayer {
    return layer{ glassDistortion <| video(inputPath, $0.0)}
}


func normalLayer(inputPath: String, maskPath: String) -> RenderLayer {
    return layer{ $.curry <| mask <| video(inputPath, $0.0) <| video(maskPath, $0.0) }
}

func multiplyLayer(path: String) -> RenderLayer {
    return layer{ multiply <| video(path, $0.0) }
}


func mask(inputLayer: RenderLayer, maskLayer: RenderLayer) -> RenderLayer {
    return layer { $.curry <| mask <| inputLayer.createGraph($0, background: $1) <| maskLayer.createGraph($0, background: $1) }
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
    return delegateGraphGroup(graphs){ sum($0.map{$0 as! ConcreteFilter})}
}
