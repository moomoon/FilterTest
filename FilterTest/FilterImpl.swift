//
//  FilterImpl.swift
//  FilterTest
//
//  Created by Jia Jing on 7/8/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage


struct DelegateFilter: Filter {
    let delegate: (ConcreteFilter) -> ConcreteFilter
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        return delegate(filter)
    }
}

func delegateFilter(delegate: (ConcreteFilter) -> ConcreteFilter) -> Filter {
    return DelegateFilter(delegate: delegate)
}

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

func immutable(filter: Filter...) -> RenderLayer {
    return layer {combine([$0.1[0]] + filter.map{immutable($0)})}
}

func immutable(filter: Filter) -> RenderGraph {
    return ImmutableGraph(filter: filter)
}

func immutable(filter: () -> Filter) -> RenderGraph {
    return immutable(filter())
}


var colorControls: Filter {
    let filter = SimpleEffectFilter(name: "CIColorControls")
    filter.filter.setValue(0.03, forKey: kCIInputBrightnessKey)
    return filter
}

func saturation(sat: CGFloat) -> SimpleEffectFilter {
    let filter = colorControls as! SimpleEffectFilter
    filter.filter.setValue(sat, forKey:kCIInputSaturationKey)
    return filter
}



var exposureAdjust: Filter {
    let filter = SimpleEffectFilter(name: "CIExposureAdjust")
    filter.filter.setValue(1.0, forKey: kCIInputEVKey)
    return filter
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
    filter.filter.setValue(20.0, forKey: kCIInputIntensityKey)
    return filter
}

var edgeWork: Filter {
    return SimpleEffectFilter(name: "CIEdgeWork")
}

var keepColor: Filter {
    return SimpleKernelFilter(kernel: ciKernelKeepColor)
}

var colorClamp: Filter {
    let filter = SimpleEffectFilter(name: "CIColorClamp")
    filter.filter.setValue(CIVector(x: 0.01, y: 0.01, z: 0.01, w: 0), forKey: "inputMinComponents")
    return filter
}

func posterize(levels: CGFloat) -> Filter {
    let filter = SimpleEffectFilter(name: "CIColorPosterize")
    filter.filter.setValue(levels, forKey: "inputLevels")
    return filter
}

func gaussian(_ radius: CGFloat = 10) -> Filter {
    let filter = SimpleEffectFilter(name: "CIGaussianBlur")
    filter.filter.setValue(radius, forKey: kCIInputRadiusKey)
    return filter
}

func boxBlur(_ radius: CGFloat = 10) -> Filter {
    let filter = SimpleEffectFilter(name: "CIBoxBlur")
    filter.filter.setValue(radius, forKey: kCIInputRadiusKey)
    return filter
}

func discBlur(radius: CGFloat = 8) -> Filter {
    let filter = SimpleEffectFilter(name: "CIDiscBlur")
    filter.filter.setValue(radius, forKey: kCIInputRadiusKey)
    return filter
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

func maskedBlur(_ radius: CGFloat = 5) -> PendingFilter {
    let filter = pInput("CIMaskedVariableBlur", "inputMask")
    filter.filter.setValue(radius, forKey: kCIInputRadiusKey)
    return filter
}

//struct MaskedBlurAddMask: Filter {
//    func filter(filter: ConcreteFilter) -> ConcreteFilter {
//        return MaskedBlurFilter(outputImage: filter.outputImage)
//    }
//}
//
//struct MaskedBlurFilter: ConcreteFilter {
//    let outputImage: CIImage
//    let filter = CIFilter(name: "CIMaskedVariableBlur")!
//    func filter(filter: ConcreteFilter) -> ConcreteFilter {
//        self.filter.setValue(self.outputImage, forKey: "inputMask")
//        self.filter.setValue(filter.outputImage, forKey: kCIInputImageKey)
////        self.filter.setValue(20, forKey: kCIInputRadiusKey)
//        return ConcreteImage(outputImage: self.filter.outputImage)
//    }
//}

struct PendingFilter: ConcreteFilter {
    let outputImage: CIImage = CIImage.emptyImage()
    let filter: CIFilter
    let pendingArgs: [String]
    init(_ name: String, _ args: [String]){
        self.init(CIFilter(name: name), args)
    }
    init(_ name: String, _ args: String...){
        self.init(name, args)
    }
    private init(_ filter: CIFilter, _ args: [String]){
        self.filter = filter
        self.pendingArgs = args
    }
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        if let first = pendingArgs.first{
            self.filter.setValue(filter.outputImage, forKey: first)
            println("add arg \(first)")
        }
        return pendingArgs.count > 1 ?
            PendingFilter(self.filter, Array(pendingArgs[1 ..< pendingArgs.count]))
            : ConcreteImage(outputImage: self.filter.outputImage)
    }
}

func pInput(name: String, args: String...) -> PendingFilter{
    return PendingFilter(name, args + [kCIInputImageKey])
}

func pBackground(name: String, args: String...) -> PendingFilter{
    return PendingFilter(name, args + [kCIInputBackgroundImageKey])
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


func sum(filters: [Filter]) -> ConcreteFilter {
    var interpolated = [filters[0]]
    if filters.count > 1 {
        let add = AdditionFilterAddInput()
        filters[1..<filters.count].map{interpolated.append(add.filter($0 as! ConcreteFilter))}
    }
    return FilterGroup.reduceFilters(interpolated)
}








