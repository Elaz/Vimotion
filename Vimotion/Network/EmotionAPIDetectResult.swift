//
//  EmotionAPIDetectResult.swift
//  Vimotion
//
//  Created by Elazar Yifrach on 20/07/2019.
//  Copyright © 2019 Elaz. All rights reserved.
//

import Foundation


struct DetectionRect: Decodable {
    var width: UInt16
    var height: UInt16
    var left: UInt16
    var top: UInt16
}

struct Emotion: Decodable {
    var neutral: Double
    var anger: Double
    var contempt: Double
    var disgust: Double
    var fear: Double
    var happiness: Double
    var sadness: Double
    var surprise: Double
    func mostPowerfulEmotion() -> String {
        return [
            ("Neutral", neutral),
            ("Anger", anger),
            ("Contempt", contempt),
            ("Disgust", disgust),
            ("Fear", fear),
            ("Happines", happiness),
            ("Sadness", sadness),
            ("Surprise", surprise)
            ].max { a, b in a.1 < b.1 }!.0
    }
}

struct FaceAttributes: Decodable {
    var emotion: Emotion
}

struct EmotionAPIDetectResult: Decodable {
    
    var faceRectangle: DetectionRect
    var faceAttributes: FaceAttributes
    
}
