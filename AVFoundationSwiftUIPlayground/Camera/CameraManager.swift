
import Foundation
import AVFoundation

class CameraManager: ObservableObject {
  enum Status {
    case unconfigured, configured, unauthorized, failed
  }

  @Published var error: CameraError?

  let session = AVCaptureSession()

  private let sessionQueue = DispatchQueue(label: "com.pickle.SessionQ")

  private let videoOutput = AVCaptureVideoDataOutput()
  private let photoOutput = AVCapturePhotoOutput()
  private var metaDataOutput = AVCaptureMetadataOutput()

  private var status = Status.unconfigured
  
  static let shared = CameraManager()
  
  private init() {
    configure()
  }
  
  private func set(error: CameraError?){
    DispatchQueue.main.async {
      self.error = error
    }

  }
  
  private func checkPermissions() {
    
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:

      sessionQueue.suspend()
      AVCaptureDevice.requestAccess(for: .video) { authorized in

        if !authorized {
          self.status = .unauthorized
          self.set(error: .deniedAuthorization)
        }
        self.sessionQueue.resume()
      }

    case .restricted:
      status = .unauthorized
      set(error: .restrictedAuthorization)
    case .denied:
      status = .unauthorized
      set(error: .deniedAuthorization)

    case .authorized:
      break

    @unknown default:
      status = .unauthorized
      set(error: .unknownAuthorization)
    }
  }
  
  /**
   Will configure the pipeline for Capture Session
   More information here https://developer.apple.com/documentation/avfoundation/capture_setup
   */
  private func configureCaptureSession() {
    
    //Configure session
    guard status == .unconfigured else {
      return
    }
    session.beginConfiguration()
    
    session.sessionPreset = AVCaptureSession.Preset.photo
    
    //Will be executed at the end of this function code
    defer {
      session.commitConfiguration()
    }
    
    //Getting the raw - Low level camera input
    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    guard let camera = device else {
      set(error: .cameraUnavailable)
      status = .failed
      return
    }
    
    do {
      //Creating the CaptureDeviceInput to connect to CaptureSession
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      if session.canAddInput(cameraInput) {
        session.addInput(cameraInput)
      } else {
        set(error: .cannotAddInput)
        status = .failed
        return
      }
    } catch {
      set(error: .createCaptureInput(error))
      status = .failed
      return
    }
    
    //Output for Photo
    if session.canAddOutput(photoOutput) {
//        photoOutput.setPreparedPhotoSettingsArray([
//          AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
//        ], completionHandler: nil)
        session.addOutput(photoOutput)
    } else {
      set(error: .cannotAddOutput)
      status = .failed
    }
    
    //Output for Meta Data like QRCode
    if session.canAddOutput(metaDataOutput) {
      session.addOutput(metaDataOutput)
      metaDataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    } else {
      set(error: .cannotAddOutput)
      status = .failed
    }
    
    //Output for video preview
    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
      videoOutput.videoSettings =
      [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
      let videoConnection = videoOutput.connection(with: .video)
      videoConnection?.videoOrientation = .portrait
    } else {
      set(error: .cannotAddOutput)
      status = .failed
      return
    }
    
    status = .configured
  }
  
  func takePicture(_ delegate: AVCapturePhotoCaptureDelegate, queue: DispatchQueue, flashMode: AVCaptureDevice.FlashMode = .auto) {
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    settings.flashMode = flashMode
    queue.async {
      self.photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
  }
  
  func setMetaDataOutputDelegate(_ delegate: AVCaptureMetadataOutputObjectsDelegate, queue: DispatchQueue) {
    sessionQueue.async {
      self.metaDataOutput.setMetadataObjectsDelegate(delegate, queue: queue)
    }
  }
  
  /*
   Passing video data to an Output set by a delegate
   */
  func set(
    _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
    queue: DispatchQueue
  ) {
    sessionQueue.async {
      self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
    }
  }

  
  public func configure() {
    checkPermissions()
    sessionQueue.async {
      self.configureCaptureSession()
      self.session.startRunning()
    }
  }
}
