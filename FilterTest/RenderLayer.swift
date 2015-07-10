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
        
        
        
        if backgroundEffect.count > 0 {
            graphs.append(RenderGraphGroup(subGraphs: [background[0]] + backgroundEffect))
        } else {
            graphs.append(background[0])
        }
        if region.0.count > 0 {
            let regionGroup = RegionGraphGroup(subGraphs: region.0.map{ $0.createGraph(context, background: background)})
            let addInput = RenderGraphGroup(subGraphs: [regionGroup, immutable(BlendWithMaskAddMask())])
            if(region.1.count > 0){
                let backgroundFiltered = RenderGraphGroup(subGraphs: [background[0]] + region.1)
                graphs.append(RenderGraphGroup(subGraphs: [backgroundFiltered, addInput]))
            } else {
                graphs.append(RenderGraphGroup(subGraphs: [background[0], addInput]))
            }
        }
        
        
        
        vfx.map{graphs.append($0.createGraph(context, background: background))}
        return RenderGraphGroup(subGraphs: graphs)
    }
}

struct VideoLayer: RenderLayer {
    let path: String
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        let generator = VideoGenerator(path: path, synced: context.syncManager.newSynced())
        context.updateManager.registerUpdatable(generator)
        return generator
    }
}

struct MultiplyVideoLayer: RenderLayer {
    let path0: String
    let path1: String
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        let generator0 = VideoGenerator(path: path0, synced: context.syncManager.newSynced())
        context.updateManager.registerUpdatable(generator0)
        let generator1 = VideoGenerator(path: path1, synced: context.syncManager.newSynced())
        context.updateManager.registerUpdatable(generator1)
        let multiply = RenderGraphGroup(subGraphs: [generator0, immutable(MultiplyCompositingAddInput())])
        return RenderGraphGroup(subGraphs: [generator1, multiply])
    }
}

struct NormalLayer: RenderLayer {
    let backgroundPath: String
    let maskPath: String
    func createGraph(context: RenderGraphContext, background: [RenderGraph]) -> RenderGraph {
        let backgroundGenerator = VideoGenerator(path: backgroundPath, synced: context.syncManager.newSynced())
        let maskGenerator = VideoGenerator(path: maskPath, synced: context.syncManager.newSynced())
        context.updateManager.registerUpdatable(backgroundGenerator)
        context.updateManager.registerUpdatable(maskGenerator)
        let maskGraph = RenderGraphGroup(subGraphs: [maskGenerator, immutable(BlendWithMaskAddMask())])
        return RenderGraphGroup(subGraphs: [backgroundGenerator, maskGraph])
    }
}

struct RegionGraphGroup: RenderGraph {
    let subGraphs: [RenderGraph]
    var filter: Filter { return RegionGraphGroup.reduceFilters(subGraphs.map{$0.filter})}
    static func reduceFilters(layers: [Filter]) -> ConcreteFilter{
        let concreteFilters = layers.map{$0 as! ConcreteFilter}
        if concreteFilters.count < 2 { return concreteFilters[0] }
        let flatten = concreteFilters[0..<1] + concreteFilters[1..<concreteFilters.count].map{FilterGroup.reduceFilters([$0, AdditionFilterAddInput()])}
        return FilterGroup.reduceFilters(Array(flatten.map{ $0 as Filter }))
    }
}
