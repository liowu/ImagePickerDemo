//
//  AssetModel.swift
//  epcmobile-ios
//
//  Created by LioWu on 16/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit
import Photos

enum AssetModelMediaType:Int {
    case photo
    case livePhoto
    case photoGIF
    case video
    case audio
}

class AssetModel: NSObject {
    var asset: PHAsset
    var isSelected: Bool = false
    var type: AssetModelMediaType = .photo
    var timeLength: String?
    var showSelectBtn:Bool = true
    
    init(asset:PHAsset, type:AssetModelMediaType = .photo, timeLength:String? = nil) {
        self.asset = asset
        self.isSelected = false
        self.type = type
        self.timeLength = timeLength
        super.init()
    }
}

class LFAlbumModel: NSObject {
    var name: String
    var count:Int = 0
    var result: PHFetchResult<PHAsset>
    var models: Array<AssetModel>?
    var selectedCount:Int = 0
    
    init(name:String, result:PHFetchResult<PHAsset>) {
        self.name = name
        self.result = result
        super.init()
        ImagePickerManager.default.getAssetsFromFetchResult(result: result, allowPickingVideo: false, allowPickingImage: true) { (array:Array<AssetModel>) in
            models = array
            count = models?.count ?? 0 
            self.checkSelectedModels()
        }
    }
    
    var selectedModels: Array<AssetModel>? {
        didSet {
            checkSelectedModels()
        }
    }
    
    fileprivate func checkSelectedModels() {
        selectedCount = 0
        var selectedAssets = Array<PHAsset>()
        
        if let selectedModels = selectedModels {
            for model in selectedModels {
                selectedAssets.append(model.asset)
            }
        }
        
        if let models = models {
            for model in models {
                if selectedAssets.contains(model.asset) {
                    selectedCount += 1
                }
            }
        }
    }
    
}
