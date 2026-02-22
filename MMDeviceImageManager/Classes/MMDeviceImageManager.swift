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
public protocol MMDeviceImageManagerDelegate: AnyObject {
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
        return photoGalleryAccess(from: PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }
    
    public func hasCameraAccess() -> Bool {
        cameraAccess(from: AVCaptureDevice.authorizationStatus(for: .video))
    }
    
    public func isDeviceHasCamera() -> Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    // MARK: - Private Helpers
    private func initializeImagePicker() {
        imagePickerController.delegate = self
        let mediaType: UIImagePickerController.SourceType = (imagePickerMode == .photoGallery) ? .photoLibrary : .camera
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
        default:
            break
        }
    }
    
    private func handleCameraOption() {
        Task { [weak self] in
            guard let self = self else { return }
            if !self.isDeviceHasCamera() {
                self.delegate?.mmDeviceImageManagerError(self, error: .noCameraAvailable)
                return
            }
            let hasAccess = self.hasCameraAccess()
            let granted: Bool
            if hasAccess {
                granted = true
            } else {
                granted = await self.requestCameraAccessAsync()
            }
            if granted {
                self.imagePickerMode = .camera
                self.presentImagePicker()
            } else {
                self.delegate?.mmDeviceImageManagerError(self, error: .noCameraPermission)
            }
        }
    }
    
    private func handlePhotoGalleryOption() {
        self.imagePickerMode = .photoGallery
        Task { [weak self] in
            guard let self else { return }
            let hasAccess = self.hasPhotoGalleryPermission()
            let granted: Bool
            if hasAccess {
                granted = true
            } else {
                granted = await self.requestPhotoLibraryPermission()
            }
            if granted {
                self.presentImagePicker()
            } else {
                self.delegate?.mmDeviceImageManagerError(self, error: .noPhotoGalleryPermission)
            }
        }
    }
    
    private func cameraAccess(from authorizationStatus: AVAuthorizationStatus) -> Bool {
        authorizationStatus == .authorized
    }
    
    private func photoGalleryAccess(from status: PHAuthorizationStatus) -> Bool {
        status == .authorized || status == .limited
    }
    
    private func requestPhotoLibraryPermission() async -> Bool {
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
        return photoGalleryAccess(from: status)
    }
    
    private func requestCameraAccessAsync() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { status in
                continuation.resume(returning: status)
            }
        }
    }
}

// MARK: - Image Picker Delegates
extension MMDeviceImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        picker.dismiss(animated: true) {
            let stringKeyedInfo: [String: Any] = info.reduce(into: [:]) { partialResult, pair in
                partialResult[pair.key as String] = pair.value
            }
            self.delegate?.mmDeviceImageManager(self, selectedImage: stringKeyedInfo)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.delegate?.mmDeviceImageManagerError(self, error: .cancel)
        }
    }
}

