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
        self.layerController.backgroundEffect.append(immutable(keepColor))
//        self.layerController.regionLayer.append(videoLayer(mp4("Comp 1")))
//        self.layerController.regionLayer.append(videoLayer(mp4("Comp 1_2")))
//        self.layerController.vfx.append(mask(toonLayer(0))(maskLayer: videoLayer(mp4("Comp 1_2"))))
//        self.layerController.vfx.append(toonLayerConcrete(0))
//        self.layerController.vfx.append(concrete(glassDistortionLayer(mp4("Comp 1_2")))(backgroundSelector: 1))
//        self.layerController.vfx.append(glassDistortionLayerConcrete(mp4("Comp 1_2"), mp4("Comp 1_1"), 0))
        self.layerController.vfx.append(glassDistortionLayer(mp4("Comp 1_2")))
        renderer.render(layerController)
        renderer.next()
    }
    
    func mp4(name: String) -> String {
        return NSBundle.mainBundle().pathForResource(name, ofType: "mp4")!
    }
    
}