//
//  AssetCell.swift
//  epcmobile-ios
//
//  Created by LioWu on 17/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit
import Photos

enum AssetCellType:Int {
    case photo
    case livePhoto
    case photoGIF
    case video
    case audio
}

class AssetCell: UICollectionViewCell {
    var selectPhotoButton:UIButton?
    var didSelectPhotoBlock:((_ select:Bool)->())?
    var type:AssetCellType?
    var representedAssetIdentifier:String?
    var imageRequestID:PHImageRequestID?
    
    var imageView:UIImageView?
    var model: AssetModel? {
        didSet {
            refreshSubviews()
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
        imageView = UIImageView(frame: bounds)
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        contentView.addSubview(imageView!)
        
        selectPhotoButton = UIButton(frame: CGRect(x: bounds.width - 50, y: bounds.height - 50, width: 50, height: 50))
        selectPhotoButton?.setImage(UIImage.pickerImage(photoSelectedImageName), for: .selected)
        selectPhotoButton?.setImage(UIImage.pickerImage(photoDeselectedImageName), for: .normal)
        selectPhotoButton?.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 0, 0)
        contentView.addSubview(selectPhotoButton!)
        selectPhotoButton?.addTarget(self, action: #selector(selectPhotoButtonClick(sender:)), for: .touchUpInside)
    }
    
    private func refreshSubviews() {
        guard let model = model else {
            return
        }
        
        representedAssetIdentifier = ImagePickerManager.default.getAssetIdentifier(asset: model.asset)
        let imgReqID = ImagePickerManager.default.getPhotoWithAsset(asset: model.asset, photoWidth: bounds.size.width ){ (photo, _, isDegraded:Bool) in
            
            guard let representedAssetIdentifier = self.representedAssetIdentifier else {
                return
            }
            
            if representedAssetIdentifier == ImagePickerManager.default.getAssetIdentifier(asset: model.asset) {
                self.imageView?.image = photo
            } else {
                PHImageManager.default().cancelImageRequest(self.imageRequestID!)
            }
            
            if (!isDegraded) {
                self.imageRequestID = 0;
            }
        }
        
        if let imageRequestID = self.imageRequestID {
            if imageRequestID != 0 && imgReqID != imageRequestID {
                PHImageManager.default().cancelImageRequest(imageRequestID)
            }
        }
        imageRequestID = imgReqID
        selectPhotoButton?.isHidden = !model.showSelectBtn
        selectPhotoButton?.isSelected = model.isSelected
    }
    
    @objc private func selectPhotoButtonClick(sender:UIButton) {
        didSelectPhotoBlock?(sender.isSelected)
        if sender.isSelected {
            selectPhotoButton?.imageView?.showOscillatoryAnimation()
        }
    }
}

class LFCameraCell: UICollectionViewCell {
    
    lazy var imageView = UIImageView()
    
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
        backgroundColor = UIColor.white
        clipsToBounds = true
        
        imageView.frame = self.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.image = Bundle.lf_image(named: "takePicture")
        addSubview(imageView)
    }
}

class LFAlbumCell: UITableViewCell {
    
    var albumModel:LFAlbumModel? {
        didSet {
            setModel()
        }
    }

    lazy var posterImageView:UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        return imgView
    }()
    
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.frame = CGRect(x: 80, y: 0, width: self.bounds.size.width - 80 - 50, height: self.bounds.size.height)
        label.textColor = UIColor.black
        label.textAlignment = .left
        return label
    }()
        
    lazy var selectedCountButton:UIButton = {
        let btn = UIButton()
        return btn
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
    }
    
    private func setupSubviews() {
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
    }
    
    private func setModel() {
        let _nameString = NSMutableAttributedString.init(
            string: albumModel?.name ?? "",
            attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 16),
                         NSForegroundColorAttributeName:UIColor.black])
        
        let _count = NSString.init(format: "  (%zd)", albumModel?.count ?? 0)
        let countString = NSAttributedString.init(
            string: _count as String,
            attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 16),
                         NSForegroundColorAttributeName:UIColor.lightGray])
        _nameString.append(countString)
        titleLabel.attributedText = _nameString
        
        if let model = albumModel {
            ImagePickerManager.default.getPostImageWithAlbumModel(albumModel: model, completeHandler: { (img) in
                self.posterImageView.image = img
            })
        }
    }
}
