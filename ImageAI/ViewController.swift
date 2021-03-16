//
//  ViewController.swift
//  ImageAI
//
//  Created by cmStudent on 2021/01/05.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController {
    
    /// 写真を表示するimageView
    @IBOutlet weak var photoDisplay: UIImageView!
    
    /// 写真の説明
    @IBOutlet weak var photoExplanation: UITextView!
    
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        // カメラか写真か
        imagePicker.sourceType = .camera
        
    }
    
    @IBAction func photoAction(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }

}

/// UIImagePickerの処理
extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let userSelectedImage = info[.originalImage] as? UIImage {
            
            photoDisplay.image = userSelectedImage
            
        }
        
        // imagePickerを非表示にdismiss
        // completion終わった時に何か処理をするか
        imagePicker.dismiss(animated: true, completion: nil)
        
        imageInference(image: (info[.originalImage] as? UIImage)!)
    }
    
    /// 画像の推定
    func imageInference(image: UIImage) {
        
        // let model = VNCoreMLModel(for: Resnet50().model)
        // CoreMLを使うためにVNCoreMLModelクラスのコンストラクタを使って引数にどのモデルを使うのか問いうデータを与える
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            
            fatalError("モデルをロードできません")
            
        }
        
        // リクエストの生成にはVisionフレームワークのVNCoreMLRequestコンストラクタを使って上のmodelをベースにしたリクエストを作る
        let request = VNCoreMLRequest(model: model) {
            
            [weak self] request, error in
            
            guard let results = request.results as? [VNClassificationObservation],
            
            let firstResult = results.first else {
                
                fatalError("判定をできません")
                
            }
            
            DispatchQueue.main.async {
                
                self?.photoExplanation.text = "Accuracy : \(Int(firstResult.confidence * 100))% \n\nDetail : \(firstResult.identifier)"
                
                // 結果を読み上げるコード
                let utterWords = AVSpeechUtterance(string: (self?.photoExplanation.text)!)
                
                // 英語なら"en-us" 日本語なら"ja-jp"
                utterWords.voice = AVSpeechSynthesisVoice(language: "en-us")
                
                let synthesizer = AVSpeechSynthesizer()
                
                synthesizer.speak(utterWords)
            }
            
        }
        
        guard let ciImage = CIImage(image: image) else {
            
            fatalError("画像を変換できません")
            
        }
        
        // リクエストハンドラーの生成にはVNImageRequestHandlerコンストラクタで引数で判定をしたい画像を与えて
        // カメラで撮った画像をciImageクラスのデータ型に変換している
        let imageHandler = VNImageRequestHandler(ciImage: ciImage)
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            do {
                
                // imageHandlerのperformメソッドを使ってrequestを実行する
                try imageHandler.perform([request])
                
            } catch {
                
                print("エラー \(error)")
                
            }
            
        }
        
    }
}

