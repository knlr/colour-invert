//
//  ViewController.swift
//  ImageDemo
//
//  Created by Knut Lorenzen on 30/01/2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    lazy var session = AVCaptureSession()
    private var metalView: PreviewMetalView { return view as! PreviewMetalView}


    override func viewDidLoad() {
        super.viewDidLoad()

        AVCaptureDevice.requestAccess(for: .video) {

            if $0 {
                DispatchQueue.main.async {
                    self.startCapture()
                }
            }
        }
    }




    func startCapture() {

//        let output = AVCapturePhotoOutput()
//        session.sessionPreset = .high
//        guard let device = AVCaptureDevice.default(for: .video)
//        else { return }
//        //        guard let device = AVCaptureDevice.devices(for: .video).first(where: { $0.position == .front })
////        else { return }
//
//        do {
//            let input = try AVCaptureDeviceInput(device: device)
//            if session.canAddInput(input) &&
//                session.canAddOutput(output) {
//
//                session.addInput(input)
//                session.addOutput(output)
//
//                let layer = AVCaptureVideoPreviewLayer(session: session)
//                previewLayer = layer
//                layer.videoGravity = .resizeAspectFill
//                view.layer.addSublayer(layer)
//
//                session.startRunning()
//            }
//        }
//        catch {
//            print(error)
//        }
    }
}

