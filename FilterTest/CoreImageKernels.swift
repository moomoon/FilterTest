//
//  CoreImageKernels.swift
//  FilterTest
//
//  Created by Jia Jing on 7/10/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage

var ciKernelKeepColor: CIKernel {
    return kernel(color, "HSV2RGB", "RGB2HSV", "knKeepColor")
}
