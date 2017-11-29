//
//  UIImage+ImagePickerBundle.swift
//  epcmobile-ios
//
//  Created by LioWu on 27/09/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

extension UIImage {
    class func pickerImage(_ named:String) -> UIImage? {
        return Bundle.lf_image(named: named)
    }
}
