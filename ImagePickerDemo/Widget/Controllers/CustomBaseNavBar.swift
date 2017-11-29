//
//  CustomBaseNavBar.swift
//  epcmobile-ios
//
//  Created by LioWu on 07/11/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

class CustomBaseNavBar: UIView {
    var contentView:UIView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        contentView = UIView(frame: CGRect(x: 0, y: bounds.size.height - 44, width: bounds.size.width, height: 44))
        addSubview(contentView)
    }
}
