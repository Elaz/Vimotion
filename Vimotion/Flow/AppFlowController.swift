//
//  AppFlowController.swift
//  Vimotion
//
//  Created by Elazar Yifrach on 20/07/2019.
//  Copyright © 2019 Elaz. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

class AppFlowController: FlowController {
    
    fileprivate let photo = VimotionPhotoViewModel()
    fileprivate var mainVC: MainViewController!
    fileprivate var detector: EmotionDetector!
    
    override func start() {
        mainVC = MainViewController(viewModel: photo)
        mainVC.delegate = self
        detector = EmotionDetector(with: mainVC.imageView.bounds.size)
        presentingViewController.present(mainVC, animated: false)
    }
    
    fileprivate func chooseImageSource(controller: MainViewController) -> Promise<UIImagePickerController.SourceType> {
        
        return Promise { seal in
            let hasCamera = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
            guard hasCamera else {
                seal.fulfill(UIImagePickerController.SourceType.photoLibrary)
                return
            }
            let alert = UIAlertController(title: "Select image source",
                                          message: nil,
                                          preferredStyle: .actionSheet)
            if hasCamera {
                alert.addAction(UIAlertAction(title: "Camera",
                                              style: .default) { _ in
                    seal.fulfill(UIImagePickerController.SourceType.camera)
                })
            }
            alert.addAction(UIAlertAction(title: "Gallery",
                                          style: .default) { _ in
                seal.fulfill(UIImagePickerController.SourceType.photoLibrary)
            })
            alert.addAction(UIAlertAction.init(title: "Cancel",
                                               style: .cancel) { _ in
                seal.reject(PMKError.cancelled)
            })
            controller.present(alert, animated: true)
        }
    }
    
    fileprivate func processImage(_ image: UIImage) {
        resetPhoto()
        photo.image.accept(image)
        photo.state.accept(.processing)
        detector.detectEmotion(in: image).done { image, emotion in
            self.photo.image.accept(image)
            self.photo.state.accept(.detected(emotion))
        }.catch { error in
            self.photo.state.accept(.error(error.localizedDescription))
        }
    }
    
    fileprivate func resetPhoto() {
        photo.image.accept(nil)
        photo.state.accept(.idle)
    }
    
}

extension AppFlowController: MainViewControllerDelegate {
    func controllerDidTapSelectNewPhoto(controller: MainViewController) {
        
        firstly {
            chooseImageSource(controller: controller)
        }.then(on: .main) { source -> Promise<[UIImagePickerController.InfoKey: Any]> in
            let picker = UIImagePickerController()
            picker.sourceType = source
            picker.allowsEditing = false
            return controller.promise(picker, animate: .appear)
        }.then(on: .main, flags: nil) { info -> Promise<UIImage> in
            return Promise { seal in
                guard let image = info[.originalImage] as? UIImage else {
                    seal.reject(PMKError.badInput)
                    return
                }
                seal.fulfill(image)
            }
        }.done(on: .main) { image in
            self.processImage(image)
        }.catch { error in
            if case PMKError.badInput = error {
                self.resetPhoto()
                // TODO: present alert
            }
        }
    }
}
