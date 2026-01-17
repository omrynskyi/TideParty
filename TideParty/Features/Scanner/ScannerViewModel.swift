//
//  ScannerViewModel.swift
//  TideParty
//
//  Handles camera capture and CoreML classification
//

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreML
import UIKit

@MainActor
class ScannerViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var classificationLabel: String = "Scanning..."
    @Published var confidence: Float = 0.0
    @Published var isHighConfidence: Bool = false
    @Published var isSessionRunning: Bool = false
    
    // MARK: - Camera
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.tideparty.scanner")
    
    // MARK: - Vision
    private var classificationRequest: VNCoreMLRequest?
    private var isProcessing = false
    
    // MARK: - Haptics
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private var lastIdentification: String?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupModel()
        setupCamera()
        haptic.prepare()
    }
    
    // MARK: - Model Setup
    private var classLabels: [Int: String] = [:]
    
    private func setupModel() {
        // Load class labels
        loadClassLabels()
        
        // Load TidePoolIdentifier model
        guard let modelURL = Bundle.main.url(forResource: "TidePoolIdentifier", withExtension: "mlmodelc")
                ?? Bundle.main.url(forResource: "TidePoolIdentifier", withExtension: "mlpackage") else {
            print("❌ Could not find TidePoolIdentifier model")
            classificationLabel = "Model not found"
            return
        }
        
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            let visionModel = try VNCoreMLModel(for: model)
            
            classificationRequest = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                self?.handleClassification(request: request, error: error)
            }
            classificationRequest?.imageCropAndScaleOption = .centerCrop
            
            print("✅ Model loaded successfully with \(classLabels.count) labels")
        } catch {
            print("❌ Model load error: \(error)")
            classificationLabel = "Model error"
        }
    }
    
    private func loadClassLabels() {
        guard let url = Bundle.main.url(forResource: "marine_labels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            print("⚠️ Could not load class labels, using class indices")
            return
        }
        
        // Convert string keys to Int
        for (key, value) in dict {
            if let idx = Int(key) {
                classLabels[idx] = value
            }
        }
        print("✅ Loaded \(classLabels.count) class labels")
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Camera not available")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Session Control
    func startSession() {
        guard !captureSession.isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        processingQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Classification Handler
    private func handleClassification(request: VNRequest, error: Error?) {
        isProcessing = false
        
        guard let results = request.results as? [VNClassificationObservation],
              let top = results.first else { return }
        
        let conf = top.confidence
        let name = formatName(top.identifier)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.confidence = conf
            
            if conf > 0.9 {
                self.classificationLabel = name
                self.isHighConfidence = true
                
                // Haptic on new discovery
                if self.lastIdentification != name {
                    self.haptic.impactOccurred()
                    self.lastIdentification = name
                }
            } else if conf > 0.8 {
                self.classificationLabel = name
                self.isHighConfidence = false
            } else {
                self.classificationLabel = "Scanning..."
                self.isHighConfidence = false
                self.lastIdentification = nil
            }
        }
    }
    
    private func formatName(_ identifier: String) -> String {
        // Try to look up from labels if identifier is a class index
        if let classIdx = Int(identifier), let label = classLabels[classIdx] {
            // Format the label nicely: "edible_mussel, Mytilus_edulis" -> "Edible Mussel"
            return label
                .split(separator: ",")
                .first
                .map(String.init)?
                .replacingOccurrences(of: "_", with: " ")
                .capitalized ?? identifier
        }
        
        // Fallback: clean up model output for display
        return identifier
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: ",")
            .first
            .map(String.init)?
            .capitalized ?? identifier
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ScannerViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Perform classification on the processing queue
        Task { @MainActor in
            guard !self.isProcessing, let request = self.classificationRequest else { return }
            self.isProcessing = true
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            try? handler.perform([request])
        }
    }
}

