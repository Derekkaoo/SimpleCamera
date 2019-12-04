//
//  SimpleCameraController.swift
//  SimpleCamera
//
//  Created by Simon Ng on 16/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation

class SimpleCameraController: UIViewController {

    @IBOutlet var cameraButton:UIButton!
    
    let captureSession = AVCaptureSession()
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice!
    var stillImageOutput: AVCapturePhotoOutput!
    var stillImage: UIImage?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    //實現相機切換的手勢
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    //實現 zoomIn 的手勢
    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
    
    //實現 zoomOut 的手勢
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - Action methods
    
    @IBAction func capture(sender: UIButton) {
        //照片設定
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])
        
        //是否需要啟用圖片穩定性
        photoSettings.isAutoStillImageStabilizationEnabled = true
        
        //是否高解析度
        photoSettings.isHighResolutionPhotoEnabled = true
        
        //閃光燈模式
        photoSettings.flashMode = .auto
        
        stillImageOutput.isHighResolutionCaptureEnabled = true
        
        //開始擷取圖片
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    // MARK: - Segues
    
    @IBAction func unwindToCameraView(segue: UIStoryboardSegue) {
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            let photoViewController = segue.destination as! PhotoViewController
            photoViewController.image = stillImage
        }
    }
}

//設定 session
extension SimpleCameraController {
    private func configure() {
        //以高解析度照相來預設 session
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        //取得前後鏡頭來拍照
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
            }
        }
        
        currentDevice = backFacingCamera
        
        //以 currentDevice 建立一個 AVCaptureDeviceInput 的實例，就可以從裝置擷取資料
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else { return }
        
        //設置輸出的 session 為擷取靜態圖片 (用來擷取靜態圖片)
        stillImageOutput = AVCapturePhotoOutput()
        
        //輸入與輸出裝置的 session 設置
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(stillImageOutput)
        
        //提供相機預覽
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        
        //將相機按鈕移到前面
        view.bringSubview(toFront: cameraButton)
        
        captureSession.startRunning()
        
        //相機辨識器的切換
        toggleCameraGestureRecognizer.direction = .up
        toggleCameraGestureRecognizer.addTarget(self, action: #selector(toggleCamera))
        view.addGestureRecognizer(toggleCameraGestureRecognizer)
        
        //辨識器放大
        zoomInGestureRecognizer.direction = .right
        zoomInGestureRecognizer.addTarget(self, action: #selector(zoomIn))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        //辨識器縮小
        zoomOutGestureRecognizer.direction = .left
        zoomOutGestureRecognizer.addTarget(self, action: #selector(zoomOut))
        view.addGestureRecognizer(zoomOutGestureRecognizer)
    }
}

extension SimpleCameraController: AVCapturePhotoCaptureDelegate {
    //擷取完成呼叫 didFinishProcessingPhoto ，先檢查是否有錯誤，擷取到的照片會在 photo ，呼叫 fileDataRepresentation() 存取圖片
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { return }
        
        //從照片緩衝區取得圖片
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        stillImage = UIImage(data: imageData)
        
        performSegue(withIdentifier: "showPhoto", sender: self)
    }
}

//手勢執行的 function
extension SimpleCameraController {
    //相機前後變換
    @objc func toggleCamera() {
        //切換 session 的輸入裝置 Start
        captureSession.beginConfiguration()
        
        //依照目前的相機變更裝置
        guard let newDevice = currentDevice.position == AVCaptureDevice.Position.back ? frontFacingCamera : backFacingCamera else { return }
        
        //從 session 中移除所有的輸入
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        //變更為新的輸入
        let cameraInput: AVCaptureDeviceInput
        
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
        //切換 session 的輸入裝置 End
    }
    
    //鏡頭放大
    @objc func zoomIn() {
        //改變縮放程度，需要調整 videoZoomFactor
        if let zoomFactor = currentDevice?.videoZoomFactor {
            //檢查縮放因子是否大於 5.0 (相機 App 只支援 5x 倍率)
            if zoomFactor < 5.0 {
                let newZoomFactor = min(zoomFactor + 1.0, 5.0)
                do {
                    //改變屬性前，要先取得鎖
                    try currentDevice.lockForConfiguration()
                    //呼叫 rampToVideoZoomFactor 加上新的縮放因子來完成縮放效果
                    currentDevice.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    //完成後，再將鎖解開
                    currentDevice.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    //鏡頭縮小
    @objc func zoomOut() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor > 1.0 {
                let newZoomFactor = max(zoomFactor - 1.0, 1.0)
                do {
                    try currentDevice.lockForConfiguration()
                    currentDevice.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
}
