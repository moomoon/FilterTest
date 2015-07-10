//
//  CIKLHelper.swift
//  FilterTest
//
//  Created by Jia Jing on 7/10/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage
func loadCIKLFiles(fileNames: String...) -> String {
    return fileNames.reduce(""){ "\($0)\t\(loadCIKLFile($1))\n" }
}

func loadCIKLFile(fileName: String) -> String {
    let path = NSBundle.mainBundle().pathForResource(fileName , ofType : "cikl")
    var error: NSError?
    return String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: &error)!
}

func color(str: String) -> CIColorKernel {
    return CIColorKernel(string: str)
}

func warp(str: String) -> CIWarpKernel {
    return  CIWarpKernel(string: str)
}

func general(str: String) -> CIKernel {
    return CIKernel(string: str)
}

func kernel<T: CIKernel>(type: (String) -> T, fileNames: String...) -> T{
    fileNames.map{ println(loadCIKLFile($0)) }
    return type(fileNames.reduce(""){ "\($0)\t\(loadCIKLFile($1))\n" })
}