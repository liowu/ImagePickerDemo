//
//  UIView+LFExtensions.swift
//  epcmobile-ios
//
//  Created by LioWu on 18/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

enum OscillatoryAnimationType {
    case bigger
    case smaller
}

extension UIView {
    func showOscillatoryAnimation(_ type: OscillatoryAnimationType = .bigger) {
        let tLayer = self.layer
        let animationScale1 = true ? 1.15 : 0.5
        let animationScale2 = true ? 0.92 : 1.15
        let transform = "transform.scale"
        
        UIView.animate(withDuration: 0.15, animations: {
            tLayer.setValue(animationScale1, forKeyPath: transform)
        }) { (_) in
            UIView.animate(withDuration: 0.15, animations: {
                tLayer.setValue(animationScale2, forKeyPath: transform)
            }) { (_) in
                UIView.animate(withDuration: 0.1, animations: {
                    tLayer.setValue(1.0, forKeyPath: transform)
                })
            }
        }
    }
}
