//
//  MMDeviceImageManager.swift
//  MMDeviceImageManagerSample
//
//  Created by Muthuraj Muthulingam on 15/04/18.
//  Copyright © 2018 Muthuraj Muthulingam. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

// MARK: - ImagePickerManager Rules
public protocol MMDeviceImageManagerDelegate: class {
    func mmDeviceImageManager(_ imagePicker: MMDeviceImageManager, selectedImage imageInfo:[String:Any])
    func mmDeviceImageManagerError(_ imagePicker: MMDeviceImageManager, error: ImagePickerErrorType)
}

public enum ActionSheetType {
    case standard(title: String, message: String, photoAlbumOptionTitle: String, cameraOptionTitle: String)
    case custom
}

private enum ImagePickerMode {
    case photoGallery
    case camera
}

public enum ImagePickerErrorType {
    case noPhotoGalleryPermission
    case noCameraPermission
    case noCameraAvailable
    case cancel
}

public class MMDeviceImageManager: NSObject {
    
    lazy private var imagePickerController: UIImagePickerController = UIImagePickerController()
    private var imagePickerMode: ImagePickerMode = .photoGallery {
        didSet {
            initializeImagePicker()
        }
    }
    private weak var viewController: UIViewController?
    public weak var delegate: MMDeviceImageManagerDelegate?
    private var actionSheetType: ActionSheetType
    
    // MARK: - Designated Inizialiser
    public init(with viewController: UIViewController, delegate: MMDeviceImageManagerDelegate, ActionSheetType type:ActionSheetType) {
        self.viewController = viewController
        self.delegate = delegate
        self.actionSheetType = type
    }
    
    // MARK: - Public Methods
    public func present() {
        addActionSheet()
    }
    
    public func hasPhotoGalleryPermission() -> Bool {
        return photoGalleryAccess(from: PHPhotoLibrary.authorizationStatus())
    }
    
    public func hasCameraAccess() -> Bool {
        return cameraAccess(from: AVCaptureDevice.authorizationStatus(for: .video))
    }
    
    public func isDeviceHasCamera() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    // MARK: - Private Helpers
    private func initializeImagePicker() {
        imagePickerController.delegate = self
        let mediaType: UIImagePickerControllerSourceType = (imagePickerMode == .photoGallery) ? .photoLibrary : .camera
        imagePickerController.sourceType = mediaType
    }
    
    private func presentImagePicker() {
        viewController?.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func addActionSheet() {
        switch actionSheetType {
        case .standard(let title,let message, let option1, let option2):
            let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            let photoGalleryAction = UIAlertAction(title: option1, style: .default) { (action) in
                self.handlePhotoGalleryOption()
            }
            let cameraAction = UIAlertAction(title: option2, style: .default) { (action) in
                self.handleCameraOption()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                self.delegate?.mmDeviceImageManagerError(self, error: .cancel)
            }
            actionSheet.addAction(photoGalleryAction)
            actionSheet.addAction(cameraAction)
            actionSheet.addAction(cancelAction)
            viewController?.present(actionSheet, animated: true, completion:nil)
            break
        default:
            break
        }
    }
    
    private func handleCameraOption() {
        if self.isDeviceHasCamera() {
            if self.hasCameraAccess() { // already access given
                // access requested and granted
                self.imagePickerMode = .camera
                self.presentImagePicker()
            } else {
                self.requestCameraAccess(completion: { status in
                    if status {
                        // access requested and granted
                        self.imagePickerMode = .camera
                        self.presentImagePicker()
                    } else { // no access
                        self.delegate?.mmDeviceImageManagerError(self, error: .noCameraPermission)
                    }
                })
            }
        } else {
            self.delegate?.mmDeviceImageManagerError(self, error: .noCameraAvailable)
        }
    }
    
    private func handlePhotoGalleryOption() {
        self.imagePickerMode = .photoGallery
        // handle photoGallery option
        if self.hasPhotoGalleryPermission() {
            // access available
            self.presentImagePicker()
        } else {
            // request access
            self.requestPhotoLibrarayPermission(completion: { (status) in
                if status {
                    // access given, Go ahead and present the Gallery
                    self.presentImagePicker()
                } else {
                    self.delegate?.mmDeviceImageManagerError(self, error: .noPhotoGalleryPermission)
                }
            })
        }
    }
    
    private func cameraAccess(from authorizationStatus: AVAuthorizationStatus) -> Bool {
        var status: Bool = false
        switch authorizationStatus {
        case .authorized:
            status = true
        default:
            break
        }
        return status
    }
    
    private func photoGalleryAccess(from status: PHAuthorizationStatus) -> Bool {
        var status: Bool = false
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            status = true
        default:
            break
        }
        return status
    }
    
    private func requestPhotoLibrarayPermission(completion : @escaping ((_ status:Bool) -> ())) {
        PHPhotoLibrary.requestAuthorization {[unowned self] (status) in
            let isAccessGiven = self.photoGalleryAccess(from: status)
            completion(isAccessGiven)
        }
    }
    
    private func requestCameraAccess(completion: @escaping ((_ status: Bool) -> Void)) {
        AVCaptureDevice.requestAccess(for: .video) { status in
            completion(status)
        }
    }
}

// MARK: - Image Picker Delegates
extension MMDeviceImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        self.delegate?.mmDeviceImageManager(self, selectedImage: info)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.delegate?.mmDeviceImageManagerError(self, error: .cancel)
    }
}
