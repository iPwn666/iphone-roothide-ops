import AVFoundation
import SwiftUI
import UIKit

struct RootView: View {
	var body: some View {
		ZStack {
			LensBackground()

			VStack(alignment: .leading, spacing: 24) {
				Spacer()

				CapsuleBadge(label: "Safe Mode", tint: LensPalette.brass)

				Text("TopOps Lens")
					.font(.system(size: 40, weight: .bold, design: .rounded))
					.foregroundStyle(.white)

				Text("This verification build strips camera runtime and opens into a static native shell. If this screen stays up, launch, signing, and registration are healthy on your phone.")
					.font(.title3)
					.foregroundStyle(.white.opacity(0.74))
					.fixedSize(horizontal: false, vertical: true)

				GlassPanel {
					VStack(alignment: .leading, spacing: 12) {
						StatusRow(symbol: "checkmark.shield.fill", title: "Launch path", subtitle: "UIKit + SwiftUI shell only")
						StatusRow(symbol: "iphone.gen3", title: "Target phone", subtitle: "iPhone XS / iOS 16.3 baseline")
						StatusRow(symbol: "wrench.and.screwdriver.fill", title: "Next step", subtitle: "Re-enable camera pieces one layer at a time")
					}
				}

				Text("Once this build opens reliably, the next pass will restore preview, permissions, and capture incrementally.")
					.font(.footnote)
					.foregroundStyle(.white.opacity(0.58))

				Spacer()
			}
			.padding(24)
		}
		.statusBarHidden(true)
	}
}

private struct StatusRow: View {
	let symbol: String
	let title: String
	let subtitle: String

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: symbol)
				.font(.system(size: 16, weight: .bold))
				.frame(width: 22)
				.foregroundStyle(LensPalette.cyan)
			VStack(alignment: .leading, spacing: 3) {
				Text(title)
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.white)
				Text(subtitle)
					.font(.footnote)
					.foregroundStyle(.white.opacity(0.68))
			}
		}
	}
}

private struct CameraSurface: View {
	@ObservedObject var camera: LensCameraController

	var body: some View {
		GeometryReader { proxy in
			ZStack {
				LensPreviewView(camera: camera)
					ignoresSafeArea()

				LinearGradient(
					colors: camera.selectedLook.overlay,
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.ignoresSafeArea()
				.allowsHitTesting(false)

				FrameGuideOverlay(guide: camera.selectedGuide)
					.stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 10]))
					.foregroundStyle(.white.opacity(0.42))
					.padding(.horizontal, 24)
					.padding(.vertical, 150)
					.allowsHitTesting(false)

				if let marker = camera.focusMarker {
					FocusMarkerView()
						.position(
							x: max(24, min(proxy.size.width - 24, marker.normalizedPoint.x * proxy.size.width)),
							y: max(44, min(proxy.size.height - 44, marker.normalizedPoint.y * proxy.size.height))
						)
						.transition(.scale.combined(with: .opacity))
				}

				VStack(spacing: 16) {
					TopBar(camera: camera)
					Spacer()
					ExposureMeter(camera: camera)
						.frame(maxWidth: .infinity, alignment: .trailing)
					BottomDeck(camera: camera)
				}
				.padding(.horizontal, 18)
				.padding(.top, 14)
				.padding(.bottom, 18)

				if let toast = camera.toast {
					VStack {
						Spacer()
						CapsuleBadge(label: toast.message, tint: toast.tint)
							.padding(.bottom, 182)
					}
					.transition(.move(edge: .bottom).combined(with: .opacity))
				}

				if !camera.isReady {
					VStack(spacing: 12) {
						ProgressView()
							.tint(.white)
						Text(camera.sessionMessage)
							.font(.footnote.weight(.semibold))
							.foregroundStyle(.white.opacity(0.76))
					}
					.padding(20)
					.background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
				}
			}
			.animation(.spring(response: 0.32, dampingFraction: 0.85), value: camera.focusMarker?.id)
			.animation(.spring(response: 0.36, dampingFraction: 0.88), value: camera.toast?.id)
		}
	}
}

private struct TopBar: View {
	@ObservedObject var camera: LensCameraController

	var body: some View {
		HStack(spacing: 12) {
			GlassPanel {
				VStack(alignment: .leading, spacing: 4) {
					Text("TopOps Lens")
						.font(.system(size: 24, weight: .bold, design: .rounded))
						.foregroundStyle(.white)
					Text("Fast native capture tuned for your phone.")
						.font(.caption)
						.foregroundStyle(.white.opacity(0.72))
				}
			}

			Spacer(minLength: 0)

			VStack(alignment: .trailing, spacing: 8) {
				CapsuleBadge(label: camera.selectedProfile.summary, tint: LensPalette.brass)
				CapsuleBadge(label: camera.captureDestinationLabel, tint: LensPalette.cyan)
				if camera.isRecording {
					CapsuleBadge(label: camera.recordingDuration, tint: LensPalette.rose)
				}
			}
		}
	}
}

private struct ExposureMeter: View {
	@ObservedObject var camera: LensCameraController

	private var formatted: String {
		let sign = camera.exposureNormalized >= 0 ? "+" : ""
		return "\(sign)\(String(format: "%.1f", camera.exposureNormalized)) EV"
	}

	var body: some View {
		GlassPanel {
			VStack(spacing: 12) {
				Text("Exposure")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.white.opacity(0.82))
				ZStack(alignment: .bottom) {
					Capsule()
						.fill(.white.opacity(0.10))
						.frame(width: 10, height: 150)
					Capsule()
						.fill(
							LinearGradient(
								colors: [LensPalette.cyan, LensPalette.brass, LensPalette.ember],
								startPoint: .bottom,
								endPoint: .top
							)
						)
						.frame(width: 10, height: max(38, 74 + (camera.exposureNormalized * 36)))
				}
				Text(formatted)
					.font(.caption2.monospacedDigit())
					.foregroundStyle(.white.opacity(0.78))
			}
			.frame(width: 76)
		}
	}
}

private struct BottomDeck: View {
	@ObservedObject var camera: LensCameraController

	var body: some View {
		VStack(spacing: 14) {
			GlassPanel {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 10) {
						ForEach(CaptureProfile.allCases) { profile in
							SelectableChip(
								title: profile.title,
								subtitle: profile.summary,
								tint: profile == camera.selectedProfile ? LensPalette.brass : .white.opacity(0.24),
								isSelected: profile == camera.selectedProfile
							) {
								camera.setProfile(profile)
							}
						}
					}
				}
			}

			GlassPanel {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 10) {
						ForEach(LensLook.allCases) { look in
							Button {
								camera.setLook(look)
							} label: {
								HStack(spacing: 8) {
									Image(systemName: look.symbol)
									Text(look.title)
								}
								.font(.caption.weight(.semibold))
								.padding(.horizontal, 12)
								.padding(.vertical, 10)
								.background(
									Capsule()
										.fill(look == camera.selectedLook ? look.tint.opacity(0.22) : .white.opacity(0.08))
								)
								.overlay(
									Capsule()
										.strokeBorder(look == camera.selectedLook ? look.tint : .white.opacity(0.10), lineWidth: 1)
								)
							}
							.foregroundStyle(.white)
						}
					}
				}
			}

			HStack(alignment: .center, spacing: 16) {
				ThumbnailDock(image: camera.latestThumbnail, count: camera.localCaptureCount)

				Spacer(minLength: 0)

				LensShutterButton(camera: camera)

				Spacer(minLength: 0)

				VStack(spacing: 10) {
					ControlCircle(symbol: "camera.rotate.fill", tint: LensPalette.cyan) {
						camera.flipCamera()
					}
					ControlCircle(symbol: camera.captureDestinationLabel == "Photos" ? "photo.on.rectangle.angled" : "folder.fill", tint: LensPalette.brass) {
						camera.toggleAutoSaveToPhotos()
					}
				}
			}

			GlassPanel {
				HStack(spacing: 10) {
					ForEach(FrameGuide.allCases) { guide in
						Button {
							camera.setGuide(guide)
						} label: {
							Text(guide.title)
								.font(.caption.weight(.semibold))
								.padding(.horizontal, 12)
								.padding(.vertical, 10)
								.frame(maxWidth: .infinity)
								.background(
									RoundedRectangle(cornerRadius: 18, style: .continuous)
										.fill(guide == camera.selectedGuide ? LensPalette.cyan.opacity(0.22) : .white.opacity(0.06))
								)
								.overlay(
									RoundedRectangle(cornerRadius: 18, style: .continuous)
										.strokeBorder(guide == camera.selectedGuide ? LensPalette.cyan : .white.opacity(0.10), lineWidth: 1)
								)
						}
						.foregroundStyle(.white)
					}
				}
			}
		}
	}
}

private struct ThumbnailDock: View {
	let image: UIImage?
	let count: Int

	var body: some View {
		GlassPanel {
			VStack(alignment: .leading, spacing: 8) {
				if let image {
					Image(uiImage: image)
						.resizable()
						.scaledToFill()
						.frame(width: 78, height: 78)
						.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
				} else {
					RoundedRectangle(cornerRadius: 22, style: .continuous)
						.fill(.white.opacity(0.08))
						.frame(width: 78, height: 78)
						.overlay(
							Image(systemName: "photo.stack.fill")
								.font(.system(size: 22, weight: .bold))
								.foregroundStyle(.white.opacity(0.68))
						)
				}
				Text("\(count) local")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.white.opacity(0.84))
			}
		}
	}
}

private struct SelectableChip: View {
	let title: String
	let subtitle: String
	let tint: Color
	let isSelected: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.caption.weight(.bold))
				Text(subtitle)
					.font(.caption2)
					.foregroundStyle(.white.opacity(0.62))
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 12)
			.frame(width: 118, alignment: .leading)
			.background(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(isSelected ? tint.opacity(0.22) : .white.opacity(0.06))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.strokeBorder(isSelected ? tint : .white.opacity(0.10), lineWidth: 1)
			)
		}
		.foregroundStyle(.white)
	}
}

private struct ControlCircle: View {
	let symbol: String
	let tint: Color
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Image(systemName: symbol)
				.font(.system(size: 20, weight: .bold))
				.frame(width: 54, height: 54)
				.background(.ultraThinMaterial, in: Circle())
				.overlay(Circle().strokeBorder(tint.opacity(0.82), lineWidth: 1))
		}
		.foregroundStyle(.white)
	}
}

private struct FocusMarkerView: View {
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.strokeBorder(LensPalette.brass, lineWidth: 2)
				.frame(width: 70, height: 70)
			Circle()
				.fill(LensPalette.brass)
				.frame(width: 8, height: 8)
		}
		.shadow(color: LensPalette.brass.opacity(0.35), radius: 12, x: 0, y: 0)
	}
}

private struct PermissionView: View {
	@ObservedObject var camera: LensCameraController

	var body: some View {
		VStack(spacing: 18) {
			Image(systemName: "camera.aperture")
				.font(.system(size: 56, weight: .bold))
				.foregroundStyle(LensPalette.brass)
			Text("Allow camera access")
				.font(.system(size: 28, weight: .bold, design: .rounded))
				.foregroundStyle(.white)
			Text("TopOps Lens needs Camera and, for video, Microphone access. Photo permission is optional but unlocks direct save to Photos.")
				.font(.body)
				.multilineTextAlignment(.center)
				.foregroundStyle(.white.opacity(0.72))
				.padding(.horizontal, 26)

			HStack(spacing: 12) {
				Button("Open Settings") {
					camera.openSettings()
				}
				.buttonStyle(.borderedProminent)
				.tint(LensPalette.brass)

				Button("Retry") {
					camera.prepareSession()
				}
				.buttonStyle(.bordered)
				.tint(.white)
			}
		}
		.padding(26)
		.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
		.padding(24)
	}
}

private struct LensPreviewView: UIViewRepresentable {
	@ObservedObject var camera: LensCameraController

	func makeUIView(context: Context) -> CameraPreviewUIView {
		let view = CameraPreviewUIView()
		view.attach(camera: camera)
		return view
	}

	func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
		uiView.attach(camera: camera)
	}
}

private final class CameraPreviewUIView: UIView {
	private weak var camera: LensCameraController?
	private var doubleTap: UITapGestureRecognizer?
	private var singleTap: UITapGestureRecognizer?
	private var pinch: UIPinchGestureRecognizer?
	private var pan: UIPanGestureRecognizer?

	override class var layerClass: AnyClass {
		AVCaptureVideoPreviewLayer.self
	}

	private var previewLayer: AVCaptureVideoPreviewLayer {
		layer as! AVCaptureVideoPreviewLayer
	}

	func attach(camera: LensCameraController) {
		if self.camera !== camera {
			self.camera = camera
			previewLayer.session = camera.session
			previewLayer.videoGravity = .resizeAspectFill
			configureGesturesIfNeeded()
		}
	}

	private func configureGesturesIfNeeded() {
		guard singleTap == nil else { return }

		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		addGestureRecognizer(doubleTap)
		self.doubleTap = doubleTap

		let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
		singleTap.require(toFail: doubleTap)
		addGestureRecognizer(singleTap)
		self.singleTap = singleTap

		let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
		addGestureRecognizer(pinch)
		self.pinch = pinch

		let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		pan.maximumNumberOfTouches = 1
		addGestureRecognizer(pan)
		self.pan = pan
	}

	@objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
		guard let camera else { return }
		let point = gesture.location(in: self)
		let converted = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
		let normalized = CGPoint(x: point.x / bounds.width, y: point.y / bounds.height)
		camera.focus(at: converted, normalizedPoint: normalized)
	}

	@objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
		camera?.flipCamera()
	}

	@objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
		guard let camera else { return }
		switch gesture.state {
		case .began:
			camera.beginPinch()
		case .changed:
			camera.updateZoom(scale: gesture.scale)
		default:
			break
		}
	}

	@objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
		guard let camera else { return }
		switch gesture.state {
		case .began:
			camera.beginExposureGesture()
		case .changed:
			camera.updateExposureGesture(verticalTranslation: gesture.translation(in: self).y)
		default:
			break
		}
	}
}

private struct LensShutterButton: UIViewRepresentable {
	@ObservedObject var camera: LensCameraController

	func makeUIView(context: Context) -> HoldShutterButton {
		let button = HoldShutterButton()
		button.onTapCapture = { [weak camera] in
			camera?.capturePhoto()
		}
		button.onStartRecording = { [weak camera] in
			camera?.startRecording()
		}
		button.onStopRecording = { [weak camera] in
			camera?.stopRecording()
		}
		button.isRecording = camera.isRecording
		return button
	}

	func updateUIView(_ uiView: HoldShutterButton, context: Context) {
		uiView.isRecording = camera.isRecording
	}
}

private final class HoldShutterButton: UIControl {
	var onTapCapture: (() -> Void)?
	var onStartRecording: (() -> Void)?
	var onStopRecording: (() -> Void)?
	var isRecording = false {
		didSet { setNeedsDisplay() }
	}

	private var pendingLongPress: DispatchWorkItem?
	private var isHolding = false
	private var longPressTriggered = false

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .clear
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var intrinsicContentSize: CGSize {
		CGSize(width: 102, height: 102)
	}

	override func draw(_ rect: CGRect) {
		let outer = UIBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3))
		UIColor.white.withAlphaComponent(0.18).setFill()
		outer.fill()

		let innerRect = rect.insetBy(dx: isRecording ? 28 : 18, dy: isRecording ? 28 : 18)
		let innerPath: UIBezierPath
		if isRecording {
			innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 18)
			UIColor.systemRed.setFill()
		} else {
			innerPath = UIBezierPath(ovalIn: innerRect)
			UIColor.white.setFill()
		}
		innerPath.fill()
	}

	override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		isHolding = true
		longPressTriggered = false
		let item = DispatchWorkItem { [weak self] in
			guard let self, self.isHolding else { return }
			self.longPressTriggered = true
			self.isRecording = true
			self.setNeedsDisplay()
			self.onStartRecording?()
		}
		pendingLongPress = item
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.24, execute: item)
		return true
	}

	override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
		finishInteraction()
	}

	override func cancelTracking(with event: UIEvent?) {
		finishInteraction()
	}

	private func finishInteraction() {
		isHolding = false
		pendingLongPress?.cancel()
		pendingLongPress = nil
		if longPressTriggered || isRecording {
			onStopRecording?()
		} else {
			onTapCapture?()
		}
		isRecording = false
		longPressTriggered = false
		setNeedsDisplay()
	}
}

private struct FrameGuideOverlay: Shape {
	let guide: FrameGuide

	func path(in rect: CGRect) -> Path {
		guard let ratio = guide.aspectRatio else {
			return Path(roundedRect: rect, cornerRadius: 28)
		}

		let fitted: CGRect
		let currentRatio = rect.width / rect.height
		if currentRatio > ratio {
			let width = rect.height * ratio
			fitted = CGRect(x: rect.midX - (width / 2), y: rect.minY, width: width, height: rect.height)
		} else {
			let height = rect.width / ratio
			fitted = CGRect(x: rect.minX, y: rect.midY - (height / 2), width: rect.width, height: height)
		}
		return Path(roundedRect: fitted, cornerRadius: 28)
	}
}
