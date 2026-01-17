//
//  CameraPreview.swift
//  TideParty
//
//  UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Session updates handled externally
    }
}

class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            previewLayer.session = session
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.videoGravity = .resizeAspectFill
    }
}
