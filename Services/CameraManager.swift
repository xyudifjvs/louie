//
//  UntitledCameraManager.swift
//  Louie
//
//  Created by Carson on 3/28/25.
//

import SwiftUI
import AVFoundation
import Photos

enum CameraError: Error {
    case permissionDenied
    case captureError
    case deviceNotAvailable
    case photoLibraryPermissionDenied
    case saveError
    case unknown
    
    var description: String {
        switch self {
        case .permissionDenied:
            return "Camera permission was denied. Please enable it in Settings."
        case .captureError:
            return "Failed to capture photo. Please try again."
        case .deviceNotAvailable:
            return "Camera is not available on this device."
        case .photoLibraryPermissionDenied:
            return "Photo library permission was denied. Please enable it in Settings."
        case .saveError:
            return "Failed to save photo. Please try again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

class CameraManager: NSObject, ObservableObject {
    static let shared = CameraManager()
    
    @Published var error: CameraError?
    @Published var showPermissionAlert = false
    @Published var image: UIImage?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var completionHandler: ((Result<UIImage, CameraError>) -> Void)?
    
    // Check if camera permission has been granted
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            self.error = .permissionDenied
            self.showPermissionAlert = true
            completion(false)
        @unknown default:
            self.error = .unknown
            completion(false)
        }
    }
    
    // Setup camera capture session
    func setupCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        // Set up the capture device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            self.error = .deviceNotAvailable
            return nil
        }
        
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }
        
        // Setup the photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
        }
        
        captureSession.commitConfiguration()
        self.captureSession = captureSession
        
        return captureSession
    }
    
    // Take a photo
    func capturePhoto(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
        self.completionHandler = completion
        
        guard let photoOutput = self.photoOutput else {
            completion(.failure(.deviceNotAvailable))
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    // Start the capture session (call this when the camera view appears)
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    // Stop the capture session (call this when the camera view disappears)
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // Check photo library permission and save image
    func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping (Result<Void, CameraError>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                self.tempCompletion = completion
            case .denied, .restricted:
                DispatchQueue.main.async {
                    completion(.failure(.photoLibraryPermissionDenied))
                }
            case .notDetermined:
                // This shouldn't happen as we already requested permission
                DispatchQueue.main.async {
                    completion(.failure(.unknown))
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(.failure(.unknown))
                }
            }
        }
    }
    
    private var tempCompletion: ((Result<Void, CameraError>) -> Void)?
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            tempCompletion?(.failure(.saveError))
        } else {
            tempCompletion?(.success(()))
        }
        tempCompletion = nil
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completionHandler?(.failure(.captureError))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completionHandler?(.failure(.captureError))
            return
        }
        
        self.image = image
        completionHandler?(.success(image))
    }
} 
