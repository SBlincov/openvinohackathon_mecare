//
//  RealTime detection.swift
//  Skin Cancer
//
//  Created by Blintsov Sergey on 01/12/2019.
//  Copyright © 2019 Blintsov Sergey. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Vision

class RealtimeDetection: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var resNeuro: UILabel!
    
    @IBAction func didPressedBackButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {return}
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)

        setupIdentifierConfidenceLabel()
        
    }

    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    var goodRes = 0
    var badRes = 0
    var countRes = 0
    var isBenign = true
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("Camera was able to capture a frame:", Date())
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: melanoma().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                self.resNeuro.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)"
                if firstObservation.confidence * 100 < 80.0 {
                    self.identifierLabel.text = "Не вижу родинку на фотографии"
                }
                
                if firstObservation.identifier == "malignant" && (firstObservation.confidence * 100) > 90.0 {
                    self.countRes += 1
                } else {
                    self.countRes = 0
                }
                if self.countRes > 5 {
                    self.identifierLabel.text = "Это очень похоже на меланому"
                }
                
                if firstObservation.identifier == "benign" && (firstObservation.confidence * 100) > 40.0 {
                    self.goodRes += 1
                } else {
                    self.goodRes = 0
                }
                if self.goodRes > 2 {
                    self.identifierLabel.text = "Это обычная родинка :)"
                }
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
