import SwiftUI

enum LensPalette {
	static let obsidian = Color(red: 0.05, green: 0.06, blue: 0.09)
	static let smoke = Color(red: 0.13, green: 0.14, blue: 0.18)
	static let pearl = Color(red: 0.95, green: 0.96, blue: 0.98)
	static let ember = Color(red: 0.95, green: 0.48, blue: 0.29)
	static let brass = Color(red: 0.90, green: 0.68, blue: 0.32)
	static let mint = Color(red: 0.36, green: 0.82, blue: 0.63)
	static let cyan = Color(red: 0.38, green: 0.76, blue: 0.93)
	static let rose = Color(red: 0.95, green: 0.52, blue: 0.66)
}

struct LensBackground: View {
	var body: some View {
		ZStack {
			LinearGradient(
				colors: [LensPalette.obsidian, Color.black, LensPalette.smoke],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			Rectangle()
				.fill(
					RadialGradient(
						colors: [LensPalette.ember.opacity(0.32), .clear],
						center: .bottomLeading,
						startRadius: 20,
						endRadius: 260
					)
				)
			Rectangle()
				.fill(
					RadialGradient(
						colors: [LensPalette.cyan.opacity(0.18), .clear],
						center: .topTrailing,
						startRadius: 20,
						endRadius: 280
					)
				)
		}
		.ignoresSafeArea()
	}
}

struct GlassPanel<Content: View>: View {
	let content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		content
			.padding(16)
			.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 28, style: .continuous)
					.strokeBorder(.white.opacity(0.10), lineWidth: 1)
			)
	}
}

struct CapsuleBadge: View {
	let label: String
	let tint: Color

	var body: some View {
		Text(label)
			.font(.caption.weight(.semibold))
			.foregroundStyle(.white)
			.padding(.horizontal, 11)
			.padding(.vertical, 7)
			.background(tint.opacity(0.24), in: Capsule())
			.overlay(
				Capsule()
					.strokeBorder(tint.opacity(0.65), lineWidth: 1)
			)
	}
}
