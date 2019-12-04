//
//  PhotoViewController.swift
//  SimpleCamera
//
//  Created by Simon Ng on 16/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func save(sender: UIButton) {
        guard let imageToSave = image else { return }
        
        //呼叫 UIImageWriteToSavedPhotosAlbum 儲存靜態圖片至相機膠卷
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
}
