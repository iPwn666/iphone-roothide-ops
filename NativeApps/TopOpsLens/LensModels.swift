import AVFoundation
import CoreGraphics
import SwiftUI

enum CaptureProfile: String, CaseIterable, Identifiable {
	case speed
	case social
	case cinema

	var id: String { rawValue }

	var title: String {
		switch self {
		case .speed:
			return "Speed"
		case .social:
			return "Social"
		case .cinema:
			return "Cinema"
		}
	}

	var summary: String {
		switch self {
		case .speed:
			return "1080p / 60"
		case .social:
			return "High / 30"
		case .cinema:
			return "4K / 30"
		}
	}

	var preset: AVCaptureSession.Preset {
		switch self {
		case .speed:
			return .hd1920x1080
		case .social:
			return .high
		case .cinema:
			return .hd4K3840x2160
		}
	}

	var framesPerSecond: Int32 {
		switch self {
		case .speed:
			return 60
		case .social:
			return 30
		case .cinema:
			return 30
		}
	}
}

enum LensLook: String, CaseIterable, Identifiable {
	case clean
	case chrome
	case sunset
	case noir
	case frost

	var id: String { rawValue }

	var title: String {
		switch self {
		case .clean:
			return "Clean"
		case .chrome:
			return "Chrome"
		case .sunset:
			return "Sunset"
		case .noir:
			return "Noir"
		case .frost:
			return "Frost"
		}
	}

	var symbol: String {
		switch self {
		case .clean:
			return "camera.aperture"
		case .chrome:
			return "sparkles"
		case .sunset:
			return "sun.max.fill"
		case .noir:
			return "moon.stars.fill"
		case .frost:
			return "snowflake"
		}
	}

	var tint: Color {
		switch self {
		case .clean:
			return LensPalette.pearl
		case .chrome:
			return LensPalette.brass
		case .sunset:
			return LensPalette.ember
		case .noir:
			return LensPalette.rose
		case .frost:
			return LensPalette.cyan
		}
	}

	var overlay: [Color] {
		switch self {
		case .clean:
			return [.clear, .clear]
		case .chrome:
			return [LensPalette.brass.opacity(0.18), LensPalette.rose.opacity(0.05)]
		case .sunset:
			return [LensPalette.ember.opacity(0.24), LensPalette.brass.opacity(0.08)]
		case .noir:
			return [Color.black.opacity(0.18), Color.black.opacity(0.36)]
		case .frost:
			return [LensPalette.cyan.opacity(0.20), LensPalette.pearl.opacity(0.06)]
		}
	}
}

enum FrameGuide: String, CaseIterable, Identifiable {
	case full
	case vertical
	case portrait
	case square

	var id: String { rawValue }

	var title: String {
		switch self {
		case .full:
			return "Full"
		case .vertical:
			return "9:16"
		case .portrait:
			return "4:5"
		case .square:
			return "1:1"
		}
	}

	var aspectRatio: CGFloat? {
		switch self {
		case .full:
			return nil
		case .vertical:
			return 9.0 / 16.0
		case .portrait:
			return 4.0 / 5.0
		case .square:
			return 1.0
		}
	}
}

struct FocusMarker: Identifiable {
	let id = UUID()
	let normalizedPoint: CGPoint
}

struct LensToast: Identifiable {
	let id = UUID()
	let message: String
	let tint: Color
}
