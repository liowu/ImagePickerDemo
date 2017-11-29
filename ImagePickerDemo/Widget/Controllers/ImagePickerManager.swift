//
//  ImagePickerManager.swift
//  epcmobile-ios
//
//  Created by LioWu on 16/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit
import Photos

private let LFScreenWidth:CGFloat = UIScreen.main.bounds.width
private let LFScreenScale:CGFloat = LFScreenWidth > 700 ? 1.5 : 2.0

class ImagePickerManager: NSObject {
    
    static let `default`: ImagePickerManager = ImagePickerManager()
    
    var shouldFixOrientation:Bool = false
    var photoPreviewMaxWidth:CGFloat = 600
    var columnNumber:Int = 3
    
    /// Sort photos ascending by modificationDate，Default is true, when false, the camera will be the first item
    var sortAscendingByModificationDate:Bool = true
    
    /// Minimum selectable photo width, Default is 0
    var minPhotoWidthSelectable:Int = 350
    var minPhotoHeightSelectable:Int = 350
    var hideWhenCanNotSelect:Bool = true
    
    var assetGridThumbnailSize:CGSize? {
        let itemWH:CGFloat = (LFScreenWidth - CGFloat(columnNumber - 1) * kGridMargin) / CGFloat(columnNumber)
        return CGSize(width: itemWH * LFScreenScale, height: itemWH * LFScreenScale)
    }
    
    /// author
    func authorizationStatusAuthorized() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            requestAuthorizationWhenNotDetermined()
        }
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    private func requestAuthorizationWhenNotDetermined() {
        DispatchQueue.global().async { 
            PHPhotoLibrary.requestAuthorization({ (status:PHAuthorizationStatus) in })
        }
    }
    
    // MARK: - get album
    func getCameraRollAlbum(allowPickingVideo:Bool, allowPickingImage:Bool, completeHandler:(_ model:LFAlbumModel)->()) {
        let option = PHFetchOptions()
        
        if !allowPickingVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        if !allowPickingImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }

        if (!self.sortAscendingByModificationDate) {
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: self.sortAscendingByModificationDate)
            option.sortDescriptors = [sortDescriptor]
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        
        for i in 0..<smartAlbums.count {
            let collection = smartAlbums[i]
            if !collection.isKind(of: PHAssetCollection.self) { continue }
            if isCameraRollAlbum(albumName: collection.localizedTitle ?? "") {
                let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                let model = modelWithResult(result: fetchResult, name: collection.localizedTitle ?? "")
                completeHandler(model)
                break
            }
        }
    }
    
    func getAllAlbums(allowPickingVideo:Bool, allowPickingImage:Bool, completeHandler:(_ albums:Array<LFAlbumModel>)->()) {
        let option = PHFetchOptions()
        
        if !allowPickingVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        if !allowPickingImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        
        if (!self.sortAscendingByModificationDate) {
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: self.sortAscendingByModificationDate)
            option.sortDescriptors = [sortDescriptor]
        }
        
        let myPhotoStreamAlbum = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        let topLevelUserCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil)
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
        
        let allAlbums = [myPhotoStreamAlbum,
                         smartAlbums,
                         topLevelUserCollections,
                         syncedAlbums,
                         sharedAlbums] as! [PHFetchResult<PHAssetCollection>]
        
        var albumArr = Array<LFAlbumModel>()
        
        for fetch in allAlbums {
            for i in 0..<fetch.count {
                let collection = fetch[i]
                if !collection.isKind(of: PHAssetCollection.self) { continue }
                guard let locTitle = collection.localizedTitle else { continue }
                
                // TODO: - how judge this
                if locTitle.contains("Deleted")
                    || locTitle.contains("最近删除") {
                    continue
                }
                
                if isCameraRollAlbum(albumName: locTitle) {
                    let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                    let album = modelWithResult(result: fetchResult, name: locTitle)
                    if album.count < 1 {continue}
                    albumArr.insert(album, at:0)
                } else {
                    let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                    let album = modelWithResult(result: fetchResult, name: locTitle)
                    if album.count < 1 {continue}
                    albumArr.append(album)
                }
            }
        }
        completeHandler(albumArr)
    }

    func isCameraRollAlbum(albumName:String?) -> Bool{
        guard let albumName = albumName else { return false }
        var versionStr:String = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "")
        let vLength = (versionStr as NSString).length
        if vLength <= 1 {
            versionStr.append("00")
        } else if vLength <= 2 {
            versionStr.append("0")
        }
        
        // TODO: -
        let version = (versionStr as NSString).floatValue
        if version >= 800 && version <= 802 {
            return (albumName == "最近添加")
                || (albumName == "Recently Added")
        }
        else {
            return (albumName == "Camera Roll")
                || (albumName == "相机胶卷")
                || (albumName == "All Photos")
                || (albumName == "所有照片")
        }
    }
    
    fileprivate func modelWithResult(result:PHFetchResult<PHAsset>, name:String) -> LFAlbumModel {
        return LFAlbumModel(name: name, result: result)
    }
}

// MARK: - get assets
extension ImagePickerManager {
    
    func getAssetsFromFetchResult(result:PHFetchResult<PHAsset>, allowPickingVideo:Bool, allowPickingImage:Bool, completeHandler:(_ assetModels:Array<AssetModel>)->() ) {
        var array = Array<AssetModel>()
        result.enumerateObjects({ (asset, index, _) in
            let assetModdel = self.assetModelWithAsset(asset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
            if let assetModdel = assetModdel {
                array.append(assetModdel)
            }
        })
        
        completeHandler(array)
    }
    
    func assetModelWithAsset(asset:PHAsset, allowPickingVideo:Bool, allowPickingImage:Bool) -> AssetModel? {
        var type:AssetModelMediaType = .photo
        if asset.mediaType == .audio {
            type = .audio
        } else if asset.mediaType == .video {
            type = .video
        } else if asset.mediaType == .image {
            if let filename = asset.value(forKey: "filename") as? String {
                if filename.hasSuffix(".GIF") || filename.hasSuffix(".gif") {
                    type = .photoGIF
                }
            }
        }
        
        if !allowPickingVideo && type == .video {
            return nil
        }
        if !allowPickingImage && type == .photo {
            return nil
        }
        if !allowPickingImage && type == .photoGIF {
            return nil
        }
        
        return AssetModel(asset: asset, type: type, timeLength: "0")
    }
    
    func getAssetIdentifier(asset:PHAsset) -> String {
        return asset.localIdentifier;
    }
    
    class func fetchPhotosBytes(withArray:Array<AssetModel>, complete:((_ length:String)->())? = nil) {
        var dataLength = 0
        var assetCount = 0
        for i in 0..<withArray.count {
            let options = PHImageRequestOptions()
            options.resizeMode = .fast
            PHImageManager.default().requestImageData(for: withArray[i].asset, options: options, resultHandler: { (data, _, _, _) in
                if let data = data {
                    dataLength += data.count
                }
                assetCount += 1
                if assetCount == withArray.count {
                    complete?(getBytes(fromDataLength: dataLength))
                }
            })
        }
    }
}

// MARK: - get photo
extension ImagePickerManager {
    
    func getPreviewPhotoWith(asset:PHAsset, networkAccessAllowed:Bool? = true, completion:((_ photo:UIImage?, _ info:[AnyHashable : Any]?, _ isDegraded:Bool)->())?) -> PHImageRequestID {
        var fullScreenWidth:CGFloat = LFScreenWidth;
        if fullScreenWidth > photoPreviewMaxWidth {
            fullScreenWidth = photoPreviewMaxWidth
        }
        return getPhotoWithAsset(asset: asset, photoWidth: fullScreenWidth, networkAccessAllowed: networkAccessAllowed, completion: completion)
    }
    
    func getPhotoWithAsset(asset:PHAsset, photoWidth:CGFloat, networkAccessAllowed:Bool? = true, completion:((_ photo:UIImage?, _ info:[AnyHashable : Any]?, _ isDegraded:Bool)->())?) -> PHImageRequestID {
        var imageSize:CGSize = CGSize.zero
        if photoWidth < LFScreenWidth && photoWidth < photoPreviewMaxWidth {
            imageSize = assetGridThumbnailSize!
        } else {
            let aspectRatio =  CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
            let pixelWidth = photoWidth * LFScreenScale;
            let pixelHeight = pixelWidth / aspectRatio;
            imageSize = CGSize(width:pixelWidth, height:pixelHeight)
        }
        let option = PHImageRequestOptions()
        option.resizeMode = .fast
        
        return PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: option) { (result:UIImage?, info:[AnyHashable : Any]?) in
            
            var _downloadFinined:Bool = true
            var _isDegrade:Bool = false
            if let isDegrade = info?[PHImageResultIsDegradedKey] as? Bool {
                _isDegrade = isDegrade
            }
            
            if let cancelled = info?[PHImageCancelledKey] as? Bool {
                if cancelled == true {
                    _downloadFinined = false
                }
            }
            
            if let error = info?[PHImageErrorKey] as? Bool {
                if error == true {
                    _downloadFinined = false
                }
            }
            
            if let ret = result {
                if _downloadFinined == true {
                    let fixResult = ret.fixOrientation()
                    completion?(fixResult, info, _isDegrade)
                }
            }
        }
    }
    
    func getOriginalPhoto(withAsset asset:PHAsset, isCompress:Bool = false, completion:((_ photo:UIImage?, _ info:[AnyHashable : Any]?)->())?) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = false
        
        _ = PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { (result:UIImage?, info:[AnyHashable : Any]?) in
            var _downloadFinined:Bool = true
            
            if let cancelled = info?[PHImageCancelledKey] as? Bool {
                if cancelled == true {
                    _downloadFinined = false
                }
            }
            
            if let error = info?[PHImageErrorKey] as? Bool {
                if error == true {
                    _downloadFinined = false
                }
            }
            
            if let ret = result {
                if _downloadFinined == true {
                    var fixResult = ret.fixOrientation()
                    if isCompress {
                        fixResult = fixResult.compress() ?? fixResult
                    }
                    completion?(fixResult, info)
                    return
                }
            }
            completion?(nil, info)
        }
    }
}


// MARK: - get postImage
extension ImagePickerManager {
    
    func getPostImageWithAlbumModel(albumModel:LFAlbumModel, completeHandler:((_ image:UIImage?)->())? = nil) {
        var asset = albumModel.result.lastObject
        if !self.sortAscendingByModificationDate {
            asset = albumModel.result.firstObject
        }
        guard let ast = asset else {
            completeHandler?(nil)
            return
        }
        _ = ImagePickerManager.default.getPhotoWithAsset(asset: ast, photoWidth: 80) { (img, _, _) in
            completeHandler?(img)
        }
    }
    
    func savePhoto(withImage image:UIImage, completeHandler:((_ success:Bool, _ error:Error?)->())? = nil) {
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (success:Bool, error:Error?) in
            completeHandler?(success, error)
        })
    }
}

// MARK: - util
extension ImagePickerManager {
    class func fetchAsset(fromModelArray:Array<AssetModel>) -> [PHAsset] {
        return fromModelArray.map({ (model) -> PHAsset in
            model.asset
        })
    }
    
    class func getBytes(fromDataLength:Int) -> String {
        var bytes:String
        if fromDataLength < 1024 {
            bytes = String(format: "%zdB", fromDataLength)
        } else if fromDataLength < 1024 * 1024 {
            bytes = String(format: "%0.0fK", CGFloat(fromDataLength)/1024)
        } else {
            bytes = String(format: "%0.1fM", CGFloat(fromDataLength)/1024/1024)
        }
        return bytes
    }
}

