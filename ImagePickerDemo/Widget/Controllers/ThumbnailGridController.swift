//
//  ThumbnailGridController.swift
//  epcmobile-ios
//
//  Created by LioWu on 15/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import Photos

// grid margin 表格间距
let kGridMargin:CGFloat = 2

private let kAssetCell = "AssetCell"
private let kLFCameraCell = "LFCameraCell"

/// thumbnail grid image
class ThumbnailGridController: UIViewController {
    var isFirstAppear:Bool = true
    var columnNumber:Int = ImagePickerManager.default.columnNumber
    var albumModel:LFAlbumModel?
    var modelArray = Array<AssetModel>()
    var collectionView:UICollectionView?
    var shouldScrollToBottom:Bool = false
    var showTakePhotoBtn:Bool = false
    
    var toolBar:CustomToolBar?
    var toolBarContentView:UIView?
    var preViewButton:UIButton?
    var originalPhotoButton:UIButton?
    var originalPhotoSizeLabel:UILabel?
    var doneButton:UIButton?
    var selectedNumberView:UIButton?
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = albumModel?.name
        
        let imagePickerNAV = navigationController as! ImagePickerController
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: imagePickerNAV.cancelBtnTitleStr, style: .plain, target: imagePickerNAV, action: #selector(imagePickerNAV.cancelButtonClick))
        
        showTakePhotoBtn = ImagePickerManager.default.isCameraRollAlbum(albumName: albumModel?.name) && imagePickerNAV.allowTakePicture
        imagePickerNAV.singleSelectionMode ? () : setupToolBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if modelArray.count == 0 {
            fetchAssetModels()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let imagePickerNAV = navigationController as! ImagePickerController
        let toolBarHeight:CGFloat = imagePickerNAV.singleSelectionMode ? 0 : 44
        collectionView?.frame = CGRect(x: 0, y: navBarHeight(), width: view.bounds.width, height: view.bounds.size.height - navBarHeight() - bottomSafeAreaHeight() - toolBarHeight)
    }
    
    // MARK: - data
    private func fetchAssetModels() {
        DispatchQueue.global().async {
            let imagePickerNAV = self.navigationController as! ImagePickerController
            guard let result = self.albumModel?.result else { return }
            ImagePickerManager.default.getAssetsFromFetchResult(result: result, allowPickingVideo: imagePickerNAV.allowPickingVideo, allowPickingImage: imagePickerNAV.allowPickingImage) { [weak self] (assets:Array<AssetModel>) in
                let nav = self?.navigationController as! ImagePickerController
                self?.modelArray = assets.map({ (assetModel) -> AssetModel in
                    assetModel.showSelectBtn = !nav.singleSelectionMode
                    return assetModel
                })
                self?.setupSubviews()
            }
        }
    }
    
    fileprivate func reloadDatas() {
        let imagePickerNAV = navigationController as! ImagePickerController
        guard let result = albumModel?.result else {
            return
        }
        
        ImagePickerManager.default.getAssetsFromFetchResult(result: result, allowPickingVideo: imagePickerNAV.allowPickingVideo, allowPickingImage: imagePickerNAV.allowPickingImage) { (assets:Array<AssetModel>) in
            modelArray = assets
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    fileprivate func reloadCameraRollAlbumData() {
        let imagePickerNAV = self.navigationController as! ImagePickerController
        ImagePickerManager.default.getCameraRollAlbum(allowPickingVideo: imagePickerNAV.allowPickingVideo, allowPickingImage: imagePickerNAV.allowPickingImage) { (albumModel) in
            self.albumModel = albumModel
            
            ImagePickerManager.default.getAssetsFromFetchResult(result: albumModel.result, allowPickingVideo: imagePickerNAV.allowPickingVideo, allowPickingImage: imagePickerNAV.allowPickingImage) { (assets:Array<AssetModel>) in
                modelArray = assets
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            }
        }
    }
    
    // MARK: - setup subviews
    private func setupSubviews() {
        checkSelectedModels()
        DispatchQueue.main.async {
            self.setupCollectionView()
        }
    }
    
    private func setupToolBar() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let toolBarHeight = 44 + bottomSafeAreaHeight()
        toolBar = CustomToolBar(frame: CGRect(x: 0, y: view.bounds.height - toolBarHeight, width: view.bounds.width, height: toolBarHeight))
        toolBar?.backgroundColor = UIColor(hex: 0xf0f0f0)
        
        preViewButton = UIButton(type: .system)
        preViewButton?.setTitle(Bundle.lf_localizedString(forKey: "Preview"), for: .normal)
        preViewButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        preViewButton?.sizeToFit()
        preViewButton?.frame.origin.x = 15
        preViewButton?.frame.size.width = preViewButton!.frame.size.width + 20
        preViewButton?.center.y = toolBar!.contentView.bounds.height/2
        preViewButton?.setTitleColor(UIColor.darkText, for: .normal)
        preViewButton?.setTitleColor(UIColor.lightGray, for: .disabled)
        preViewButton?.addTarget(self, action: #selector(previewButtonClick), for: .touchUpInside)
        
        originalPhotoButton = UIButton(type: .custom)
        originalPhotoButton?.setTitle(" " + (Bundle.lf_localizedString(forKey: "Full image") ?? ""), for: .normal)
        originalPhotoButton?.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        originalPhotoButton?.setTitleColor(UIColor.lightGray, for: .normal)
        originalPhotoButton?.setTitleColor(UIColor.darkText, for: .selected)
        originalPhotoButton?.setImage(Bundle.lf_image(named: "photo_original_def"), for: .normal)
        originalPhotoButton?.setImage(Bundle.lf_image(named: "photo_original_sel"), for: .selected)
        originalPhotoButton?.sizeToFit()
        originalPhotoButton?.frame.origin.x = originalPhotoButton!.frame.maxX + 15
        originalPhotoButton?.center.y = toolBar!.contentView.bounds.height/2
        originalPhotoButton?.addTarget(self, action: #selector(originalPhotoButtonClick), for: .touchUpInside)
        
        originalPhotoSizeLabel = UILabel()
        originalPhotoSizeLabel?.font = UIFont.systemFont(ofSize: 15)
        originalPhotoSizeLabel?.frame = CGRect(x: originalPhotoButton!.frame.origin.x + originalPhotoButton!.frame.width + 5, y: 0, width: 100, height: toolBar!.contentView.bounds.height)
        originalPhotoSizeLabel?.textColor = UIColor.darkText
        
        doneButton = UIButton(type: .system)
        doneButton?.frame = CGRect(x: view.bounds.width - 12 - 44, y: 0, width: 44, height: 44)
        doneButton?.setTitle(Bundle.lf_localizedString(forKey: "Done"), for: .normal)
        doneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        doneButton?.setTitleColor(imagePickerNAV.doneButtonTitleColorNormal, for: .normal)
        doneButton?.setTitleColor(imagePickerNAV.doneButtonTitleColorDisabled, for: .disabled)
        doneButton?.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)
        
        selectedNumberView = UIButton(type: .system)
        selectedNumberView?.frame = CGRect(x: (doneButton?.frame.origin.x)! - 35, y: 7, width: 30, height: 30)
        selectedNumberView?.setBackgroundImage(Bundle.lf_image(named: "preview_number_icon"), for: .normal)
        selectedNumberView?.setTitleColor(UIColor.white, for: .normal)
        selectedNumberView?.imageView?.contentMode = .scaleAspectFit
        selectedNumberView?.isUserInteractionEnabled = false
        
        let sepLine = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 1))
        sepLine.backgroundColor = UIColor.lightGray
        
        toolBar?.contentView.addSubview(sepLine)
        toolBar?.contentView.addSubview(preViewButton!)
        toolBar?.contentView.addSubview(originalPhotoButton!)
        toolBar?.contentView.addSubview(originalPhotoSizeLabel!)
        toolBar?.contentView.addSubview(selectedNumberView!)
        toolBar?.contentView.addSubview(doneButton!)
        view.addSubview(toolBar!)
        
        refreshBottomToolBarStatus()
    }
    
    private func setupCollectionView() {
        let columnNumber = ImagePickerManager.default.columnNumber
        let itemWH:CGFloat = (UIScreen.main.bounds.width - CGFloat(columnNumber - 1) * kGridMargin) / CGFloat(columnNumber)
        
        let flow = UICollectionViewFlowLayout()
        flow.itemSize = CGSize(width: itemWH, height: itemWH)
        flow.minimumLineSpacing = kGridMargin
        flow.minimumInteritemSpacing = kGridMargin
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flow)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.register(AssetCell.self, forCellWithReuseIdentifier: kAssetCell)
        collectionView?.register(LFCameraCell.self, forCellWithReuseIdentifier: kLFCameraCell)
        view.addSubview(collectionView!)
    }
    
    fileprivate func refreshBottomToolBarStatus() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let couldToolBarEnable = imagePickerNAV.selectedModels.count > 0
        preViewButton?.isEnabled = couldToolBarEnable
        doneButton?.isEnabled = couldToolBarEnable
        selectedNumberView?.isHidden = !couldToolBarEnable
        selectedNumberView?.setTitle("\(imagePickerNAV.selectedModels.count)", for: .normal)
        refreshOriginalPhotoSizeLabel()
    }
    
    private func refreshOriginalPhotoSizeLabel() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let couldToolBarEnable = imagePickerNAV.selectedModels.count > 0
        originalPhotoButton?.isEnabled = couldToolBarEnable
        originalPhotoButton?.isSelected = couldToolBarEnable && imagePickerNAV.isSelectOriginalPhoto
        originalPhotoSizeLabel?.isHidden = !originalPhotoButton!.isSelected
        imagePickerNAV.isSelectOriginalPhoto ? showPhotoBytes() : ()
    }
    
    // MARK: - action
    @objc private func previewButtonClick() {
        let imagePickerNAV = navigationController as! ImagePickerController
        previewImages(imageModel: imagePickerNAV.selectedModels, index: 0)
    }
    
    @objc private func originalPhotoButtonClick() {
        let imagePickerNAV = navigationController as! ImagePickerController
        imagePickerNAV.isSelectOriginalPhoto = !imagePickerNAV.isSelectOriginalPhoto
        refreshOriginalPhotoSizeLabel()
    }
    
    func doneButtonClick() {
        let imagePickerNAV = navigationController as! ImagePickerController
        var images = imagePickerNAV.selectedModels.map { (_) -> UIImage in
            return UIImage()
        }
        
        let hud = HUD.showAdded(to: view, title: "")
        let concurrentQueue = DispatchQueue(label: "com.imagePicker.multiImages", attributes: .concurrent)
        let group = DispatchGroup()
        for item in imagePickerNAV.selectedModels {
            guard let index = imagePickerNAV.selectedModels.index(of: item) else { return }
            group.enter()
            concurrentQueue.async(group: group, execute: {
                fetchImage(asset: item.asset, index: index, completeHandler: { (image, index) in
                    if let image = image {
                        images[index] = image
                    }
                    group.leave()
                })
            })
        }
        
        group.notify(queue: DispatchQueue.main, execute: { [weak imagePickerNAV] in
            if imagePickerNAV?.singleSelectionMode == true {
                if let pickerDelegate = imagePickerNAV?.pickerDelegate, pickerDelegate.responds(to: #selector(ImagePickerControllerDelegate.imagePickerController(_:didFinishPickingPhoto:))) {
                    pickerDelegate.imagePickerController!(imagePickerNAV!, didFinishPickingPhoto: images[0])
                }
            } else {
                if let pickerDelegate = imagePickerNAV?.pickerDelegate, pickerDelegate.responds(to: #selector(ImagePickerControllerDelegate.imagePickerController(_:didFinishPickingPhotos:))) {
                    pickerDelegate.imagePickerController!(imagePickerNAV!, didFinishPickingPhotos: images)
                }
            }
            hud.hide(animated:true)
        })
        
        func fetchImage(asset:PHAsset, index:Int, completeHandler:@escaping ((_ image:UIImage?,_ index:Int)->())) {
            ImagePickerManager.default.getOriginalPhoto(withAsset: asset, isCompress: !imagePickerNAV.isSelectOriginalPhoto, completion: { (image, _) in
                if let image = image {
                    completeHandler(image, index)
                } else {
                    completeHandler(nil, -1)
                }
            })
        }
    }
    
    fileprivate func previewImages(imageModel:[AssetModel], index:Int) {
        let photoPreviewVC = ImagePreviewController()
        photoPreviewVC.currentIndex = index
        photoPreviewVC.modelArray = imageModel
        navigationController?.pushViewController(photoPreviewVC, animated: true)
        
        photoPreviewVC.backButtonClickBlock = { [weak self] in
            self?.collectionView?.reloadData()
            self?.refreshBottomToolBarStatus()
        }
        
        photoPreviewVC.doneButtonClickBlock = { [weak self] in
            self?.doneButtonClick()
        }
    }
    
    func camera() {
        func cameraAction() {
            let sysCameraVC = UIImagePickerController()
            sysCameraVC.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
            sysCameraVC.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
            sysCameraVC.sourceType = .camera
            sysCameraVC.cameraDevice = .rear
            sysCameraVC.delegate = self
            present(sysCameraVC, animated: true, completion: nil)
        }
        
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if authStatus == .authorized {
            cameraAction()
        } else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (success:Bool) in
                if success {
                    cameraAction()
                }
            }
        } else {
            let appName = Bundle.appName()
            let msg = String.init(format: "Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\"", appName)
            let alert = UIAlertController(title: "Can not use camera", message: msg, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: Bundle.lf_localizedString(forKey: "Cancel"), style: .cancel, handler: nil)
            let settingAction = UIAlertAction(title: Bundle.lf_localizedString(forKey: "Setting"), style: .default) { (_) in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - private
    func checkSelectedModels() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let selectedAssetArray = ImagePickerManager.fetchAsset(fromModelArray: imagePickerNAV.selectedModels)
        for model in modelArray {
            model.isSelected = false
            if selectedAssetArray.contains(model.asset) {
                model.isSelected = true
            }
        }
    }
    
    private func showPhotoBytes() {
        let imagePickerNAV = navigationController as! ImagePickerController
        ImagePickerManager.fetchPhotosBytes(withArray: imagePickerNAV.selectedModels) { (photoBytesLength) in
            self.originalPhotoSizeLabel?.text = "(\(photoBytesLength))"
        }
    }
}


extension ThumbnailGridController:UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (showTakePhotoBtn) {
            let imagePickerNAV = navigationController as! ImagePickerController
            if (imagePickerNAV.allowPickingImage && imagePickerNAV.allowTakePicture) {
                return modelArray.count + 1
            }
        }
        return modelArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // camera cell
        let imagePickerNAV = self.navigationController as! ImagePickerController
        if ((imagePickerNAV.sortAscendingByModificationDate && indexPath.row >= modelArray.count)
            || (!imagePickerNAV.sortAscendingByModificationDate && indexPath.row == 0) && showTakePhotoBtn) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: kLFCameraCell, for: indexPath) as! LFCameraCell
        }
        
        // asset cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kAssetCell, for: indexPath) as! AssetCell
        cell.backgroundColor = UIColor.lightGray
        var model:AssetModel = AssetModel(asset: PHAsset())
        if (imagePickerNAV.sortAscendingByModificationDate || !showTakePhotoBtn) {
            model = modelArray[indexPath.row]
        } else {
            model = modelArray[indexPath.row - 1]
        }
        cell.model = model
        
        cell.didSelectPhotoBlock = { [weak self, weak cell] (isSelected) in
            let imagePickerNAV = self?.navigationController as! ImagePickerController
            if isSelected {
                // cancel selected
                cell?.selectPhotoButton?.isSelected = false
                cell?.model?.isSelected = false
                if let index = imagePickerNAV.selectedModels.index(of: model) {
                    imagePickerNAV.selectedModels.remove(at: index)
                }
            } else {
                // selected:check if over the maxImagesCount
                if imagePickerNAV.selectedModels.count < imagePickerNAV.maxImagesCount {
                    cell?.selectPhotoButton?.isSelected = true
                    cell?.model?.isSelected = true
                    imagePickerNAV.selectedModels.append(model)
                } else {
                    imagePickerNAV.promptSelectPhotoBeyondUpperLimit()
                }
            }
            self?.refreshBottomToolBarStatus()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // take photo
        let imagePickerNAV = self.navigationController as! ImagePickerController
        if ((imagePickerNAV.sortAscendingByModificationDate && indexPath.row >= modelArray.count) ||
            (!imagePickerNAV.sortAscendingByModificationDate && indexPath.row == 0)  && showTakePhotoBtn) {
            camera()
            return
        }
        
        // preview images
        var index = indexPath.row;
        if (!imagePickerNAV.sortAscendingByModificationDate && showTakePhotoBtn) {
            index = indexPath.row - 1;
        }
        previewImages(imageModel: modelArray, index: index)
    }
}

extension ThumbnailGridController:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let type = info[UIImagePickerControllerMediaType] as? NSString,
            let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                return
        }
        
        if type.isEqual(to: "public.image") {
            ImagePickerManager.default.savePhoto(withImage: image, completeHandler: { (success, error) in
                if success {
                    self.reloadCameraRollAlbumData()
                } else {
                    assert(false, "cannot save images")
                }
            })
        }
    }
    
}

