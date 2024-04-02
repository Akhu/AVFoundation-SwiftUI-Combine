import SwiftUI
import AVFoundation
import Photos

extension AVCaptureDevice.FlashMode {
  func toString() -> String {
    switch self {
    case .auto:
      return "Auto"
    case .on:
      return "On"
    case .off:
      return "Off"
    default:
      return "Auto"
    }
  }
}

struct ContentView: View {
  
  @StateObject private var model = ContentViewModel()
  
  @State private var showPicture = false
  
  @State private var flashMode: AVCaptureDevice.FlashMode = .auto
  
    func saveImageToLibrary(capturedPhoto: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { authStatus in

            guard authStatus == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                // Add the captured photo's file data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.creationRequestForAsset(from: capturedPhoto)
                
            }) { result, error in
                print("Result photo saving \(result)")
                guard let error else { return }
                print(error)
            }
        }
        model.capturePhotoAsUIImage = nil
    }
    
    var body: some View {
        VStack {
            ZStack {
                
                if showPicture {
                    VStack {
                        if let uiImagePhoto = model.capturePhotoAsUIImage {
                            Image(uiImage: uiImagePhoto)
                                .resizable()
                                .centerCropped()
                        }
                        Button("Close") {
                            showPicture = false
                        }
                        Button("Save Image") {
                            if let uiImagePhoto = model.capturePhotoAsUIImage {
                                saveImageToLibrary(capturedPhoto: uiImagePhoto)
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    .transition(.push(from: .bottom))
                } else {
                    FrameView(image: model.frame)
                        .edgesIgnoringSafeArea(.all)
                }
                Text("QRCode ? \(model.urlDetectedInImage?.absoluteString ?? "Nope")")
                ErrorView(error: model.error)
            }
            HStack {
                //Flash
                Button("Flash Mode \(flashMode.toString())") {
                    switch flashMode {
                    case .auto:
                        flashMode = .on
                        break
                    case .on:
                        flashMode = .off
                        break
                    case .off:
                        flashMode = .auto
                        break
                    @unknown default:
                        flashMode = .auto
                        break
                    }
                }
                Button("Current Camera \(model.currentCamera.rawValue)") {
                    model.switchCamera()
                }
                //Change Camera
                Button("Take picture") {
                    model.takePicture(flashMode: flashMode)
                }
            }
        }
        .onReceive(model.$capturedPhoto) { output in
            if let image = output {
                withAnimation {
                    
                    showPicture = true
                }
            } else {
                withAnimation {
                    showPicture = false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
