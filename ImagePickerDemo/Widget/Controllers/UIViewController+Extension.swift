//
//  UIViewController+Extensions.swift
//  epcmobile-ios
//
//  Created by LioWu on 02/11/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

extension NSObject {
    func navBarHeight(_ viewController:UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> CGFloat {
        let prefersStatusBarHidden = viewController?.prefersStatusBarHidden ?? false
        if #available(iOS 11, *) {
            if UIDevice.isIPhoneX() {
                return 88
            }
        }
        return prefersStatusBarHidden ? 44 : 64
    }
    
    func bottomSafeAreaHeight() -> CGFloat {
        if #available(iOS 11, *) {
            return UIDevice.isIPhoneX() ? 34 : 0
        } else {
            return 0
        }
    }
}

extension UIDevice {
    class func isIPhoneX() -> Bool {
        return UIScreen.main.bounds.height == 812
    }
}
