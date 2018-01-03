//
//  MemeViewController.swift
//  MEMESampler
//
//  Created by tanaka.takaaki on 2016/12/08.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import AVFoundation
import AudioToolbox
import MEMELib
import UIKit

class MemeViewController: UIViewController {

    var device: AVCaptureDevice!
    var session: AVCaptureSession!
    var output: AVCaptureVideoDataOutput!
    
    var image: UIImage?
    
    var before: Date?
    
    weak var presenter: MEMEPresenter?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        session = AVCaptureSession()
        
        for d in AVCaptureDevice.devices() {
            if (d as AnyObject).position == AVCaptureDevicePosition.back {
                device = d as? AVCaptureDevice
                print("\(device!.localizedName) found.")
            }
        }
        
        // バックカメラからキャプチャ入力生成
        let input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            print("Caught exception!")
            return
        }
        session.addInput(input)
        //output = AVCaptureStillImageOutput()
        
        output = AVCaptureVideoDataOutput()
        // ピクセルフォーマットを 32bit BGR + A とする
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        
        // フレームをキャプチャするためのサブスレッド用のシリアルキューを用意
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        output.alwaysDiscardsLateVideoFrames = true
        
        
        
        session.addOutput(output)
        session.sessionPreset = AVCaptureSessionPresetHigh
        // プレビューレイヤを生成
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
        
        // セッションを開始
        session.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter?.didDisconnected = { [weak self] _ in
            self?.dismiss(animated: true, completion: {
                print("JINS MEME Disconnected")
            })
        }
        presenter?.didReceiveMemeRealTimeData = { [weak self] data in
            if data.pitch > 50 || data.pitch < -70 {
                print("sleep")
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            
            if data.blinkSpeed > 0 {
                print("blinkSpeed: \(data.blinkSpeed)")
                
                let now = Date()
                
                if let date = self?.before {
                    
                    let ti = now.timeIntervalSince(date)
                    
                    print("ti: \(ti)")
                    
                    if ti < 0.3 {
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                        self?.shot()
                    }
                }
                
                self?.before = now
            }
            
            if data.blinkStrength > 0 {
                print("blinkStrength: \(data.blinkStrength)")
            }
        }
    }
    
    func shot() {
        let connection = output.connection(withMediaType: AVMediaTypeVideo)

        if let image = self.image {
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        }
    }
    
    // sampleBufferからUIImageを作成
    func captureImage(sampleBuffer: CMSampleBuffer) -> UIImage {
        
        // Sampling Bufferから画像を取得
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        
        
        // 色空間
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent:Int = 8
        // swift 2.0
        let newContext:CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)!
        
        let imageRef: CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultImage
    }
}

extension MemeViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // キャプチャしたsampleBufferからUIImageを作成
        let image: UIImage = self.captureImage(sampleBuffer: sampleBuffer)
        
        // 画像を画面に表示
        self.image = image
    }
}
