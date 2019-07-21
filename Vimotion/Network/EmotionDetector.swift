//
//  EmotionDetector.swift
//  Vimotion
//
//  Created by Elazar Yifrach on 20/07/2019.
//  Copyright © 2019 Elaz. All rights reserved.
//

import Foundation
import PromiseKit
import AVFoundation

enum EmotionDetectorError: LocalizedError {
    case noFaceDetected
    case imagePreprocessFailed
    case noInternetConnection
    case parseError
    case apiKeyMissing
    
    var errorDescription: String? {
        return localizedDescription
    }
    var localizedDescription: String {
        switch self {
        case .noFaceDetected:
            return "No faces were detected in the selected photo."
        case .imagePreprocessFailed:
            return "There was an issue with the image you provided. Please try another photo."
        case .noInternetConnection:
            return "This app requires an internet connection. Please check that you are connected and try again."
        case .parseError:
            return "There was an error trying to parse the face detection result."
        case .apiKeyMissing:
            return "No api key is present in the info.plist file. See readme in repo for details."
        }
    }
}

class EmotionDetector {
    
    let reachability = NetworkReachabilityManager()
    let imageSize: CGSize
    fileprivate let detectionURL = URL(string: "https://eastus.api.cognitive.microsoft.com/face/v1.0/detect?returnFaceAttributes=emotion")!
    
    init(with imageSize: CGSize) {
        self.imageSize = imageSize
        reachability?.startListening()
    }
    
    func detectEmotion(in image: UIImage) -> Promise<(UIImage, String)> {
        return firstly { () -> Promise<UIImage> in
            guard let reach = reachability?.isReachable, reach else {
                throw EmotionDetectorError.noInternetConnection
            }
            return downsample(image)
        }.then { downsampledImage -> Promise<(URLRequest, UIImage)> in
            return Promise<(URLRequest, UIImage)> { seal in
                self.faceDetectionRequest(with: downsampledImage)
                .done { request in
                    seal.fulfill((request, downsampledImage))
                }.catch { error in
                    seal.reject(error)
                }
            }
        }.then { request ,downsampledImage -> Promise<(EmotionAPIDetectResult, UIImage)> in
            return Promise { seal in
                Alamofire.request(request)
                    .responseData() { response in
                        switch response.result {
                        case .success(let data):
                            guard let detection = try? JSONDecoder().decode([EmotionAPIDetectResult].self, from: data) else {
                                seal.reject(EmotionDetectorError.parseError)
                                return
                            }
                            guard detection.count > 0 else {
                                seal.reject(EmotionDetectorError.noFaceDetected)
                                return
                            }
                            seal.fulfill((self.largestFace(in: detection), downsampledImage))
                        case .failure(let e):
                            // transform error
                            seal.reject(e)
                        }
                }
            }
        }.then(on: .main) { detection, downsampledImage -> Guarantee<(UIImage, String)> in
            return Guarantee { seal in
                seal((self.croppedImage(for: detection, image: downsampledImage),
                      detection.faceAttributes.emotion.mostPowerfulEmotion()))
            }
        }
    }
    
    fileprivate func downsample(_ image: UIImage) -> Promise<UIImage> {
        
        return Promise { seal in
            let rect = AVMakeRect(aspectRatio: image.size,
                                  insideRect: CGRect(origin: .zero, size: imageSize))
            
            UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
            image.draw(in: rect)
            guard let imageResult = UIGraphicsGetImageFromCurrentImageContext() else {
                seal.reject(EmotionDetectorError.imagePreprocessFailed)
                return
            }
            seal.fulfill(imageResult)
        }
    }
    
    fileprivate func croppedImage(for detection: EmotionAPIDetectResult, image: UIImage) -> UIImage {
        let faceRect = CGRect(x: CGFloat(detection.faceRectangle.left),
                              y: CGFloat(detection.faceRectangle.top),
                              width: CGFloat(detection.faceRectangle.width),
                              height: CGFloat(detection.faceRectangle.height))
        let imageRect = CGRect(x: -faceRect.minX,
                               y: -faceRect.minY,
                               width: image.size.width * image.scale,
                               height: image.size.height * image.scale)
        UIGraphicsBeginImageContext(faceRect.size)
        image.draw(in: imageRect)
        let cropResult = UIGraphicsGetImageFromCurrentImageContext()!
        return cropResult
    }
    
    fileprivate func faceDetectionRequest(with image: UIImage) -> Promise<URLRequest> {
        return Promise { seal in
            guard   let apiKey = Bundle.main.object(forInfoDictionaryKey: "FaceAPIKey") as? String,
                        apiKey.isEmpty == false else {
                seal.reject(EmotionDetectorError.apiKeyMissing)
                return
            }
            var request = URLRequest(url: detectionURL)
            request.httpMethod = "POST"
            request.addValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.httpBodyStream = InputStream(data: image.jpegData(compressionQuality: 1.0)!)
            seal.fulfill(request)
        }
    }
    
    fileprivate func largestFace(in detections: [EmotionAPIDetectResult]) -> EmotionAPIDetectResult {
        if detections.count == 1 {
            return detections[0]
        }
        return detections.max { a, b in
            a.faceRectangle.width * a.faceRectangle.height <
            b.faceRectangle.width * b.faceRectangle.height
        }!
    }
    
}
