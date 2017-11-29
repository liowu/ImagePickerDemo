//
//  ViewController.swift
//  ImagePickerDemo
//
//  Created by LioWu on 29/11/2017.
//  Copyright © 2017 Expedia. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ImagePickerControllerDelegate {
    
    @IBOutlet weak var imgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(hex:0xc0c0c0)
        
//        let testButton = UIButton(frame: CGRect(x: 50, y: 50, width: 80, height: 80))
//        testButton.backgroundColor = UIColor.red
//        view.addSubview(testButton)
    }
    
    @IBAction func camera(_ sender: Any) {
        let imagePickerNav = ImagePickerController(maxImagesCount: 9, columnNumber: 3, delegate: self, pushPhotoPickerVC: true)
        self.present(imagePickerNav, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(_ picker: ImagePickerController, didFinishPickingPhoto photo: UIImage) {
        imgView.image = photo
        picker.dismiss(animated: true, completion: nil)
        
        print(photo)
    }
    
    func imagePickerController(_ picker: ImagePickerController, didFinishPickingPhotos photos: [UIImage]) {
        imgView.image = photos[0]
        picker.dismiss(animated: true, completion: nil)
        
        print(photos)
    }
    
    func imagePickerControllerCancel(_ picker: ImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
