//
//  FilterImpl.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage



struct SimpleEffectFilter: EffectFilter{
    let filter: CIFilter
    init(name: String){
        self.filter = CIFilter(name: name)
    }
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: applyEffect(filter.outputImage))
    }
    func applyEffect(background: CIImage) -> CIImage {
        filter.setValue(background, forKey: kCIInputImageKey)
        return filter.outputImage
    }
}

struct SimpleKernelFilter: EffectFilter {
    let kernel: CIKernel
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: applyEffect(filter.outputImage))
    }
    func applyEffect(background: CIImage) -> CIImage {
        let args = [background as AnyObject, Float(0) as AnyObject, Float(0.5) as AnyObject, Float(1.5) as AnyObject]
        return kernel.applyWithExtent(background.extent(), roiCallback: {point, rect in return background.extent()}, arguments: args)
    }
}

func immutable<T: Filter>(filter: T) -> RenderGraph{
    return ImmutableGraph(filter: filter)
}

func immutable<T: Filter>(filter: () -> T) -> RenderGraph{
    return ImmutableGraph(filter: filter())
}
func immutable(filter: () -> Filter) -> RenderGraph {
    return ImmutableGraph(filter: filter())
}

var invert: Filter {
    return SimpleEffectFilter(name: "CIColorInvert")
}

var sepia: Filter {
    return SimpleEffectFilter(name: "CISepiaTone")
}
var chrome: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectChrome")
}
var instant: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectInstant")
}

var mono: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectMono")
}

var noir: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectNoir")
}

var process: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectProcess")
}

var tonal: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectTonal")
}

var transfer: Filter {
    return SimpleEffectFilter(name: "CIPhotoEffectTransfer")
}
var vignette: Filter {
    return SimpleEffectFilter(name: "CIVignette")
}

var vignetteEffect: Filter {
    return SimpleEffectFilter(name: "CIVignetteEffect")
}

var edges: Filter {
    let filter = SimpleEffectFilter(name: "CIEdges")
    filter.filter.setValue(3.0, forKey: kCIInputIntensityKey)
    return filter
}

var edgeWork: Filter {
    return SimpleEffectFilter(name: "CIEdgeWork")
}

func keepColor() -> Filter {
    return SimpleKernelFilter(kernel: ciKernelKeepColor)
}

struct MaskToAlphaFilter: EffectFilter {
    let filter = CIFilter (name: "CIMaskToAlpha")
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: applyEffect(filter.outputImage))
    }
    func applyEffect(background: CIImage) -> CIImage {
        filter.setValue(background, forKey: kCIInputImageKey)
        return filter.outputImage
    }
}

struct BlendWithAlphaFilterAddMask: Filter {
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return BlendWithAlphaFilterAddInput(outputImage: filter.outputImage)
    }
}

struct BlendWithAlphaFilterAddInput: ConcreteFilter {
    let outputImage: CIImage
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return BlendWithAlphaFliter(outputImage: filter.outputImage, maskImage: self.outputImage)
    }
}

struct BlendWithAlphaFliter: BlendFilter {
    let outputImage: CIImage
    let maskImage: CIImage
    let filter = CIFilter(name: "CIBlendWithAlphaMask")!
    
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: blend(filter.outputImage, overlay: self.outputImage))
    }
    
    func blend(background: CIImage, overlay: CIImage) -> CIImage {
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        filter.setValue(overlay, forKey: kCIInputImageKey)
        filter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        return filter.outputImage
    }
}


struct MultiplyCompositingAddInput: Filter{
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return MultiplyCompositing(outputImage: filter.outputImage)
    }
}

struct MultiplyCompositing: BlendFilter {
    let outputImage: CIImage
    let filter = CIFilter(name: "CIMultiplyCompositing")
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: blend(filter.outputImage, overlay: outputImage))
    }
    
    func blend(background: CIImage, overlay: CIImage) -> CIImage {
        filter.setValue(overlay, forKey: kCIInputImageKey)
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }
}


struct BlendWithMaskAddMask: Filter {
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return BlendWithMaskAddInput(inputMaskImage: filter.outputImage)
    }
}

struct BlendWithMaskAddInput: ConcreteFilter {
    let inputMaskImage: CIImage
    var outputImage: CIImage{return inputMaskImage}
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return BlendWithMaskFilter(inputImage: filter.outputImage, inputMaskImage: self.inputMaskImage)
    }
}

struct BlendWithMaskFilter: ConcreteFilter {
    let inputImage: CIImage
    let inputMaskImage: CIImage
    var outputImage: CIImage {return inputImage}
    let filter = CIFilter(name: "CIBlendWithMask")!
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: doFilter(filter.outputImage))
    }
    private func doFilter(inputBackgroundImage: CIImage) -> CIImage {
        self.filter.setValue(inputImage, forKey: kCIInputImageKey)
        self.filter.setValue(inputMaskImage, forKey: kCIInputMaskImageKey)
        self.filter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return self.filter.outputImage
    }
}

struct AdditionFilterAddInput: Filter {
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return AdditionFilter(outputImage: filter.outputImage)
    }
}

struct AdditionFilter: BlendFilter {
    let outputImage: CIImage
    let filter = CIFilter(name: "CIAdditionCompositing")
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: blend(filter.outputImage, overlay: self.outputImage))
    }
    func blend(background: CIImage, overlay: CIImage) -> CIImage {
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        filter.setValue(overlay, forKey: kCIInputImageKey)
        return filter.outputImage
    }
}

struct EdgeWorkFilter: EffectFilter {
    let filter = CIFilter(name: "CIEdgeWork")
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return ConcreteImage(outputImage: applyEffect(filter.outputImage))
    }
    func applyEffect(background: CIImage) -> CIImage {
        filter.setValue(background, forKey: kCIInputImageKey)
        return filter.outputImage
    }
}


struct DummyFilter: ConcreteFilter{
    let outputImage: CIImage = CIImage.emptyImage()
    func filter(filter: ConcreteFilter) -> ConcreteFilter{
        return filter
    }
}









