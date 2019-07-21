//
//  VimotionPhotoViewModel.swift
//  Vimotion
//
//  Created by Elazar Yifrach on 20/07/2019.
//  Copyright © 2019 Elaz. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class VimotionPhotoViewModel {
    
    enum State {
        case idle
        case processing
        case detected(String)
        case error(String)
    }
    
    var image = BehaviorRelay<UIImage?>(value: nil)
    var state = BehaviorRelay<State>(value: .idle)
    
}
