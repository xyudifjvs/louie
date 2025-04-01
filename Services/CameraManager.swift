//
//  CameraManager.swift
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
    @Published var image: UIImage?
    
    @Published var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var completion: ((Result<UIImage, CameraError>) -> Void)?
    
    override init() {
        super.init()
    }
    
    // Check camera permission
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
            completion(false)
        @unknown default:
            self.error = .unknown
            completion(false)
        }
    }
    
    // Set up and start the camera session
    func setupAndStartSession() {
        // Create the session
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // Configure the session on a background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get the camera device
            guard let camera = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async {
                    self.error = .deviceNotAvailable
                }
                return
            }
            
            do {
                // Add camera input
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                // Add photo output
                let photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                    self.photoOutput = photoOutput
                }
                
                // Update the published property on the main thread
                DispatchQueue.main.async {
                    self.captureSession = session
                }
                
                // Start the session on the background thread
                session.startRunning()
            } catch {
                DispatchQueue.main.async {
                    self.error = .deviceNotAvailable
                }
            }
        }
    }
    
    // Capture a photo
    func capturePhoto(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
        self.completion = completion
        
        // Check if we have a valid photo output
        guard let photoOutput = photoOutput, captureSession?.isRunning == true else {
            completion(.failure(.deviceNotAvailable))
            return
        }
        
        // Create photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        // Take the photo
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Stop the session
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // Reset the manager
    func reset() {
        stopSession()
        captureSession = nil
        photoOutput = nil
        image = nil
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion?(.failure(.captureError))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion?(.failure(.captureError))
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.image = image
            self?.completion?(.success(image))
        }
    }
}
