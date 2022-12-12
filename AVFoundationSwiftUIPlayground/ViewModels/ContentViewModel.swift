/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import CoreImage

class ContentViewModel: ObservableObject {
  @Published var frame: CGImage?
  @Published var urlDetectedInImage: URL?
  @Published var capturedPhoto: CGImage?
  
  private let frameManager = FrameManager.shared
  
  
  @Published var error:Error?
  
  private let cameraManager = CameraManager.shared
  
  init() {
    setupSubscriptions()
  }
  
  func takePicture(flashMode: AVCaptureDevice.FlashMode) {
    frameManager.takePicture(flashMode: flashMode)
  }
  
  func setupSubscriptions() {
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
