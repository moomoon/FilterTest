//
//  HueSlider.swift
//  FilterTest
//
//  Created by Jia Jing on 7/10/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import UIKit
class HueSlider: UIView {
    
    override func drawRect(rect: CGRect){
        super.drawRect(rect)
    }
}
func hueImage(width: CGFloat, height: CGFloat, context: CIContext? = nil) -> UIImage {
    let kernelStr = loadCIKLFiles("HSV2RGB", "knHueImage")
    let kernel = CIKernel(string: kernelStr)
    let args = [width as AnyObject]
    let ciImage = kernel.applyWithExtent(CGRect(x: 0, y: 0, width: width, height: height), roiCallback: {point, rect in return rect}, arguments: args)
    let uiImage: UIImage
    if let context = context {
        uiImage = UIImage(CGImage: context.createCGImage(ciImage, fromRect: ciImage.extent()))!
    } else {
        uiImage = UIImage(CIImage: ciImage)!
    }
    return uiImage
}