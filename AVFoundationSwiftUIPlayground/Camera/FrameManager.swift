import Foundation
import AVFoundation
import UIKit
import Combine

class FrameManager: NSObject, ObservableObject {
    static let shared = FrameManager()
    
    @Published var current: CVPixelBuffer?
    @Published var qrCodeDetected: String?
    @Published var capturedPhoto: CGImage?
    
    
    var shouldCaptureQrCode = true
    
    let videoOutputQueue = DispatchQueue(
        label: "com.pickle.VideoOutputQ",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    let photoCaptureOutputQueue = DispatchQueue(
        label: "com.pickle.PhotoCaptureOutputQ",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    let qrCodeOutputQueue = DispatchQueue(label: "com.pickle.QrOutputQ",
                                          qos: .userInitiated,
                                          attributes: [],
                                          autoreleaseFrequency: .workItem)
    
     override init() {
        super.init()
        CameraManager.shared.set(self, queue: videoOutputQueue)
        CameraManager.shared.setMetaDataOutputDelegate(self, queue: qrCodeOutputQueue)
        
     
    }
}

extension FrameManager: AVCapturePhotoCaptureDelegate {
    
    func takePicture(flashMode: AVCaptureDevice.FlashMode) {
        CameraManager.shared.takePicture(self, queue: photoCaptureOutputQueue, flashMode: flashMode)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            
            guard let newImage = UIImage(data: imageData) else { return }
            
            guard let cgImage = newImage.cgImage else { return }
            DispatchQueue.main.async {
                self.capturedPhoto = cgImage
            }
            
        }
    }
}

extension FrameManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if shouldCaptureQrCode {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                qrCodeDetected = stringValue
            }
        }
    }
}

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = sampleBuffer.imageBuffer {
            DispatchQueue.main.async {
                self.current = buffer
            }
        }
    }
}
