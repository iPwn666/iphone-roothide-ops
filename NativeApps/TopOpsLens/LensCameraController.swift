import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Photos
import SwiftUI
import UIKit

final class LensCameraController: NSObject, ObservableObject {
	private enum DefaultsKey {
		static let look = "TopOpsLens.look"
		static let guide = "TopOpsLens.guide"
		static let profile = "TopOpsLens.profile"
		static let autoSaveToPhotos = "TopOpsLens.autoSaveToPhotos"
	}

	private let sessionQueue = DispatchQueue(label: "com.topwnz.TopOpsLens.session")
	private let ciContext = CIContext()
	private let imageRendererFormat = UIGraphicsImageRendererFormat.default()
	private let captureSession = AVCaptureSession()
	private let photoOutput = AVCapturePhotoOutput()
	private let movieOutput = AVCaptureMovieFileOutput()

	private var videoInput: AVCaptureDeviceInput?
	private var audioInput: AVCaptureDeviceInput?
	private var currentPosition: AVCaptureDevice.Position = .back
	private var didConfigureSession = false
	private var didStart = false
	private var pinchBaseZoom: CGFloat = 1
	private var exposurePanBase: CGFloat = 0
	private var recordingTimer: Timer?
	private var recordingStartDate: Date?

	@Published var selectedProfile: CaptureProfile
	@Published var selectedLook: LensLook
	@Published var selectedGuide: FrameGuide
	@Published var sessionMessage = "Preparing camera..."
	@Published var latestThumbnail: UIImage?
	@Published var focusMarker: FocusMarker?
	@Published var toast: LensToast?
	@Published var isRecording = false
	@Published var isReady = false
	@Published var recordingDuration = "00:00"
	@Published var zoomFactor: CGFloat = 1
	@Published var exposureNormalized: CGFloat = 0
	@Published var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
	@Published var microphonePermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
	@Published var photoPermission: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
	@Published var localCaptureCount = 0

	var session: AVCaptureSession {
		captureSession
	}

	var captureDestinationLabel: String {
		if autoSaveToPhotos && (photoPermission == .authorized || photoPermission == .limited) {
			return "Photos"
		}
		return "Captures"
	}

	var autoSaveToPhotos: Bool {
		didSet {
			UserDefaults.standard.set(autoSaveToPhotos, forKey: DefaultsKey.autoSaveToPhotos)
		}
	}

	override init() {
		let defaults = UserDefaults.standard
		selectedProfile = CaptureProfile(rawValue: defaults.string(forKey: DefaultsKey.profile) ?? "") ?? .social
		selectedLook = LensLook(rawValue: defaults.string(forKey: DefaultsKey.look) ?? "") ?? .clean
		selectedGuide = FrameGuide(rawValue: defaults.string(forKey: DefaultsKey.guide) ?? "") ?? .vertical
		autoSaveToPhotos = defaults.object(forKey: DefaultsKey.autoSaveToPhotos) as? Bool ?? true
		imageRendererFormat.scale = 1
		super.init()
		refreshLocalInventory()
	}

	deinit {
		recordingTimer?.invalidate()
	}

	static func ensureWorkspace() {
		let manager = FileManager.default
		for url in [capturesDirectory(), exportsDirectory()] {
			try? manager.createDirectory(at: url, withIntermediateDirectories: true)
		}
	}

	func prepareSession() {
		guard !didStart else { return }
		didStart = true
		updatePermissions()
		requestPermissionsAndConfigure()
	}

	func appDidBecomeActive() {
		updatePermissions()
		if cameraPermission == .authorized {
			startSessionIfNeeded()
		}
	}

	func setProfile(_ profile: CaptureProfile) {
		selectedProfile = profile
		UserDefaults.standard.set(profile.rawValue, forKey: DefaultsKey.profile)
		applyProfile(profile)
	}

	func setLook(_ look: LensLook) {
		selectedLook = look
		UserDefaults.standard.set(look.rawValue, forKey: DefaultsKey.look)
	}

	func setGuide(_ guide: FrameGuide) {
		selectedGuide = guide
		UserDefaults.standard.set(guide.rawValue, forKey: DefaultsKey.guide)
	}

	func toggleAutoSaveToPhotos() {
		autoSaveToPhotos.toggle()
		showToast("Saving to \(captureDestinationLabel)", tint: LensPalette.mint)
	}

	func capturePhoto() {
		guard isReady, !movieOutput.isRecording else { return }
		let settings = AVCapturePhotoSettings()
		settings.flashMode = .off
		settings.isHighResolutionPhotoEnabled = true
		settings.photoQualityPrioritization = .quality
		photoOutput.capturePhoto(with: settings, delegate: self)
		UIImpactFeedbackGenerator(style: .medium).impactOccurred()
	}

	func startRecording() {
		guard isReady, !movieOutput.isRecording else { return }
		let fileURL = Self.exportsDirectory().appendingPathComponent("clip-\(Self.timestamp()).mov")
		try? FileManager.default.removeItem(at: fileURL)
		if let connection = movieOutput.connection(with: .video), connection.isVideoOrientationSupported {
			connection.videoOrientation = .portrait
			if connection.isVideoStabilizationSupported {
				connection.preferredVideoStabilizationMode = .cinematic
			}
		}
		movieOutput.startRecording(to: fileURL, recordingDelegate: self)
	}

	func stopRecording() {
		guard movieOutput.isRecording else { return }
		movieOutput.stopRecording()
	}

	func flipCamera() {
		sessionQueue.async {
			let newPosition: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
			self.reconfigureVideoInput(position: newPosition)
		}
	}

	func beginPinch() {
		pinchBaseZoom = zoomFactor
	}

	func updateZoom(scale: CGFloat) {
		let target = pinchBaseZoom * scale
		setZoomFactor(target)
	}

	func beginExposureGesture() {
		exposurePanBase = exposureNormalized
	}

	func updateExposureGesture(verticalTranslation: CGFloat) {
		let next = exposurePanBase - (verticalTranslation / 280)
		setExposureNormalized(next)
	}

	func focus(at devicePoint: CGPoint, normalizedPoint: CGPoint) {
		guard let device = activeVideoDevice() else { return }
		sessionQueue.async {
			do {
				try device.lockForConfiguration()
				if device.isFocusPointOfInterestSupported {
					device.focusPointOfInterest = devicePoint
					device.focusMode = .autoFocus
				}
				if device.isExposurePointOfInterestSupported {
					device.exposurePointOfInterest = devicePoint
					device.exposureMode = .continuousAutoExposure
				}
				device.isSubjectAreaChangeMonitoringEnabled = true
				device.unlockForConfiguration()
				DispatchQueue.main.async {
					self.focusMarker = FocusMarker(normalizedPoint: normalizedPoint)
					self.showToast("Focus locked", tint: LensPalette.brass)
					UIImpactFeedbackGenerator(style: .light).impactOccurred()
				}
			} catch {
				DispatchQueue.main.async {
					self.showToast("Focus failed", tint: LensPalette.rose)
				}
			}
		}
	}

	func openSettings() {
		guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
		UIApplication.shared.open(url)
	}

	private func requestPermissionsAndConfigure() {
		requestCamera { granted in
			self.requestMicrophone {
				self.requestPhotoPermission()
				guard granted else {
					DispatchQueue.main.async {
						self.sessionMessage = "Allow camera access in Settings."
					}
					return
				}
				self.configureSessionIfNeeded()
			}
		}
	}

	private func requestCamera(completion: @escaping (Bool) -> Void) {
		let status = AVCaptureDevice.authorizationStatus(for: .video)
		switch status {
		case .authorized:
			completion(true)
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { granted in
				DispatchQueue.main.async { self.updatePermissions() }
				completion(granted)
			}
		default:
			completion(false)
		}
	}

	private func requestMicrophone(completion: @escaping () -> Void) {
		let status = AVCaptureDevice.authorizationStatus(for: .audio)
		switch status {
		case .authorized, .denied, .restricted:
			completion()
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .audio) { _ in
				DispatchQueue.main.async { self.updatePermissions() }
				completion()
			}
		@unknown default:
			completion()
		}
	}

	private func requestPhotoPermission() {
		if #available(iOS 14, *) {
			let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
			if status == .notDetermined {
				PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in
					DispatchQueue.main.async { self.updatePermissions() }
				}
			}
		}
	}

	private func updatePermissions() {
		cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
		microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
		photoPermission = PHPhotoLibrary.authorizationStatus(for: .addOnly)
	}

	private func configureSessionIfNeeded() {
		sessionQueue.async {
			guard !self.didConfigureSession else {
				self.startSessionIfNeeded()
				return
			}

			self.captureSession.beginConfiguration()
			self.captureSession.sessionPreset = self.selectedProfile.preset

			do {
				let videoDevice = try self.makeVideoInput(position: .back)
				if self.captureSession.canAddInput(videoDevice) {
					self.captureSession.addInput(videoDevice)
					self.videoInput = videoDevice
					self.currentPosition = .back
				}
				if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
				   let audioDevice = AVCaptureDevice.default(for: .audio) {
					let audioInput = try AVCaptureDeviceInput(device: audioDevice)
					if self.captureSession.canAddInput(audioInput) {
						self.captureSession.addInput(audioInput)
						self.audioInput = audioInput
					}
				}
				if self.captureSession.canAddOutput(self.photoOutput) {
					self.captureSession.addOutput(self.photoOutput)
					self.photoOutput.maxPhotoQualityPrioritization = .quality
				}
				if self.captureSession.canAddOutput(self.movieOutput) {
					self.captureSession.addOutput(self.movieOutput)
				}
				self.captureSession.commitConfiguration()
				self.didConfigureSession = true
				self.applyProfile(self.selectedProfile)
				self.startSessionIfNeeded()
			} catch {
				self.captureSession.commitConfiguration()
				DispatchQueue.main.async {
					self.sessionMessage = "Camera setup failed."
					self.showToast("Camera setup failed", tint: LensPalette.rose)
				}
			}
		}
	}

	private func startSessionIfNeeded() {
		sessionQueue.async {
			guard self.didConfigureSession else { return }
			guard !self.captureSession.isRunning else {
				DispatchQueue.main.async {
					self.isReady = true
					self.sessionMessage = "Ready"
				}
				return
			}
			self.captureSession.startRunning()
			DispatchQueue.main.async {
				self.isReady = true
				self.sessionMessage = "Ready"
				self.showToast("Camera live", tint: LensPalette.mint)
			}
		}
	}

	private func reconfigureVideoInput(position: AVCaptureDevice.Position) {
		do {
			let newInput = try makeVideoInput(position: position)
			captureSession.beginConfiguration()
			if let videoInput {
				captureSession.removeInput(videoInput)
			}
			if captureSession.canAddInput(newInput) {
				captureSession.addInput(newInput)
				videoInput = newInput
				currentPosition = position
			}
			captureSession.commitConfiguration()
			zoomFactor = 1
			exposureNormalized = 0
			applyProfile(selectedProfile)
			DispatchQueue.main.async {
				self.showToast(position == .back ? "Back camera" : "Front camera", tint: LensPalette.cyan)
				UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
			}
		} catch {
			DispatchQueue.main.async {
				self.showToast("Camera flip failed", tint: LensPalette.rose)
			}
		}
	}

	private func makeVideoInput(position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput {
		guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
			throw NSError(domain: "TopOpsLens", code: 1, userInfo: nil)
		}
		return try AVCaptureDeviceInput(device: device)
	}

	private func activeVideoDevice() -> AVCaptureDevice? {
		videoInput?.device
	}

	private func applyProfile(_ profile: CaptureProfile) {
		sessionQueue.async {
			guard let device = self.activeVideoDevice() else { return }
			self.captureSession.beginConfiguration()
			if self.captureSession.canSetSessionPreset(profile.preset) {
				self.captureSession.sessionPreset = profile.preset
			}
			self.captureSession.commitConfiguration()

			do {
				try device.lockForConfiguration()
				let fps = profile.framesPerSecond
				let duration = CMTime(value: 1, timescale: fps)
				if device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.minFrameRate <= Double(fps) && Double(fps) <= $0.maxFrameRate }) {
					device.activeVideoMinFrameDuration = duration
					device.activeVideoMaxFrameDuration = duration
				}
				device.unlockForConfiguration()
				DispatchQueue.main.async {
					self.showToast("\(profile.title) \(profile.summary)", tint: LensPalette.brass)
				}
			} catch {}
		}
	}

	private func setZoomFactor(_ value: CGFloat) {
		guard let device = activeVideoDevice() else { return }
		let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 8)
		let clamped = max(1, min(value, maxZoom))
		sessionQueue.async {
			do {
				try device.lockForConfiguration()
				device.videoZoomFactor = clamped
				device.unlockForConfiguration()
				DispatchQueue.main.async {
					self.zoomFactor = clamped
				}
			} catch {}
		}
	}

	private func setExposureNormalized(_ value: CGFloat) {
		guard let device = activeVideoDevice() else { return }
		let clamped = max(-1, min(value, 1))
		let minBias = device.minExposureTargetBias
		let maxBias = device.maxExposureTargetBias
		let bias = minBias + (Float(clamped + 1) / 2) * (maxBias - minBias)
		sessionQueue.async {
			do {
				try device.lockForConfiguration()
				device.setExposureTargetBias(bias, completionHandler: nil)
				device.unlockForConfiguration()
				DispatchQueue.main.async {
					self.exposureNormalized = clamped
				}
			} catch {}
		}
	}

	private func handlePhotoData(_ data: Data) {
		guard let image = UIImage(data: data) else {
			showToast("Photo failed", tint: LensPalette.rose)
			return
		}
		let prepared = processedImage(from: image)
		let outputData = prepared.jpegData(compressionQuality: 0.95) ?? data
		latestThumbnail = prepared
		savePhotoData(outputData)
	}

	private func processedImage(from image: UIImage) -> UIImage {
		let normalized = normalizedImage(image)
		let cropped = cropImage(normalized, guide: selectedGuide)
		return applyLook(selectedLook, to: cropped)
	}

	private func normalizedImage(_ image: UIImage) -> UIImage {
		guard image.imageOrientation != .up else { return image }
		let renderer = UIGraphicsImageRenderer(size: image.size, format: imageRendererFormat)
		return renderer.image { _ in
			image.draw(in: CGRect(origin: .zero, size: image.size))
		}
	}

	private func cropImage(_ image: UIImage, guide: FrameGuide) -> UIImage {
		guard let ratio = guide.aspectRatio, let cgImage = image.cgImage else { return image }
		let width = CGFloat(cgImage.width)
		let height = CGFloat(cgImage.height)
		let imageRatio = width / height

		var cropRect = CGRect(x: 0, y: 0, width: width, height: height)
		if imageRatio > ratio {
			let targetWidth = height * ratio
			cropRect.origin.x = (width - targetWidth) / 2
			cropRect.size.width = targetWidth
		} else {
			let targetHeight = width / ratio
			cropRect.origin.y = (height - targetHeight) / 2
			cropRect.size.height = targetHeight
		}

		guard let cropped = cgImage.cropping(to: cropRect.integral) else { return image }
		return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
	}

	private func applyLook(_ look: LensLook, to image: UIImage) -> UIImage {
		guard look != .clean, let ciImage = CIImage(image: image) else { return image }
		let output: CIImage
		switch look {
		case .clean:
			output = ciImage
		case .chrome:
			let filter = CIFilter.photoEffectChrome()
			filter.inputImage = ciImage
			output = filter.outputImage ?? ciImage
		case .sunset:
			let warm = CIFilter.colorControls()
			warm.inputImage = ciImage
			warm.saturation = 1.16
			warm.contrast = 1.08
			let exposed = CIFilter.exposureAdjust()
			exposed.inputImage = warm.outputImage
			exposed.ev = 0.22
			output = exposed.outputImage ?? ciImage
		case .noir:
			let filter = CIFilter.photoEffectNoir()
			filter.inputImage = ciImage
			output = filter.outputImage ?? ciImage
		case .frost:
			let cooled = CIFilter.colorControls()
			cooled.inputImage = ciImage
			cooled.saturation = 0.88
			cooled.contrast = 1.04
			let exposure = CIFilter.exposureAdjust()
			exposure.inputImage = cooled.outputImage
			exposure.ev = 0.15
			output = exposure.outputImage ?? ciImage
		}
		guard let cgImage = ciContext.createCGImage(output, from: output.extent) else { return image }
		return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
	}

	private func savePhotoData(_ data: Data) {
		let fallbackURL = Self.capturesDirectory().appendingPathComponent("photo-\(Self.timestamp()).jpg")
		if autoSaveToPhotos && (photoPermission == .authorized || photoPermission == .limited) {
			PHPhotoLibrary.shared().performChanges {
				let request = PHAssetCreationRequest.forAsset()
				request.addResource(with: .photo, data: data, options: nil)
			} completionHandler: { success, _ in
				DispatchQueue.main.async {
					if success {
						self.showToast("Saved to Photos", tint: LensPalette.mint)
					} else {
						try? data.write(to: fallbackURL)
						self.refreshLocalInventory()
						self.showToast("Saved to Captures", tint: LensPalette.brass)
					}
				}
			}
		} else {
			try? data.write(to: fallbackURL)
			refreshLocalInventory()
			showToast("Saved to Captures", tint: LensPalette.brass)
		}
	}

	private func saveVideo(at url: URL) {
		let fallbackURL = Self.capturesDirectory().appendingPathComponent(url.lastPathComponent)
		let completeFallback: () -> Void = {
			do {
				try? FileManager.default.removeItem(at: fallbackURL)
				try FileManager.default.copyItem(at: url, to: fallbackURL)
				self.refreshLocalInventory()
				self.showToast("Clip saved to Captures", tint: LensPalette.brass)
			} catch {
				self.showToast("Video save failed", tint: LensPalette.rose)
			}
		}

		if autoSaveToPhotos && (photoPermission == .authorized || photoPermission == .limited) {
			PHPhotoLibrary.shared().performChanges {
				PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
			} completionHandler: { success, _ in
				DispatchQueue.main.async {
					if success {
						self.showToast("Clip saved to Photos", tint: LensPalette.mint)
					} else {
						completeFallback()
					}
				}
			}
		} else {
			completeFallback()
		}
		updateVideoThumbnail(from: url)
	}

	private func updateVideoThumbnail(from url: URL) {
		let asset = AVAsset(url: url)
		let generator = AVAssetImageGenerator(asset: asset)
		generator.appliesPreferredTrackTransform = true
		let time = CMTime(seconds: 0.2, preferredTimescale: 600)
		if let image = try? generator.copyCGImage(at: time, actualTime: nil) {
			latestThumbnail = UIImage(cgImage: image)
		}
	}

	private func refreshLocalInventory() {
		let count = (try? FileManager.default.contentsOfDirectory(at: Self.capturesDirectory(), includingPropertiesForKeys: nil).count) ?? 0
		DispatchQueue.main.async {
			self.localCaptureCount = count
		}
	}

	private func showToast(_ message: String, tint: Color) {
		DispatchQueue.main.async {
			self.toast = LensToast(message: message, tint: tint)
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
				if self.toast?.message == message {
					self.toast = nil
				}
			}
		}
	}

	private func beginRecordingUI() {
		DispatchQueue.main.async {
			self.isRecording = true
			self.recordingStartDate = Date()
			self.recordingDuration = "00:00"
			self.recordingTimer?.invalidate()
			self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
				guard let start = self.recordingStartDate else { return }
				let elapsed = Int(Date().timeIntervalSince(start))
				self.recordingDuration = String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
			}
			self.showToast("Recording", tint: LensPalette.rose)
		}
	}

	private func endRecordingUI() {
		DispatchQueue.main.async {
			self.isRecording = false
			self.recordingTimer?.invalidate()
			self.recordingTimer = nil
			self.recordingStartDate = nil
			self.recordingDuration = "00:00"
		}
	}

	private static func capturesDirectory() -> URL {
		documentsDirectory().appendingPathComponent("Captures", isDirectory: true)
	}

	private static func exportsDirectory() -> URL {
		documentsDirectory().appendingPathComponent("Exports", isDirectory: true)
	}

	private static func documentsDirectory() -> URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
	}

	private static func timestamp() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd-HHmmss"
		return formatter.string(from: Date())
	}
}

extension LensCameraController: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		DispatchQueue.main.async {
			if error != nil {
				self.showToast("Photo failed", tint: LensPalette.rose)
				return
			}
			guard let data = photo.fileDataRepresentation() else {
				self.showToast("Photo empty", tint: LensPalette.rose)
				return
			}
			self.handlePhotoData(data)
		}
	}
}

extension LensCameraController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
		beginRecordingUI()
	}

	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		endRecordingUI()
		guard error == nil else {
			showToast("Clip failed", tint: LensPalette.rose)
			return
		}
		saveVideo(at: outputFileURL)
	}
}
