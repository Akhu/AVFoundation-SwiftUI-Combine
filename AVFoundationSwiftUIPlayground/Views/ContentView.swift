/// Copyright (c) 2021 Razeware LLC
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

import SwiftUI
import AVFoundation

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
  
  var body: some View {
    VStack {
      ZStack {
        FrameView(image: model.frame)
          .edgesIgnoringSafeArea(.all)
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
          }
        }
        Button("Switch Camera") {
          //model.switchCamera
        }
        //Change Camera
        Button("Take picture") {
          model.takePicture(flashMode: flashMode)
        }
      }
    }
    .sheet(isPresented: $showPicture, content: {
      if let cgImage = model.capturedPhoto {
          Image(cgImage, scale: 1.0, orientation: .right, label: Text("Hello world"))
          .resizable()
      }
    })
    .onReceive(model.$capturedPhoto) { image in
      if image != nil {
        showPicture.toggle()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
