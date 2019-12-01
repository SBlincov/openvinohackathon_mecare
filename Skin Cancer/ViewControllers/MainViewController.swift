//
//  MainViewController.swift
//  Skin Cancer
//
//  Created by Blintsov Sergey on 01/12/2019.
//  Copyright © 2019 Blintsov Sergey. All rights reserved.
//

import UIKit
import CoreML
import Vision

class MainViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var scene: UIImageView!
    @IBOutlet weak var answerLabel: UILabel!
    
    @IBAction func camButtonTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        imagePicker.allowsEditing = true
        
        imagePicker.showsCameraControls = true
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pickImage(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        present(pickerController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        guard let image = UIImage(named: "example_photo") else {
            fatalError("no starting image")
        }
        
        scene.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("couldn't convert UIImage to CIImage")
        }
        
        detectScene(image: ciImage)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        var isOriginalImage = true
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Pizdec")
        }
        scene.image = image
        
        var imageEdited = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if info[UIImagePickerControllerEditedImage] != nil {
            imageEdited = info[UIImagePickerControllerEditedImage] as? UIImage
        } else {
            imageEdited = nil
        }
        
        if info[UIImagePickerControllerEditedImage] != nil {
            scene.image = info[UIImagePickerControllerEditedImage] as? UIImage
            isOriginalImage = false
        } else {
            if info[UIImagePickerControllerOriginalImage] != nil {
                scene.image = info[UIImagePickerControllerOriginalImage] as? UIImage
            } else {
                fatalError("couldn't load image from Photos")
            }
        }
       
        guard let ciImage = CIImage(image: image) else {
            fatalError("couldn't convert UIImage to CIImage")
        }
        
        var ciImageEdited = CIImage(image: image)
        
        if isOriginalImage == false {
            ciImageEdited = CIImage(image: imageEdited!)
        }
        if isOriginalImage == true {
            detectScene(image: ciImage)
        } else {
            detectScene(image: ciImageEdited!)
        }
    }
    
    func detectScene(image: CIImage) {
        answerLabel.text = "detecting scene..."
        
        guard let model = try? VNCoreMLModel(for: melanoma().model) else {
            fatalError("can't load Places ML model")
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("unexpected result type from VNCoreMLRequest")
            }
            
            DispatchQueue.main.async { [weak self] in
                if topResult.confidence * 100 < 90.0 {
                    self?.answerLabel.text = "Не вижу родинку на фотографии"
                }
                if topResult.identifier == "malignant" && topResult.confidence * 100 >= 90.0 {
                    self?.answerLabel.text = "Злокачественная родинка! Вероятность: \(topResult.confidence*100)%"
                }
                if topResult.identifier == "benign" && (topResult.confidence * 100) > 40.0 {
                    self?.answerLabel.text = "Это обычная родинка."
                }
                
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
}
