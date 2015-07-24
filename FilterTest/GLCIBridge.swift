//
//  GLCIBridge.swift
//  FilterTest
//
//  Created by Jia Jing on 7/22/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage
import OpenGLES
import QuartzCore
import Dollar
import Argo
import GLKit

func CIImageWithGLContext(# cgImage: CGImage, eaglContext: EAGLContext) -> CIImage {
    let width = CGImageGetWidth(cgImage)
    let height = CGImageGetHeight(cgImage)
    let bytesPerPix = CGImageGetBitsPerPixel(cgImage) / 8
    var data = Array<GLubyte>(count: width * height * bytesPerPix, repeatedValue: 0)
    let bitmapInfo = CGBitmapInfo.ByteOrderDefault | CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
    let colorSpace = CGImageGetColorSpace(cgImage)
    let bytesPerRow = CGImageGetBytesPerRow(cgImage)
    let cgContext = CGBitmapContextCreate(&data, width, height, 8, CGImageGetBytesPerRow(cgImage) * 8, colorSpace, bitmapInfo)
    println("created cgContext \(cgContext)")
    let rect = CGRectMake(0, 0, CGFloat(width), CGFloat(height))
    let currContext = EAGLContext.currentContext()
    glFlush()
    EAGLContext.setCurrentContext(eaglContext)
    println("context = \(cgContext) rect = \(rect) cgImage = \(cgImage)")
    CGContextDrawImage(cgContext, rect, cgImage)
    var textureHandle: GLuint = 0
    glGenTextures(1, &textureHandle)
    glBindTexture(GLenum(GL_TEXTURE_2D), textureHandle)
    let param2D = $.curry <| glTexParameteri <| GLenum(GL_TEXTURE_2D) <| { (f : Int32) -> GLenum in GLenum(f) }
    param2D(GL_TEXTURE_MIN_FILTER)(GL_LINEAR)
    param2D(GL_TEXTURE_MAG_FILTER)(GL_LINEAR_MIPMAP_LINEAR)
    param2D(GL_TEXTURE_WRAP_S)(GL_CLAMP_TO_EDGE)
    param2D(GL_TEXTURE_WRAP_T)(GL_CLAMP_TO_EDGE)
    glTexImage2D(GLenum(GL_TEXTURE_2D), GLint(0), GL_RGBA, GLsizei(width), GLsizei(height), GLint(0), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &data)
    glGenerateMipmap(GLenum(GL_TEXTURE_2D))
    glFlush()
    EAGLContext.setCurrentContext(currContext)
    return GLCIImage(eaglContext: eaglContext, texture: textureHandle, size: CGSize(width: width, height: height), flipped: true, colorSpace: colorSpace)
}

private class GLCIImage: CIImage {
    private var eaglContext: EAGLContext? = nil
    private var texHandle: UInt32? = nil
    init(eaglContext ctx: EAGLContext, texture name: UInt32, size: CGSize, flipped flag: Bool, colorSpace cs: CGColorSpace!){
        super.init(texture: name, size: size, flipped: flag, colorSpace: cs)
        self.eaglContext = ctx
        self.texHandle = name
        println()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    deinit{
        if let eaglContext = self.eaglContext, texHandle = self.texHandle {
            let currContext = EAGLContext.currentContext()
            var tex = GLuint(texHandle)
            glFlush()
            EAGLContext.setCurrentContext(eaglContext)
            glDeleteTextures(GLsizei(1), &tex)
            glFlush()
            EAGLContext.setCurrentContext(currContext)
        }
    }
}