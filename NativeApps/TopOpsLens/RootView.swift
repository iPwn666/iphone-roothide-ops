import SwiftUI

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

				Text("This verification build is a minimal native shell with no camera runtime, no Photos runtime, and no custom launch dependencies.")
					.font(.title3)
					.foregroundStyle(.white.opacity(0.74))
					.fixedSize(horizontal: false, vertical: true)

				GlassPanel {
					VStack(alignment: .leading, spacing: 12) {
						StatusRow(symbol: "checkmark.shield.fill", title: "Launch path", subtitle: "UIKit + SwiftUI only")
						StatusRow(symbol: "iphone.gen3", title: "Target", subtitle: "iPhone XS / iOS 16.3")
						StatusRow(symbol: "wrench.and.screwdriver.fill", title: "Purpose", subtitle: "Verify pure app launch before restoring camera layers")
					}
				}

				Text("If this opens and stays visible, the remaining problem is inside the original camera stack, not deploy, signing, or bundle registration.")
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
