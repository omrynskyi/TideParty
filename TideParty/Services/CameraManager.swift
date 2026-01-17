import AVFoundation
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    @Published var error: String?
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.tideparty.cameraSessionQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // Pass visual stream to the UI
    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [weak self] in
            self?.configureSession()
            self?.session.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
            }
        default:
            permissionGranted = false
            error = "Camera access is denied. Please enable it in Settings."
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.sessionPreset = .high
        
        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async { self.error = "No back camera found" }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            DispatchQueue.main.async { self.error = "Error setting up camera input: \(error.localizedDescription)" }
            return
        }
        
        // Output (for Vision processing later)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            // We will set the delegate later when we build the Vision service
            // videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
    }
}
