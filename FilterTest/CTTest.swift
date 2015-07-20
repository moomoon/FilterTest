//
//  CTTest.swift
//  FilterTest
//
//  Created by Jia Jing on 7/20/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import CoreImage
import Dollar
import Argo

func test(bounds: CGRect) {
    let context = UIGraphicsGetCurrentContext()
    //flip
    CGContextTranslateCTM(context, 0, bounds.height)
    CGContextScaleCTM(context, 1.0, -1.0)
    
    //is this necessary?
    CGContextSetTextMatrix(context, CGAffineTransformIdentity)
    
    
    let path = CGPathCreateMutable()
    let textBounds = CGRectMake(10, 10, 200, 200)
    CGPathAddRect(path, nil, textBounds)
    
    let textString = "hello world, this is drawn by coreText"
    let attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0)
    CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), textString)
    
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let components: [CGFloat] = [1.0, 0.0, 0.0, 0.8]
    let red = CGColorCreate(rgbColorSpace, components)
    
    
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, 10), kCTForegroundColorAttributeName, red)
    
    
    let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
    
    let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)

}


typealias GlyphFragment = (CIImage, CGRect)


func getBounds(str: String, font: CTFont, frame: CGSize, ctFrame: CTFrameRef) -> [CGRect] {
    let nsStr = str as NSString
    var chars = (0..<str.length).map{nsStr.characterAtIndex($0)}
    var glyphs =  [CGGlyph](count: str.length, repeatedValue: 0)
    CTFontGetGlyphsForCharacters(font, &chars, &glyphs, str.length)
    
    
    var charBounds = [CGRect](count: str.length, repeatedValue: CGRectMake(0, 0, 0, 0))
    CTFontGetBoundingRectsForGlyphs(font, CTFontOrientation.OrientationDefault, &glyphs, &charBounds, str.length)
//    var charBounds  = glyphs.map{CTFontCreatePathForGlyph(font, $0, nil)}.map(CGPathGetBoundingBox)
    let lines = CTFrameGetLines(ctFrame)
    let lCount = CFArrayGetCount(lines)
    var lineOrigins =  [CGPoint](count: lCount, repeatedValue: CGPoint(x: 0, y: 0))
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), &lineOrigins)
    let getLine = { unsafeBitCast(CFArrayGetValueAtIndex(lines, $0), CTLine.self) }
    let charOrigins: [CGPoint] =
    Array(zip(lineOrigins.map{$0.y}, (0 ..< lCount).map(getLine)))
        .map{($0, $1, CTLineGetStringRange($1))}
        .flatMap{
            let y = $0;
            let line = $1;
            return ($2.location ..< $2.length + $2.location).map{CGPointMake(CTLineGetOffsetForStringIndex(line, $0, nil), y)}
    }
    return Array(zip(charOrigins, charBounds)).map{CGRectMake($0.x + $1.origin.x,  $0.y + $1.origin.y, $1.width, $1.height)}
}

func drawGlyphFragment(context: CGContext, ctFrame: CTFrameRef, frame: CGSize, charFrames: [CGRect]) -> [GlyphFragment] {
    CGContextSaveGState(context)
//    CGContextSetTextMatrix(context, CGAffineTransformIdentity)
//    CGContextTranslateCTM(context, 0, frame.height)
//    CGContextScaleCTM(context, 1, -1)
    CGContextSetRGBFillColor(context, 1, 0, 0, 1)
    CGContextFillRect(context, CGRectMake(0, 0, frame.width, frame.height))
    CTFrameDraw(ctFrame, context)
    CGContextFlush(context)
    let cgImage = CGBitmapContextCreateImage(context)
    CGContextRestoreGState(context)
    let ciImage = CIImage(CGImage: cgImage)
//    let cropFilter = CIFilter(name: "CICrop")!
//    cropFilter.setValue(ciImage, forKey: kCIInputImageKey)
    return charFrames.map{ println("cropping to \($0)"); return (ciImage.imageByCroppingToRect($0), $0)}
}



func getTextImage(context: CGContext, str: String,font: CTFontRef, ctFrame: CTFrameRef, frame: CGSize) -> CIImage {
    let nsStr = str as NSString
    var chars = (0..<str.length).map{nsStr.characterAtIndex($0)}
    var glyphs =  [CGGlyph](count: str.length, repeatedValue: 0)
    CTFontGetGlyphsForCharacters(font, &chars, &glyphs, str.length)
    
    
    CGContextSaveGState(context)
//    CGContextSetTextMatrix(context, CGAffineTransformIdentity)
    CGContextSetRGBFillColor(context, 1, 1, 0, 1)
    CGContextFillRect(context, CGRectMake(0, 0, frame.width, frame.height))
    CTFrameDraw(ctFrame, context)
    let paths = glyphs.map{CTFontCreatePathForGlyph(font, $0, nil)}
    for p in paths{
        CGContextBeginPath(context);
        CGContextAddPath(context, p);
        CGContextSetRGBFillColor(context, 0, 1, 1, 1)
        CGContextClosePath(context)
        CGContextFillPath(context)
    }
    CGContextFlush(context)
    let cgImage = CGBitmapContextCreateImage(context)
    return CIImage(CGImage: cgImage)
}


//func getFonts() {
//    let familyNames = UIFont.familyNames().map{$0 as! String}
//    for familyName in familyNames {
//        println("family name = \(familyName)")
//        UIFont.fontNamesForFamilyName(familyName).map{$0 as! String}.map(println)
//    }
//}

func getImageBounds(ciImage: CIImage, roi: CGRect) -> CGRect {
    let topLeft = getImageTopLeft(ciImage, roi)
    let filter = CIFilter(name: "CIAffineTransform")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    let transform = CGAffineTransformMakeScale(-1, -1)
    filter.setValue(NSValue(CGAffineTransform: transform), forKey: "inputTransform")
    let extent = ciImage.extent()
    let bottomRightFlipped = getImageTopLeft(filter.outputImage, CGRectMake(extent.width - roi.origin.x, extent.height - roi.origin.y, roi.width, roi.height))
    return CGRectMake(topLeft.x, topLeft.y, extent.width - topLeft.x - bottomRightFlipped.x, extent.height - topLeft.y - bottomRightFlipped.y)
}

private func getImageTopLeft(ciImage: CIImage, roi: CGRect) -> CGPoint {
    let filter = CIFilter(name: "CIAreaMaximumAlpha")!
    return CGPoint(x: getImageLeft(ciImage, roi, filter), y: getImageTop(ciImage, roi, filter))
}


private func isTransparent(ciImage: CIImage, roi: CGRect, maxAlphaFilter: CIFilter) -> Bool {
    return false
}

private func getImageLeft(ciImage: CIImage, roi: CGRect, maxAlphaFilter: CIFilter) ->  CGFloat {
//    if roi.width <= 1 {
//        return roi.origin.x
//    } else {
//        maxAlphaFilter.setValue(ciImage, forKey: kCIInputImageKey)
//        maxAlphaFilter.setValue(CGRectMake(roi.origin.x, <#width: CGFloat#>, <#height: CGFloat#>), forKey: <#String#>)
//    }
//    
    return 0
}

private func getImageTop(ciImage: CIImage, roi: CGRect, maxAlphaFilter: CIFilter) -> CGFloat {
    return 0
}