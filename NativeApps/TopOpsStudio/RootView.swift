import PhotosUI
import SwiftUI

struct RootView: View {
	@StateObject private var store = StudioStore()

	var body: some View {
		TabView {
			NavigationStack {
				WorkbenchView(store: store)
			}
			.tabItem {
				Label("Workbench", systemImage: "square.grid.2x2.fill")
			}

			NavigationStack {
				EditorView(store: store)
			}
			.tabItem {
				Label("Editor", systemImage: "square.and.pencil")
			}

			NavigationStack {
				ReportsView(store: store)
			}
			.tabItem {
				Label("Reports", systemImage: "chart.bar.doc.horizontal")
			}

			NavigationStack {
				NativeLabView(store: store)
			}
			.tabItem {
				Label("Native AI", systemImage: "cpu.fill")
			}
		}
		.tint(StudioPalette.tide)
	}
}

private struct WorkbenchView: View {
	@ObservedObject var store: StudioStore

	private let columns = [
		GridItem(.flexible(), spacing: 14),
		GridItem(.flexible(), spacing: 14)
	]

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				HeroPanel()

				LazyVGrid(columns: columns, spacing: 14) {
					ForEach(store.folders) { folder in
						FrostCard(title: folder.kind.rawValue, subtitle: folder.kind.summary) {
							VStack(alignment: .leading, spacing: 10) {
								Label("\(folder.fileCount) item(s)", systemImage: folder.kind.symbol)
									.font(.subheadline.weight(.semibold))
									.foregroundStyle(StudioPalette.ink)
								Text(folder.url.lastPathComponent)
									.font(.footnote.monospaced())
									.foregroundStyle(StudioPalette.tide)
							}
						}
					}
				}

				FrostCard(title: "Quick Start", subtitle: "Vytvor startovni soubory a rychle si priprav workspace.") {
					VStack(alignment: .leading, spacing: 12) {
						ForEach(StarterTemplate.allCases) { template in
							Button {
								store.createStarterFile(template)
							} label: {
								HStack {
									Label(template.title, systemImage: template.symbol)
										.font(.subheadline.weight(.semibold))
									Spacer()
									Image(systemName: "plus.circle.fill")
								}
								.foregroundStyle(template.tint)
							}
						}
					}
				}

				FrostCard(title: "Native direction", subtitle: "MVP navrzeny jako Pythonista-like alternativa, ne kopie.") {
					VStack(alignment: .leading, spacing: 10) {
						ForEach(store.featureCards) { feature in
							HStack(alignment: .top, spacing: 12) {
								Image(systemName: feature.symbol)
									.font(.system(size: 16, weight: .bold))
									.foregroundStyle(feature.tint)
									.frame(width: 24)
								VStack(alignment: .leading, spacing: 3) {
									Text(feature.title)
										.font(.subheadline.weight(.semibold))
										.foregroundStyle(StudioPalette.ink)
									Text(feature.summary)
										.font(.footnote)
										.foregroundStyle(.secondary)
								}
							}
						}
					}
				}

				if let error = store.lastError {
					FrostCard(title: "Posledni chyba") {
						Text(error)
							.font(.footnote)
							.foregroundStyle(StudioPalette.coral)
					}
				}
			}
			.padding(20)
		}
		.background(StudioBackground())
		.navigationTitle("Workbench")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					store.refreshWorkspace()
				} label: {
					Image(systemName: "arrow.clockwise")
				}
			}
		}
	}
}

private struct EditorView: View {
	@ObservedObject var store: StudioStore

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				FrostCard(title: "Open file", subtitle: "Swift, Python, shell, plist, JSON a markdown soubory ze workspace.") {
					ScrollView(.horizontal, showsIndicators: false) {
						HStack(spacing: 10) {
							ForEach(store.documents) { document in
								Button {
									store.loadDocument(document)
								} label: {
									VStack(alignment: .leading, spacing: 6) {
										Label(document.title, systemImage: document.icon)
											.font(.caption.weight(.semibold))
										Text(document.relativePath)
											.font(.caption2.monospaced())
											.lineLimit(1)
									}
									.padding(12)
									.frame(width: 160, alignment: .leading)
									.background(
										RoundedRectangle(cornerRadius: 20, style: .continuous)
											.fill(store.selectedDocument == document ? StudioPalette.tide.opacity(0.16) : Color.white)
									)
								}
								.foregroundStyle(store.selectedDocument == document ? StudioPalette.tide : StudioPalette.ink)
							}
						}
					}
				}

				FrostCard(
					title: store.selectedDocument?.title ?? "No file selected",
					subtitle: store.selectedDocument?.relativePath ?? "Vyber soubor z Projects, Snippets, Reports nebo Imports."
				) {
					TextEditor(text: $store.editorText)
						.font(.system(.body, design: .monospaced))
						.foregroundStyle(StudioPalette.ink)
						.frame(minHeight: 360)
						.scrollContentBackground(.hidden)
						.padding(12)
						.background(
							RoundedRectangle(cornerRadius: 20, style: .continuous)
								.fill(StudioPalette.paper)
						)
				}
			}
			.padding(20)
		}
		.background(StudioBackground())
		.navigationTitle("Editor")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Save") {
					store.saveSelectedDocument()
				}
				.disabled(store.selectedDocument == nil)
			}
		}
	}
}

private struct ReportsView: View {
	@ObservedObject var store: StudioStore
	@State private var importerPresented = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				FrostCard(title: "Import reports", subtitle: "Vyber JSON nebo TXT soubory z Files nebo SMB a app je zkopiruje do Imports.") {
					VStack(alignment: .leading, spacing: 12) {
						Button {
							importerPresented = true
						} label: {
							Label("Import from Files", systemImage: "square.and.arrow.down")
								.font(.subheadline.weight(.semibold))
						}
						.tint(StudioPalette.tide)

						Button {
							store.refreshWorkspace()
						} label: {
							Label("Rescan workspace", systemImage: "arrow.clockwise")
								.font(.subheadline.weight(.semibold))
						}
						.tint(StudioPalette.mint)
					}
				}

				FrostCard(title: "Pythonista runtime", subtitle: "Nejnovejsi runtime-report-*.json v Reports slozce.") {
					if let report = store.runtimeReport {
						VStack(alignment: .leading, spacing: 10) {
							InfoRow(title: "Python", value: report.python_version)
							InfoRow(title: "Platform", value: report.platform)
							InfoRow(title: "Workspace", value: report.workspace_dir)
							InfoRow(title: "Pythonista modules", value: "\(report.pythonista_modules.filter(\.ok).count) healthy")
						}
					} else {
						EmptyState(text: "Zatim nebyl nalezen zadny runtime report.")
					}
				}

				FrostCard(title: "Bundled modules", subtitle: "Stav knihoven, ktere Pythonista realne poskytuje.") {
					VStack(alignment: .leading, spacing: 12) {
						InfoRow(title: "Healthy", value: "\(store.healthyModules.count)")
						InfoRow(title: "Needs attention", value: "\(store.brokenModules.count)")

						ForEach(store.brokenModules.prefix(5)) { module in
							HStack(alignment: .top, spacing: 10) {
								Image(systemName: "exclamationmark.triangle.fill")
									.foregroundStyle(StudioPalette.coral)
								VStack(alignment: .leading, spacing: 3) {
									Text(module.module)
										.font(.subheadline.weight(.semibold))
										.foregroundStyle(StudioPalette.ink)
									Text(module.error ?? "Unexpected module issue")
										.font(.footnote)
										.foregroundStyle(.secondary)
								}
							}
						}

						if store.brokenModules.isEmpty {
							EmptyState(text: "Nejsou videt zadne problemove moduly.")
						}
					}
				}
			}
			.padding(20)
		}
		.background(StudioBackground())
		.navigationTitle("Reports")
		.fileImporter(isPresented: $importerPresented, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
			switch result {
			case let .success(urls):
				store.importFiles(from: urls)
			case let .failure(error):
				store.lastError = error.localizedDescription
			}
		}
	}
}

private struct NativeLabView: View {
	@ObservedObject var store: StudioStore
	@State private var selectedPhotoItem: PhotosPickerItem?
	@State private var previewImage: Image?

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				FrostCard(title: "Vision OCR", subtitle: "Vyber screenshot z Photos a nech ho precist primo v telefonu.") {
					VStack(alignment: .leading, spacing: 14) {
						PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
							Label("Pick screenshot", systemImage: "photo.on.rectangle")
								.font(.subheadline.weight(.semibold))
						}

						if let previewImage {
							previewImage
								.resizable()
								.scaledToFit()
								.frame(maxHeight: 220)
								.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
						}

						Text(store.ocrText.isEmpty ? "OCR vysledek se objevi tady." : store.ocrText)
							.font(.footnote.monospaced())
							.foregroundStyle(store.ocrText.isEmpty ? .secondary : StudioPalette.ink)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(12)
							.background(
								RoundedRectangle(cornerRadius: 20, style: .continuous)
									.fill(StudioPalette.paper)
							)
					}
				}

				FrostCard(title: "Core ML inventory", subtitle: "Obsah slozky Models a rychly load check.") {
					VStack(alignment: .leading, spacing: 12) {
						ForEach(store.modelItems) { item in
							HStack(alignment: .top, spacing: 10) {
								Image(systemName: item.symbol)
									.foregroundStyle(item.tint)
									.frame(width: 24)
								VStack(alignment: .leading, spacing: 2) {
									Text(item.title)
										.font(.subheadline.weight(.semibold))
										.foregroundStyle(StudioPalette.ink)
									Text(item.status)
										.font(.caption.weight(.semibold))
										.foregroundStyle(item.tint)
									Text(item.detail)
										.font(.footnote)
										.foregroundStyle(.secondary)
								}
							}
						}
					}
				}

				FrostCard(title: "Export native guide", subtitle: "Vygeneruje markdown note do Exports slozky pro dalsi handoff.") {
					Button {
						store.createNativeOpsNote()
					} label: {
						Label("Create Native Ops Guide", systemImage: "doc.badge.plus")
							.font(.subheadline.weight(.semibold))
					}
					.tint(StudioPalette.amber)
				}
			}
			.padding(20)
		}
		.background(StudioBackground())
		.navigationTitle("Native AI")
		.task(id: selectedPhotoItem?.itemIdentifier) {
			guard let selectedPhotoItem, let data = try? await selectedPhotoItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) else {
				return
			}
			previewImage = Image(uiImage: uiImage)
			store.recognizeText(in: uiImage)
		}
	}
}

private struct HeroPanel: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 10) {
					Text("TopOps Studio")
						.font(.system(.footnote, design: .rounded).weight(.semibold))
						.foregroundStyle(.white.opacity(0.72))
						.textCase(.uppercase)
					Text("Native iPhone workbench pro soubory, reporty a on-device tooling")
						.font(.system(size: 28, weight: .bold, design: .rounded))
						.foregroundStyle(.white)
					Text("Files-first appka inspirovana Pythonista workflow, ale postavena ciste na Swiftu, Vision a Core ML.")
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.84))
				}
				Spacer(minLength: 12)
				VStack(spacing: 6) {
					Text("Mode")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.white.opacity(0.68))
					Text("Native")
						.font(.system(size: 24, weight: .bold, design: .rounded))
						.foregroundStyle(.white)
				}
				.padding(.horizontal, 14)
				.padding(.vertical, 12)
				.background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
			}

			HStack(spacing: 10) {
				PillLabel(text: "Files", tint: .white)
				PillLabel(text: "OCR", tint: .white)
				PillLabel(text: "Core ML", tint: .white)
				PillLabel(text: "SMB", tint: .white)
			}
		}
		.padding(22)
		.background(
			LinearGradient(
				colors: [StudioPalette.ink, StudioPalette.graphite, StudioPalette.tide],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			),
			in: RoundedRectangle(cornerRadius: 30, style: .continuous)
		)
	}
}

private struct InfoRow: View {
	let title: String
	let value: String

	var body: some View {
		VStack(alignment: .leading, spacing: 3) {
			Text(title)
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)
				.textCase(.uppercase)
			Text(value)
				.font(.subheadline)
				.foregroundStyle(StudioPalette.ink)
				.textSelection(.enabled)
		}
	}
}

private struct EmptyState: View {
	let text: String

	var body: some View {
		Text(text)
			.font(.footnote)
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(12)
			.background(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.fill(StudioPalette.paper)
			)
	}
}
