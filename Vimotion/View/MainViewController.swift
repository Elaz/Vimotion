//
//  MainViewController.swift
//  Vimotion
//
//  Created by Elazar Yifrach on 20/07/2019.
//  Copyright © 2019 Elaz. All rights reserved.
//

import UIKit
import PromiseKit
import RxCocoa
import RxSwift
import Toast_Swift
import AVFoundation

protocol MainViewControllerDelegate: FlowController {
    func controllerDidTapSelectNewPhoto(controller: MainViewController)
}

class MainViewController: UIViewController {

    weak var delegate: MainViewControllerDelegate?
    fileprivate let bag = DisposeBag()
    
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    init(viewModel: VimotionPhotoViewModel) {
        super.init(nibName: "MainViewController", bundle: nil)
        loadViewIfNeeded()
        bindViewModel(viewModel)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("MainViewController must be init with viewModel")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("MainViewController must be init with viewModel")
    }
    
    fileprivate func bindViewModel(_ viewModel: VimotionPhotoViewModel) {
       
        viewModel.image
            .bind(to: imageView.rx.image)
            .disposed(by: bag)
        viewModel.state.subscribe(onNext: { [weak self] state in
            guard let this = self else { return }
            this.view.hideAllToasts(includeActivity: true, clearQueue: true)
            switch state {
            case .processing:
                if let image = viewModel.image.value {
                    this.view.makeToastActivity(this.pointForDisplayingActivity(with: image))
                }
            case .idle:
                this.view.hideAllToasts(includeActivity: true, clearQueue: true)
            case .detected(let emotion):
                if let image = viewModel.image.value {
                    this.view.makeToast(emotion,
                                        duration: 10.0,
                                        point: this.pointForDisplayingAlert(with: image),
                                        title: nil,
                                        image: nil,
                                        style: ToastManager.shared.style,
                                        completion: nil)
                }
            case .error(let message):
                var style = ToastStyle()
                style.backgroundColor = UIColor.red
                if let image = viewModel.image.value {
                    this.view.makeToast(message,
                                        duration: 5.0,
                                        point: this.pointForDisplayingAlert(with: image),
                                        title: "Error",
                                        image: nil,
                                        style: style,
                                        completion: nil)
                }
                
            }
        }).disposed(by: bag)
        viewModel.state.map { if case .processing = $0 {
                return false
            }
            return true
        }
        .bind(to: choosePhotoButton.rx.isEnabled)
        .disposed(by: bag)
    }
    
    fileprivate func pointForDisplayingAlert(with image: UIImage) -> CGPoint {
        let rect = AVMakeRect(aspectRatio: image.size, insideRect: imageView.frame)
        return CGPoint(x: rect.midX, y: rect.midY + (rect.maxY - rect.midY) / 2.0)
    }
    
    fileprivate func pointForDisplayingActivity(with image: UIImage) -> CGPoint {
        let rect = AVMakeRect(aspectRatio: image.size, insideRect: imageView.frame)
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        choosePhotoButton.rx.tap.bind { [weak self] in
            guard let this = self else { return }
            this.delegate?.controllerDidTapSelectNewPhoto(controller: this)
        }.disposed(by: bag)
    }

}
