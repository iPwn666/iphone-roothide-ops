import SwiftUI

struct RootView: View {
	var body: some View {
		TabView {
			NavigationStack {
				DashboardView()
			}
			.tabItem {
				Label("Prehled", systemImage: "rectangle.grid.2x2.fill")
			}

			NavigationStack {
				HandbookView()
			}
			.tabItem {
				Label("Navody", systemImage: "book.closed.fill")
			}

			NavigationStack {
				RecoveryView()
			}
			.tabItem {
				Label("Obnova", systemImage: "cross.case.fill")
			}

			NavigationStack {
				ToolkitView()
			}
			.tabItem {
				Label("Nastroje", systemImage: "wrench.and.screwdriver.fill")
			}
		}
		.tint(AppPalette.ocean)
	}
}

private struct DashboardView: View {
	private let columns = [
		GridItem(.flexible(), spacing: 14),
		GridItem(.flexible(), spacing: 14)
	]

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				HeroCard()

				LazyVGrid(columns: columns, spacing: 14) {
					ForEach(OpsContent.metrics) { metric in
						MetricCard(metric: metric)
					}
				}

				SurfaceCard(title: "Aktualne dulezite", subtitle: "Rychly stav telefonu, repa a recovery workflow.") {
					VStack(alignment: .leading, spacing: 12) {
						ForEach(OpsContent.highlights, id: \.self) { item in
							Label(item, systemImage: "sparkles")
								.font(.subheadline)
								.foregroundStyle(AppPalette.ink)
								.labelStyle(.titleAndIcon)
						}
					}
				}

				SurfaceCard(title: "Repozitar", subtitle: "Verejna dokumentace, audit a helpery pro iPhone i host.") {
					VStack(alignment: .leading, spacing: 12) {
						Link(destination: OpsContent.repoURL) {
							Label("Otevrit GitHub repo", systemImage: "arrow.up.forward.square.fill")
								.font(.headline)
						}

						ShareLink(item: OpsContent.repoURL) {
							Label("Sdilet odkaz", systemImage: "square.and.arrow.up.fill")
						}
						.font(.subheadline.weight(.semibold))
						.tint(AppPalette.steel)
					}
				}
			}
			.padding(20)
		}
		.background(AppBackground())
		.navigationTitle("Prehled")
	}
}

private struct HandbookView: View {
	@State private var query = ""

	private var filtered: [OpsArticle] {
		if query.isEmpty {
			return OpsContent.articles
		}
		return OpsContent.articles.filter { article in
			article.title.localizedCaseInsensitiveContains(query)
			|| article.summary.localizedCaseInsensitiveContains(query)
			|| article.sections.contains(where: { section in
				section.title.localizedCaseInsensitiveContains(query)
				|| section.body.localizedCaseInsensitiveContains(query)
				|| section.bullets.contains(where: { $0.localizedCaseInsensitiveContains(query) })
			})
		}
	}

	var body: some View {
		List {
			Section {
				ForEach(filtered) { article in
					NavigationLink {
						ArticleDetailView(article: article)
					} label: {
						ArticleRow(article: article)
					}
				}
			}
		}
		.scrollContentBackground(.hidden)
		.background(AppBackground())
		.navigationTitle("Navody")
		.searchable(text: $query, prompt: "Hledat v dokumentaci")
	}
}

private struct RecoveryView: View {
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				SurfaceCard(title: "Poradi obnovy", subtitle: "Nejdriv spojeni, potom shell, az nakonec balicky a tweaky.") {
					VStack(alignment: .leading, spacing: 10) {
						RecoveryOrderRow(index: "1", title: "Transport", detail: "Nejdriv WireGuard, potom USB localhost forwarding.")
						RecoveryOrderRow(index: "2", title: "SSH", detail: "Obnovit mobile a root pristup jeste pred praci s balicky.")
						RecoveryOrderRow(index: "3", title: "APT", detail: "Repozitare resit az ve chvili, kdy je shell opravdu stabilni.")
						RecoveryOrderRow(index: "4", title: "Tweaky", detail: "Rizikove injektory presouvat do karanteny, ne mazat naslepo.")
					}
				}

				ForEach(OpsContent.recoveryFlows) { flow in
					RecoveryCard(flow: flow)
				}
			}
			.padding(20)
		}
		.background(AppBackground())
		.navigationTitle("Obnova")
	}
}

private struct ToolkitView: View {
	var grouped: [String: [ToolkitItem]] {
		Dictionary(grouping: OpsContent.tools, by: \.category)
	}

	var body: some View {
		List {
			ForEach(grouped.keys.sorted(), id: \.self) { category in
				Section(category) {
					ForEach(grouped[category] ?? []) { item in
						VStack(alignment: .leading, spacing: 8) {
							Label(item.title, systemImage: item.symbol)
								.font(.headline)
								.foregroundStyle(AppPalette.ink)
							Text(item.summary)
								.font(.subheadline)
								.foregroundStyle(.secondary)
							Text(item.location)
								.font(.footnote.monospaced())
								.foregroundStyle(AppPalette.ocean)
						}
						.padding(.vertical, 4)
					}
				}
			}

			Section("Instalace") {
				VStack(alignment: .leading, spacing: 8) {
					Text("Repo uz obsahuje GitHub Actions build, takze z nej jde rovnou vyrobit .ipa i .tipa artifact pro TrollStore instalaci.")
						.font(.subheadline)
						.foregroundStyle(.secondary)
					Text("scripts/install_native_app_on_phone.py")
						.font(.footnote.monospaced())
						.foregroundStyle(AppPalette.ocean)
				}
				.padding(.vertical, 4)
			}
		}
		.scrollContentBackground(.hidden)
		.background(AppBackground())
		.navigationTitle("Nastroje")
	}
}

private struct ArticleDetailView: View {
	let article: OpsArticle

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				VStack(alignment: .leading, spacing: 10) {
					Image(systemName: article.symbol)
						.font(.system(size: 28, weight: .bold))
						.foregroundStyle(article.tint)
					Text(article.title)
						.font(.system(size: 30, weight: .bold, design: .rounded))
						.foregroundStyle(AppPalette.ink)
					Text(article.summary)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}

				ForEach(article.sections) { section in
					SurfaceCard(title: section.title) {
						VStack(alignment: .leading, spacing: 12) {
							Text(section.body)
								.font(.body)
								.foregroundStyle(AppPalette.ink)
							ForEach(section.bullets, id: \.self) { bullet in
								HStack(alignment: .top, spacing: 10) {
									Image(systemName: "circle.fill")
										.font(.system(size: 6))
										.foregroundStyle(article.tint)
										.padding(.top, 7)
									Text(bullet)
										.font(.subheadline)
										.foregroundStyle(.secondary)
								}
							}
						}
					}
				}
			}
			.padding(20)
		}
		.background(AppBackground())
		.navigationTitle(article.title)
		.navigationBarTitleDisplayMode(.inline)
	}
}

private struct HeroCard: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 18) {
			HStack(alignment: .top, spacing: 16) {
				VStack(alignment: .leading, spacing: 10) {
					Text("Roothide Ops")
						.font(.system(.footnote, design: .rounded).weight(.semibold))
						.foregroundStyle(.white.opacity(0.72))
						.textCase(.uppercase)
					Text("Nativni iPhone prehled pro roothide zarizeni")
						.font(.system(size: 28, weight: .bold, design: .rounded))
						.foregroundStyle(.white)
					Text("Cisty a rychly prehled nad stabilizaci, recovery postupy, APT pravidly a host-side helpery bez otevirani markdownu.")
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.84))
				}

				Spacer(minLength: 12)

				VStack(spacing: 6) {
					Text("Profil")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.white.opacity(0.68))
					Text("XS")
						.font(.system(size: 34, weight: .bold, design: .rounded))
						.foregroundStyle(.white)
				}
				.padding(.horizontal, 18)
				.padding(.vertical, 12)
				.background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
			}

			HStack(spacing: 10) {
				StatusPill(text: "APT ciste", tint: .white)
				StatusPill(text: "SSH pripraveno", tint: .white)
				StatusPill(text: "Tweaky zuzene", tint: .white)
			}
		}
		.padding(22)
		.background(
			LinearGradient(
				colors: [AppPalette.ink, AppPalette.steel, AppPalette.ocean],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			),
			in: RoundedRectangle(cornerRadius: 30, style: .continuous)
		)
	}
}

private struct MetricCard: View {
	let metric: OpsMetric

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Image(systemName: metric.symbol)
				.font(.system(size: 22, weight: .bold))
				.foregroundStyle(metric.tint)
			Text(metric.title)
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)
				.textCase(.uppercase)
			Text(metric.value)
				.font(.system(size: 24, weight: .bold, design: .rounded))
				.foregroundStyle(AppPalette.ink)
			Text(metric.detail)
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(.white.opacity(0.94))
				.shadow(color: AppPalette.ink.opacity(0.06), radius: 16, x: 0, y: 10)
		)
	}
}

private struct ArticleRow: View {
	let article: OpsArticle

	var body: some View {
		HStack(alignment: .top, spacing: 14) {
			Image(systemName: article.symbol)
				.font(.system(size: 18, weight: .semibold))
				.foregroundStyle(article.tint)
				.frame(width: 24, height: 24)
			VStack(alignment: .leading, spacing: 4) {
				Text(article.title)
					.font(.headline)
					.foregroundStyle(AppPalette.ink)
				Text(article.summary)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(2)
			}
		}
		.padding(.vertical, 4)
	}
}

private struct RecoveryCard: View {
	let flow: RecoveryFlow

	var body: some View {
		SurfaceCard(title: flow.title, subtitle: flow.summary) {
			VStack(alignment: .leading, spacing: 12) {
				ForEach(Array(flow.steps.enumerated()), id: \.offset) { index, step in
					HStack(alignment: .top, spacing: 12) {
						Text("\(index + 1)")
							.font(.caption.weight(.bold))
							.foregroundStyle(flow.tint)
							.frame(width: 24, height: 24)
							.background(flow.tint.opacity(0.12), in: Circle())
						Text(step)
							.font(.subheadline)
							.foregroundStyle(AppPalette.ink)
					}
				}

				if let note = flow.note {
					Text(note)
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.top, 4)
				}
			}
		}
	}
}

private struct RecoveryOrderRow: View {
	let index: String
	let title: String
	let detail: String

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			Text(index)
				.font(.caption.weight(.bold))
				.foregroundStyle(AppPalette.ocean)
				.frame(width: 24, height: 24)
				.background(AppPalette.ocean.opacity(0.12), in: Circle())
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(AppPalette.ink)
				Text(detail)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
	}
}

private struct StatusPill: View {
	let text: String
	let tint: Color

	var body: some View {
		Text(text)
			.font(.caption.weight(.semibold))
			.padding(.horizontal, 10)
			.padding(.vertical, 6)
			.background(tint.opacity(0.16), in: Capsule())
			.foregroundStyle(tint)
	}
}

private struct SurfaceCard<Content: View>: View {
	let title: String
	let subtitle: String?
	@ViewBuilder var content: Content

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
					.foregroundStyle(AppPalette.ink)
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
				.fill(.white.opacity(0.94))
				.shadow(color: AppPalette.ink.opacity(0.06), radius: 18, x: 0, y: 10)
		)
	}
}

private struct AppBackground: View {
	var body: some View {
		LinearGradient(
			colors: [Color.white, AppPalette.shell, AppPalette.fog],
			startPoint: .topLeading,
			endPoint: .bottomTrailing
		)
		.ignoresSafeArea()
	}
}
