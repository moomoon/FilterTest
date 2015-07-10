//
//  LayerController.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation

class LayerController {
    var backgroundPaths: [String] = []{ didSet{ _background = backgroundPaths.map{ VideoLayer(path: $0)}}}
    private var _background: [VideoLayer] = []
    var background: [RenderLayer] {return _background.map{$0 as RenderLayer} }
    var backgroundEffect: [RenderGraph] = []
    var regionLayer: [RenderLayer] = []
    var regionEffect: [RenderGraph] = []
    private var region:([RenderLayer], [RenderGraph]) { return (regionLayer, regionEffect) }
    var vfx: [RenderLayer] = []
    var mainLayer: MainRenderLayer {return MainRenderLayer(vfx: vfx, region: region, backgroundEffect: backgroundEffect)}
}