//
//  ImagePickerController.swift
//  epcmobile-ios
//
//  Created by LioWu on 18/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit
import Photos

let photoSelectedImageName = "photo_sel_photoPickerVc"
let photoDeselectedImageName = "photo_def_photoPickerVc"

@objc protocol ImagePickerControllerDelegate:NSObjectProtocol {
    // selected multi photos
    @objc optional func imagePickerController(_ picker: ImagePickerController, didFinishPickingPhotos photos:[UIImage])
    
    // selected single photo
    @objc optional func imagePickerController(_ picker: ImagePickerController, didFinishPickingPhoto photo:UIImage)
    
    // cancel
    @objc optional func imagePickerControllerCancel(_ picker: ImagePickerController)
}

class ImagePickerController: UINavigationController {

    /// Default is 9
    var maxImagesCount:Int = 9
    
    /// The minimum count photos user must pick, Default is 0
    var minImagesCount:Int = 0
    
    /// grid column number
    var columnNumber:Int = 4
    
    /// Sort photos ascending by modificationDate，Default is true
    var sortAscendingByModificationDate:Bool = true
    
    /// Default is 828px
    var photoWidth:CGFloat = 828
    
    /// Default is 600px
    var photoPreviewMaxWidth:CGFloat = 600
    
    /// Default is 15, While fetching photo, HUD will dismiss automatic if timeout
    var timeout:Int = 15
    
    /// Default is true, if set false, the original photo button will hide. user can't picking original photo.
    var allowPickingOriginalPhoto:Bool = true
    
    var isSelectOriginalPhoto:Bool = false
    
    /// Default is true, if set false, user can't picking video.
    var allowPickingVideo:Bool = false
    
    /// Default is false, if set true, user can picking gif image.
    var allowPickingGIF:Bool = false
    
    /// Default is true, if set false, user can't picking image.
    var allowPickingImage:Bool = true
    
    /// Default is true, if set false, user can't take picture.
    var allowTakePicture:Bool = true
    
    /// Default is true, if set false, user can't preview photo.
    var allowPreview:Bool = true
    
    /// Default is true, if set false, the picker don't dismiss itself.
    var autoDismiss:Bool = false
    
    /// The photos user have selected
    var selectedModels = Array<AssetModel>()
    
    /// Minimum selectable photo width, Default is 0
    var minPhotoWidthSelectable:Int = 0
    var minPhotoHeightSelectable:Int = 0
    
    /// Hide the photo what can not be selected, Default is false
    var hideWhenCannotSelect:Bool = false
    
    /// Single selection mode, valid when maxImagesCount = 1
    var singleSelectionMode:Bool {
        return maxImagesCount == 1
    }
    
    ///------- picker not author -----
    var timer:Timer?
    var tipLabel:UILabel?
    var settingBtn:UIButton?
    
    weak var pickerDelegate:ImagePickerControllerDelegate?
    
    var takePictureImageName = "takePicture"
    var photoNumberIconImageName = "photo_number_icon"
    var photoPreviewOriginDefImageName = "preview_original_def"
    var photoOriginDefImageName = "photo_original_def"
    var photoOriginSelImageName = "photo_original_sel"
    var doneButtonTitleColorNormal = UIColor(hex:0x52b300)
    var doneButtonTitleColorDisabled =  UIColor.lightGray
    var doneBtnTitleStr = Bundle.lf_localizedString(forKey: "Done")
    var cancelBtnTitleStr = Bundle.lf_localizedString(forKey: "Cancel")
    var previewBtnTitleStr = Bundle.lf_localizedString(forKey: "Preview")
    var fullImageBtnTitleStr = Bundle.lf_localizedString(forKey: "Full image")
    var settingBtnTitleStr = Bundle.lf_localizedString(forKey: "Setting")
    var processHintStr = Bundle.lf_localizedString(forKey: "Processing...")
    
    // MARK: - override
    override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.automaticallyAdjustsScrollViewInsets = false
        super.pushViewController(viewController, animated: animated)
    }
    
    // MARK: - init
    init(maxImagesCount:Int = 9, columnNumber:Int = 4, delegate:ImagePickerControllerDelegate?, pushPhotoPickerVC:Bool = false) {
        super.init(rootViewController: AlbumController())
        self.columnNumber = columnNumber
        self.maxImagesCount = maxImagesCount
        pickerDelegate = delegate
        sortAscendingByModificationDate = false
        ImagePickerManager.default.sortAscendingByModificationDate = sortAscendingByModificationDate
        ImagePickerManager.default.columnNumber = columnNumber
        ImagePickerManager.default.shouldFixOrientation = true
        
        if ImagePickerManager.default.authorizationStatusAuthorized() == false {
            addAuthorView()
        } else {
            self.pushPhotoPickerVC()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.white
        
        navigationBar.barStyle = .black
        navigationBar.isTranslucent = true
        navigationBar.barTintColor = UIColor(hex: 0x404040)
        navigationBar.tintColor = UIColor.white
    }
    
    // MARK: - public
    public func cancelButtonClick() {
        imagePickerDismiss()
        if let pickerDelegate = pickerDelegate, pickerDelegate.responds(to: #selector(ImagePickerControllerDelegate.imagePickerControllerCancel(_:))) {
            pickerDelegate.imagePickerControllerCancel!(self)
        }
    }
    
    public func done() {
        imagePickerDismiss()
    }
    
    private func addAuthorView() {
        tipLabel = UILabel()
        tipLabel?.frame = CGRect(x: 8, y: 120, width: view.bounds.width - 16, height: 60)
        tipLabel?.textAlignment = .center
        tipLabel?.numberOfLines = 0
        tipLabel?.font = UIFont.systemFont(ofSize: 10)
        tipLabel?.textColor = UIColor.black
        tipLabel?.text = "Allow \(Bundle.appName()) to access your album in \"Settings -> Privacy -> Photos\""
        view.addSubview(tipLabel!)
        
        settingBtn = UIButton(type: .system)
        settingBtn?.setTitle(self.settingBtnTitleStr!, for: .normal)
        settingBtn?.frame = CGRect(x: 0, y: 180, width: view.bounds.width, height: 44)
        settingBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        settingBtn?.addTarget(self, action: #selector(settingBtnClick), for: .touchUpInside)
        view.addSubview(settingBtn!)
        
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(observeAuthrizationStatusChange), userInfo: nil, repeats: true)
    }
    
    @objc private func settingBtnClick() {
        UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
    }
    
    @objc private func observeAuthrizationStatusChange() {
        if ImagePickerManager.default.authorizationStatusAuthorized() {
            tipLabel?.removeFromSuperview()
            settingBtn?.removeFromSuperview()
            
            timer?.invalidate()
            timer = nil
            pushPhotoPickerVC()
        }
    }
    
    private func pushPhotoPickerVC() {
        let photoPickerVC = ThumbnailGridController()
        photoPickerVC.isFirstAppear = true
        photoPickerVC.columnNumber = columnNumber
        
        ImagePickerManager.default.getCameraRollAlbum(allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (albumModel) in
            photoPickerVC.albumModel = albumModel
            pushViewController(photoPickerVC, animated: true)
        }
    }
    
    private func imagePickerDismiss() {
        if autoDismiss {
            dismiss(animated: true) {
                
            }
        }
    }
    
    func promptSelectPhotoBeyondUpperLimit() {
        let msg = "Select a maximum of \(maxImagesCount) photos"
        prompt(message: msg)
    }
}

extension UIViewController {
    func prompt(title: String? = nil, message: String, action: (()->())? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            action?()
        }))
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - HUD
//class HUD {
//    class func showAdded(to view: UIView, title:String, themeColor:UIColor = UIColor.black, textColor:UIColor = UIColor.white, animated:Bool = true) -> UIView {
//        print(#function)
//        return UIView()
//    }
//}
//
//extension UIView {
//    func hideHUD() {
//        print(#function)
//    }
//}

