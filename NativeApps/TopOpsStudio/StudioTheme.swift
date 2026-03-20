import SwiftUI

enum StudioPalette {
	static let ink = Color(red: 0.08, green: 0.11, blue: 0.17)
	static let graphite = Color(red: 0.18, green: 0.22, blue: 0.29)
	static let tide = Color(red: 0.09, green: 0.56, blue: 0.68)
	static let mint = Color(red: 0.24, green: 0.72, blue: 0.56)
	static let amber = Color(red: 0.92, green: 0.63, blue: 0.21)
	static let coral = Color(red: 0.86, green: 0.37, blue: 0.39)
	static let paper = Color(red: 0.97, green: 0.98, blue: 0.99)
	static let haze = Color(red: 0.90, green: 0.94, blue: 0.97)
}

struct StudioBackground: View {
	var body: some View {
		ZStack {
			LinearGradient(
				colors: [Color.white, StudioPalette.paper, StudioPalette.haze],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			Rectangle()
				.fill(
					RadialGradient(
						colors: [StudioPalette.tide.opacity(0.16), .clear],
						center: .topLeading,
						startRadius: 40,
						endRadius: 420
					)
				)
			Rectangle()
				.fill(
					RadialGradient(
						colors: [StudioPalette.amber.opacity(0.10), .clear],
						center: .bottomTrailing,
						startRadius: 60,
						endRadius: 360
					)
				)
		}
		.ignoresSafeArea()
	}
}

struct FrostCard<Content: View>: View {
	let title: String
	let subtitle: String?
	let content: Content

	init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
		self.title = title
		self.subtitle = subtitle
		self.content = content()
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(.headline, design: .rounded).weight(.semibold))
					.foregroundStyle(StudioPalette.ink)
				if let subtitle, !subtitle.isEmpty {
					Text(subtitle)
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			}
			content
		}
		.padding(18)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 28, style: .continuous)
				.fill(.white.opacity(0.92))
				.shadow(color: StudioPalette.ink.opacity(0.08), radius: 20, x: 0, y: 12)
		)
	}
}

struct PillLabel: View {
	let text: String
	let tint: Color

	var body: some View {
		Text(text)
			.font(.caption.weight(.semibold))
			.padding(.horizontal, 10)
			.padding(.vertical, 6)
			.background(tint.opacity(0.12), in: Capsule())
			.foregroundStyle(tint)
	}
}
