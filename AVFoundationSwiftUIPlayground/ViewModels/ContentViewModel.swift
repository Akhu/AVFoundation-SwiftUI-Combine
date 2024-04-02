import AVFoundation
import CoreImage
import UIKit
import Combine

class ContentViewModel: ObservableObject {
    @Published var frame: CGImage?
    @Published var urlDetectedInImage: URL?
    @Published var capturedPhoto: CGImage?
    @Published var currentCamera: AVCaptureDevice.Position = .back
    @Published var capturePhotoAsUIImage: UIImage?
    
    var cancellables = Set<AnyCancellable>()
    
    private let frameManager: FrameManager
    
    @Published var error:Error?
    
    private let cameraManager = CameraManager.shared
    
    init() {
        self.frameManager = FrameManager()
        setupSubscriptions()
    }
    
    func takePicture(flashMode: AVCaptureDevice.FlashMode) {
        frameManager.takePicture(flashMode: flashMode)
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
    }
    
    func setupSubscriptions() {
        
        cameraManager.$cameraPosition
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$currentCamera)
        
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                return CGImage.create(from: buffer)
            }
            .assign(to: &$frame)
        
        frameManager.$capturedPhoto
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$capturedPhoto)
            
        
        $capturedPhoto
            .compactMap { imageCg in
                if let imageCgUnwrap = imageCg {
                    return UIImage(cgImage: imageCgUnwrap, scale: 1.0, orientation: self.currentCamera.toUIImageOrientation())
                }
                return nil 
            }
            .assign(to: \.capturePhotoAsUIImage, on: self)
            .store(in: &cancellables)
        
        frameManager.$qrCodeDetected
            .receive(on: RunLoop.main)
            .compactMap { string in
                guard let urlString = string else { return nil }
                return URL(string: urlString)
            }
            .assign(to: &$urlDetectedInImage)
        
        cameraManager.$error
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$error)
    }
}

extension AVCaptureDevice.Position {
    //Considering that we can use the application in Landscape mode
    func toUIImageOrientation() -> UIImage.Orientation {
        switch self {
        case .unspecified:
            return .leftMirrored
        case .back:
            return .right
        case .front:
            return .right
        @unknown default:
            return .left
        }
    }
}
