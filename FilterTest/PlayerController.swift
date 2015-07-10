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
        self.imageView.image = hueImage(imageView.bounds.width, imageView.bounds.height)
//        self.glkView.context = renderer.eaglContext
//        self.backgroundVideoPath = mp4Path("movie")
//        self.layerController.backgroundEffect.append(immutable(keepColor))
//        renderer.render(layerController)
//        renderer.next()
    }
    
    func mp4Path(name: String) -> String {
        return NSBundle.mainBundle().pathForResource(name, ofType: "mp4")!
    }
    
    func mp4(name: String) -> VideoLayer {
        return VideoLayer(path: mp4Path(name))
    }
}