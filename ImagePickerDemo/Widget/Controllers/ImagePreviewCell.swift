//
//  ImagePreviewCell.swift
//  epcmobile-ios
//
//  Created by LioWu on 19/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

class ImagePreviewCell: UICollectionViewCell {
    
    var previewView:ImagePreviewView?
    
    var assetModel:AssetModel? {
        didSet {
            setModel()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        previewView = ImagePreviewView(frame: bounds)
        contentView.addSubview(previewView!)
    }
    
    func setModel() {
        previewView?.assetModel = assetModel
    }
}
