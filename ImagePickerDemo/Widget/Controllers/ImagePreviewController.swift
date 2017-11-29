//
//  ImagePreviewController.swift
//  epcmobile-ios
//
//  Created by LioWu on 19/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

let previewViewCellMargin:CGFloat = 10
let previewViewCellSize:CGSize = CGSize(width: UIScreen.main.bounds.width-previewViewCellMargin, height: UIScreen.main.bounds.height)
private let kImagePreviewCell = "ImagePreviewCell"

/// preview
class ImagePreviewController: UIViewController {
    var currentIndex:Int = 0
    var modelArray:Array<AssetModel>?
    
    var collectionView:UICollectionView?
    
    var navBar:CustomBaseNavBar?
    var backButton:UIButton?
    var selectButton:UIButton?
    
    var toolBar:CustomToolBar?
    var editButton:UIButton?
    var originalPhotoButton:UIButton?
    var originalPhotoSizeLabel:UILabel?
    var doneButton:UIButton?
    var selectedNumberView:UIButton?
    
    var backButtonClickBlock:(()->())?
    var doneButtonClickBlock:(()->())?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupCustomNavBar()
        setupBottomToolBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        collectionView?.setContentOffset(CGPoint(x:view.bounds.width * CGFloat(currentIndex),y:0), animated: false)
        refreshNaviBarAndBottomBarState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - setup subviews
    private func setupCollectionView() {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        flow.itemSize = previewViewCellSize
        flow.minimumLineSpacing = previewViewCellMargin
        flow.minimumInteritemSpacing = previewViewCellMargin
        flow.sectionInset = UIEdgeInsetsMake(0, previewViewCellMargin/2, 0, previewViewCellMargin/2)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flow)
        collectionView?.backgroundColor = UIColor.black
        collectionView?.isPagingEnabled = true
        collectionView?.bounces = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.register(ImagePreviewCell.self, forCellWithReuseIdentifier: kImagePreviewCell)
        view.addSubview(collectionView!)
    }
    
    private func setupCustomNavBar() {
        let imagePickerNAV = navigationController as! ImagePickerController
        navBar = CustomBaseNavBar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: navBarHeight()))
        navBar?.backgroundColor = UIColor(hex: 0x222222).withAlphaComponent(0.7)
        view.addSubview(navBar!)
    
        backButton = UIButton(frame: CGRect(x: 10, y: 0, width: 44, height: 44))
        backButton?.setImage(Bundle.lf_image(named: "navi_back"), for: .normal)
        backButton?.setTitleColor(UIColor.white, for: .normal)
        backButton?.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)
        
        selectButton = UIButton(frame: CGRect(x: navBar!.bounds.width - 70, y: 0, width: navBar!.contentView.bounds.height, height: navBar!.contentView.bounds.height))
        selectButton?.isHidden = imagePickerNAV.singleSelectionMode
        selectButton?.setImage(UIImage.pickerImage(photoSelectedImageName), for: .selected)
        selectButton?.setImage(UIImage.pickerImage(photoDeselectedImageName), for: .normal)
        selectButton?.addTarget(self, action: #selector(selectClick), for: .touchUpInside)
        
        navBar?.contentView.addSubview(backButton!)
        navBar?.contentView.addSubview(selectButton!)
    }
    
    private func setupBottomToolBar() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let toolBarHeight = 44 + bottomSafeAreaHeight()
        toolBar = CustomToolBar(frame: CGRect(x: 0, y: view.bounds.height - toolBarHeight, width: view.bounds.width, height: toolBarHeight))
        toolBar?.backgroundColor = UIColor(hex: 0x222222).withAlphaComponent(0.7)
        
        editButton = UIButton(type: .system)
        editButton?.frame = CGRect(x: 12, y: 0, width: 44, height: 44)
        editButton?.setTitle(Bundle.lf_localizedString(forKey: "Edit"), for: .normal)
        editButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        editButton?.setTitleColor(UIColor.white, for: .normal)
        
        originalPhotoButton = UIButton(type: .custom)
        originalPhotoButton?.setTitle(" " + (Bundle.lf_localizedString(forKey: "Full image") ?? ""), for: .normal)
        originalPhotoButton?.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        originalPhotoButton?.setTitleColor(UIColor.lightGray, for: .normal)
        originalPhotoButton?.setTitleColor(UIColor.white, for: .selected)
        originalPhotoButton?.setImage(Bundle.lf_image(named: "photo_original_def"), for: .normal)
        originalPhotoButton?.setImage(Bundle.lf_image(named: "photo_original_sel"), for: .selected)
        originalPhotoButton?.sizeToFit()
        originalPhotoButton?.frame.origin.x = 15
        originalPhotoButton?.center.y = toolBar!.contentView.bounds.height/2
        originalPhotoButton?.addTarget(self, action: #selector(originalPhotoButtonClick), for: .touchUpInside)
        
        originalPhotoSizeLabel = UILabel()
        originalPhotoSizeLabel?.font = UIFont.systemFont(ofSize: 15)
        originalPhotoSizeLabel?.frame = CGRect(x: originalPhotoButton!.frame.origin.x + originalPhotoButton!.frame.width + 5, y: 0, width: 100, height: toolBar!.contentView.bounds.height)
        originalPhotoSizeLabel?.textColor = UIColor.white
        
        doneButton = UIButton(type: .system)
        doneButton?.frame = CGRect(x: view.bounds.width - 12 - 44, y: 0, width: 44, height: 44)
        doneButton?.setTitle(Bundle.lf_localizedString(forKey: "Done"), for: .normal)
        doneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        doneButton?.setTitleColor(imagePickerNAV.doneButtonTitleColorNormal, for: .normal)
        doneButton?.setTitleColor(imagePickerNAV.doneButtonTitleColorDisabled, for: .disabled)
        doneButton?.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)
        
        if imagePickerNAV.singleSelectionMode == false {
            selectedNumberView = UIButton(type: .system)
            selectedNumberView?.frame = CGRect(x: (doneButton?.frame.origin.x)! - 35, y: 7, width: 30, height: 30)
            selectedNumberView?.setBackgroundImage(Bundle.lf_image(named: "preview_number_icon"), for: .normal)
            selectedNumberView?.setTitleColor(UIColor.white, for: .normal)
            selectedNumberView?.imageView?.contentMode = .scaleAspectFit
            selectedNumberView?.isUserInteractionEnabled = false
            selectedNumberView?.isHidden = true
            toolBar?.contentView.addSubview(selectedNumberView!)
        }
        
        toolBar?.contentView.addSubview(originalPhotoButton!)
        toolBar?.contentView.addSubview(originalPhotoSizeLabel!)
        toolBar?.contentView.addSubview(doneButton!)
        view.addSubview(toolBar!)
    }

    // MARK: - refresh
    func refreshNaviBarAndBottomBarState() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let model = modelArray?[currentIndex]
        selectButton?.isSelected = model?.isSelected ?? false
        
        if imagePickerNAV.singleSelectionMode
            || (imagePickerNAV.selectedModels.count > 0) {
            doneButton?.isEnabled = true
            selectedNumberView?.isHidden = false
            selectedNumberView?.setTitle("\(imagePickerNAV.selectedModels.count)", for: .normal)
        } else {
            doneButton?.isEnabled = false
            selectedNumberView?.isHidden = true
        }
        refreshOriginalPhotoSizeLabel()
    }
    
    private func refreshOriginalPhotoSizeLabel() {
        let imagePickerNAV = navigationController as! ImagePickerController
        originalPhotoButton?.isSelected = imagePickerNAV.isSelectOriginalPhoto
        originalPhotoSizeLabel?.isHidden = !imagePickerNAV.isSelectOriginalPhoto
        imagePickerNAV.isSelectOriginalPhoto ? showPhotoBytes() : ()
    }
    
    // MARK: - action
    @objc private func backButtonClick() {
        backButtonClickBlock?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func selectClick() {
        let imagePickerNAV = navigationController as! ImagePickerController
        let model = modelArray![currentIndex]
        if selectButton?.isSelected == true {
            // cancel selected
            selectButton?.isSelected = false
            model.isSelected = false
            if let index = imagePickerNAV.selectedModels.index(of: model) {
                imagePickerNAV.selectedModels.remove(at: index)
            }
        } else {
            // selected:check if over the maxImagesCount
            if imagePickerNAV.selectedModels.count < imagePickerNAV.maxImagesCount {
                selectButton?.isSelected = true
                selectButton?.imageView?.showOscillatoryAnimation()
                model.isSelected = true
                imagePickerNAV.selectedModels.append(model)
            } else {
                imagePickerNAV.promptSelectPhotoBeyondUpperLimit()
            }
        }
        
        if imagePickerNAV.selectedModels.count > 0 {
            selectedNumberView?.showOscillatoryAnimation()
        }
        
        refreshNaviBarAndBottomBarState()
    }
    
    func previewViewTap() {
        guard let navBar = navBar,
            let toolBar = toolBar else {
            return
        }
        navBar.isHidden = !navBar.isHidden
        toolBar.isHidden = !toolBar.isHidden
    }
    
    @objc private func originalPhotoButtonClick() {
        let imagePickerNAV = navigationController as! ImagePickerController
        imagePickerNAV.isSelectOriginalPhoto = !imagePickerNAV.isSelectOriginalPhoto
        refreshOriginalPhotoSizeLabel()
    }
    
    @objc private func doneButtonClick() {
        let imagePickerNAV = navigationController as! ImagePickerController
        if imagePickerNAV.singleSelectionMode == true {
            imagePickerNAV.selectedModels.append(modelArray![currentIndex])
            doneButtonClickBlock?()
        } else {
            doneButtonClickBlock?()
        }
    }
    
    // MARK: - private 
    func showPhotoBytes() {
        if let modelArray = modelArray {
            ImagePickerManager.fetchPhotosBytes(withArray: [modelArray[currentIndex]]) { (photoBytesLength) in
                self.originalPhotoSizeLabel?.text = "(\(photoBytesLength))"
            }
        }
    }
}

extension ImagePreviewController:UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return modelArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kImagePreviewCell, for: indexPath) as? ImagePreviewCell else {
                return UICollectionViewCell()
        }
        cell.assetModel = modelArray?[indexPath.row]
        cell.previewView?.singleTapBlock = { [weak self] in
            self?.previewViewTap()
        }
        return cell
    }
}

extension ImagePreviewController:UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var offsetWidth = scrollView.contentOffset.x
        offsetWidth = offsetWidth +  10
        let tCurrentIndex = Int(offsetWidth / view.bounds.width)
        if tCurrentIndex != currentIndex {
            currentIndex = tCurrentIndex
            refreshNaviBarAndBottomBarState()
        }
    }
}
