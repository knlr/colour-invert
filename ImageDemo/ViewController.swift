//
//  ViewController.swift
//  ImageDemo
//
//  Created by Knut Lorenzen on 30/01/2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet private weak var filterSettingSwitch: UISwitch!
    private lazy var session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var videoFilter: ColorInvertCIRenderer?
    private lazy var queue = DispatchQueue(label: "AV data queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    private weak var previewMetalView: PreviewMetalView?

    private var enableFilter: Bool = true {
        didSet {
            if enableFilter {
                videoFilter = ColorInvertCIRenderer()
            }
            else {
                videoFilter = nil
            }
        }
    }

    @IBAction private func filterSettingChanged() {

        enableFilter = filterSettingSwitch.isOn
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        previewMetalView = (view as! PreviewMetalView)
        previewMetalView?.rotation = .rotate90Degrees
        AVCaptureDevice.requestAccess(for: .video) {

            if $0 {
                DispatchQueue.main.async {
                    self.startCapture()
                }
            }
        }
        enableFilter = filterSettingSwitch.isOn
    }



   private func startCapture() {

        guard let device = AVCaptureDevice.default(for: .video)
        else { return }
        //        guard let device = AVCaptureDevice.devices(for: .video).first(where: { $0.position == .front })
//        else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {

                session.addInput(input)
                session.startRunning()
            }
            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            }
        }
        catch {
            print(error)
        }
    }
}



extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }

        var finalVideoPixelBuffer = videoPixelBuffer
        if let filter = videoFilter {
            if !filter.isPrepared {
                /*
                 outputRetainedBufferCountHint is the number of pixel buffers the renderer retains. This value informs the renderer
                 how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
                 */
                filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }

            // Send the pixel buffer through the filter
            guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }

            finalVideoPixelBuffer = filteredBuffer
        }
        
        previewMetalView?.pixelBuffer = finalVideoPixelBuffer
    }
}
