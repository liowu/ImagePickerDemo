//
//  AlbumController.swift
//  epcmobile-ios
//
//  Created by LioWu on 19/05/2017.
//  Copyright © 2017年 expedia. All rights reserved.
//

import UIKit

private let kLFAlbumCell = "LFAlbumCell"

// album list
class AlbumController:UIViewController {
    var albumDataSource:Array<LFAlbumModel>?
    
    lazy var tableView:UITableView = {
        let tabView = UITableView(frame: CGRect.zero, style: .plain)
        tabView.rowHeight = 70
        tabView.delegate = self
        tabView.dataSource = self
        tabView.register(LFAlbumCell.self, forCellReuseIdentifier: kLFAlbumCell)
        tabView.tableFooterView = UIView()
        return tabView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imagePickerNAV = navigationController as! ImagePickerController
        view.backgroundColor = UIColor.white
        navigationItem.title = imagePickerNAV.allowPickingImage ?
            Bundle.lf_localizedString(forKey: "Photos") :
            Bundle.lf_localizedString(forKey: "Video")
        
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: imagePickerNAV.cancelBtnTitleStr,
                            style: .plain,
                            target: imagePickerNAV,
                            action: #selector(imagePickerNAV.cancelButtonClick))
        
        navigationItem.backBarButtonItem =
            UIBarButtonItem(title: Bundle.lf_localizedString(forKey: "Back"),
                            style: .plain,
                            target: nil,
                            action: nil)
        
        view.addSubview(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: navBarHeight(), width: view.bounds.width, height: view.bounds.size.height - navBarHeight() - bottomSafeAreaHeight())
    }
    
    func reloadData() {
        let imagePickerNAV = navigationController as! ImagePickerController
        ImagePickerManager.default.getAllAlbums(allowPickingVideo: imagePickerNAV.allowPickingVideo, allowPickingImage: imagePickerNAV.allowPickingImage) { (albums:Array<LFAlbumModel>) in
            albumDataSource = albums
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AlbumController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumDataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kLFAlbumCell) as! LFAlbumCell
        cell.albumModel = albumDataSource?[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let albumModel = albumDataSource?[indexPath.row] else { return }
        
        let imagePickerNAV = navigationController as! ImagePickerController
        let photoPickerVC = ThumbnailGridController()
        photoPickerVC.isFirstAppear = true
        photoPickerVC.columnNumber = imagePickerNAV.columnNumber
        photoPickerVC.albumModel = albumModel
        navigationController?.pushViewController(photoPickerVC, animated: true)
    }
}
