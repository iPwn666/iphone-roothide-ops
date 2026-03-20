import CoreML
import Foundation
import SwiftUI
import UIKit
import Vision

@MainActor
final class StudioStore: ObservableObject {
	@Published var folders: [WorkspaceFolder] = []
	@Published var documents: [StudioDocument] = []
	@Published var selectedDocument: StudioDocument?
	@Published var editorText = ""
	@Published var runtimeReport: RuntimeReport?
	@Published var bundledReport: BundledModulesReport?
	@Published var modelItems: [CoreMLInventoryItem] = []
	@Published var ocrText = ""
	@Published var lastError: String?

	static let textExtensions = Set(["swift", "py", "sh", "js", "json", "plist", "md", "txt", "yaml", "yml", "toml"])

	init() {
		refreshWorkspace()
	}

	static func documentsURL() -> URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	}

	static func url(for kind: WorkspaceFolderKind) -> URL {
		documentsURL().appendingPathComponent(kind.rawValue, isDirectory: true)
	}

	static func ensureWorkspace() {
		let manager = FileManager.default
		let documents = documentsURL()

		try? manager.createDirectory(at: documents, withIntermediateDirectories: true)
		WorkspaceFolderKind.allCases.forEach { folder in
			try? manager.createDirectory(at: url(for: folder), withIntermediateDirectories: true)
		}

		writeIfMissing(
			to: documents.appendingPathComponent("README.txt"),
			body: """
			TopOps Studio Documents

			Projects: zdrojaky a on-device prototypy
			Imports: soubory z Files, SMB nebo AirDropu
			Exports: vystupy pripravené ke sdileni
			Reports: JSON/TXT reporty z Pythonista workflow
			Models: Core ML modely pro inventory
			Snippets: rychle ukazky a shell helpery
			"""
		)

		writeIfMissing(
			to: url(for: .projects).appendingPathComponent("StarterUtility.swift"),
			body: """
			import Foundation

			struct DeviceSnapshot {
			    let name: String
			    let osVersion: String
			    let notes: [String]
			}

			let snapshot = DeviceSnapshot(
			    name: "iPhone XS",
			    osVersion: "iOS 16.3",
			    notes: ["Roothide ready", "WireGuard preferred", "Files + SMB friendly"]
			)

			print(snapshot)
			"""
		)

		writeIfMissing(
			to: url(for: .projects).appendingPathComponent("PythonBridge.py"),
			body: """
			import json
			from pathlib import Path

			root = Path.home() / "Documents"
			payload = {
			    "status": "ok",
			    "workspace": str(root),
			    "next": ["collect report", "copy to SMB", "review in TopOps Studio"],
			}

			print(json.dumps(payload, indent=2))
			"""
		)

		writeIfMissing(
			to: url(for: .snippets).appendingPathComponent("ssh_recover.sh"),
			body: """
			#!/bin/sh
			mkdir -p ~/.ssh
			chmod 700 ~/.ssh
			printf '%s\\n' 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
			chmod 600 ~/.ssh/authorized_keys
			echo 'SSH key installed'
			"""
		)

		writeIfMissing(
			to: url(for: .reports).appendingPathComponent("README.md"),
			body: """
			Drop sem JSON nebo TXT reporty z Pythonista workflow.
			App je automaticky naskenuje a vytahne runtime a bundled module stav.
			"""
		)

		writeIfMissing(
			to: url(for: .models).appendingPathComponent("README.md"),
			body: """
			Drop sem .mlmodel, .mlpackage nebo .mlmodelc.
			TopOps Studio zkusí model identifikovat a zobrazit metadata.
			"""
		)
	}

	func refreshWorkspace() {
		Self.ensureWorkspace()
		lastError = nil
		scanFolders()
		scanDocuments()
		loadReports()
		scanModels()
	}

	func createStarterFile(_ template: StarterTemplate) {
		let destination: URL
		let body: String
		let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")

		switch template {
		case .swiftUtility:
			destination = Self.url(for: .projects).appendingPathComponent("Utility-\(stamp).swift")
			body = """
			import Foundation

			func summarize(_ lines: [String]) -> String {
			    lines.joined(separator: " | ")
			}

			print(summarize(["TopOps", "Swift", "Native"]))
			"""
		case .pythonBridge:
			destination = Self.url(for: .projects).appendingPathComponent("Bridge-\(stamp).py")
			body = """
			import os
			print("HOME =", os.environ.get("HOME"))
			print("TMPDIR =", os.environ.get("TMPDIR"))
			"""
		case .shellHelper:
			destination = Self.url(for: .snippets).appendingPathComponent("Helper-\(stamp).sh")
			body = """
			#!/bin/sh
			echo 'WireGuard first, USB second.'
			"""
		case .note:
			destination = Self.url(for: .exports).appendingPathComponent("Ops-Note-\(stamp).md")
			body = """
			# TopOps Studio Note

			- Device state:
			- Next recovery step:
			- Files copied from SMB:
			"""
		}

		do {
			try body.write(to: destination, atomically: true, encoding: .utf8)
			refreshWorkspace()
			if Self.textExtensions.contains(destination.pathExtension.lowercased()) {
				let doc = StudioDocument(url: destination, relativePath: relativePath(for: destination), icon: iconName(for: destination))
				loadDocument(doc)
			}
		} catch {
			lastError = error.localizedDescription
		}
	}

	func loadDocument(_ document: StudioDocument) {
		selectedDocument = document
		do {
			editorText = try String(contentsOf: document.url, encoding: .utf8)
		} catch {
			editorText = ""
			lastError = "Soubor nejde otevrit: \(document.title)"
		}
	}

	func saveSelectedDocument() {
		guard let url = selectedDocument?.url else { return }
		do {
			try editorText.write(to: url, atomically: true, encoding: .utf8)
			refreshWorkspace()
		} catch {
			lastError = "Ulozeni selhalo: \(error.localizedDescription)"
		}
	}

	func importFiles(from urls: [URL]) {
		let manager = FileManager.default
		let importsURL = Self.url(for: .imports)

		for sourceURL in urls {
			let started = sourceURL.startAccessingSecurityScopedResource()
			defer {
				if started {
					sourceURL.stopAccessingSecurityScopedResource()
				}
			}

			var targetURL = importsURL.appendingPathComponent(sourceURL.lastPathComponent)
			if manager.fileExists(atPath: targetURL.path) {
				let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
				targetURL = importsURL.appendingPathComponent("\(sourceURL.deletingPathExtension().lastPathComponent)-\(stamp).\(sourceURL.pathExtension)")
			}

			do {
				try manager.copyItem(at: sourceURL, to: targetURL)
			} catch {
				lastError = "Import selhal pro \(sourceURL.lastPathComponent): \(error.localizedDescription)"
			}
		}

		refreshWorkspace()
	}

	func createNativeOpsNote() {
		let destination = Self.url(for: .exports).appendingPathComponent("Native-Ops-Guide.md")
		let body = """
		# Native Ops Guide

		## Vision
		- pouzij screenshot z PhotosPicker
		- OCR běží přímo na zařízení

		## Core ML
		- dropni .mlmodel nebo .mlpackage do slozky Models
		- app zkusí metadata a stav modelu zobrazit bez shellu

		## Files
		- Imports a Exports jsou viditelne v aplikaci Soubory
		- pres SMB pouzij share iPhoneDrop nebo OpsRepo
		"""

		do {
			try body.write(to: destination, atomically: true, encoding: .utf8)
			refreshWorkspace()
		} catch {
			lastError = "Nepodarilo se vytvorit guide: \(error.localizedDescription)"
		}
	}

	func recognizeText(in image: UIImage) {
		guard let cgImage = image.cgImage else {
			lastError = "Obrazek nejde analyzovat."
			return
		}

		ocrText = "Analyzuji..."
		let request = VNRecognizeTextRequest { [weak self] request, error in
			Task { @MainActor in
				if let error {
					self?.lastError = error.localizedDescription
					self?.ocrText = ""
					return
				}

				let lines = (request.results as? [VNRecognizedTextObservation])?
					.compactMap { $0.topCandidates(1).first?.string }
					.filter { !$0.isEmpty } ?? []
				self?.ocrText = lines.joined(separator: "\n")
			}
		}
		request.recognitionLevel = .accurate
		request.usesLanguageCorrection = true

		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
				try handler.perform([request])
			} catch {
				Task { @MainActor in
					self.lastError = error.localizedDescription
					self.ocrText = ""
				}
			}
		}
	}

	var featureCards: [NativeFeatureCard] {
		[
			NativeFeatureCard(
				title: "Files-first workflow",
				summary: "Workspace lezi v Documents a je viditelny v aplikaci Soubory i pres SMB import.",
				symbol: "folder.fill.badge.gearshape",
				tint: StudioPalette.tide
			),
			NativeFeatureCard(
				title: "Vision OCR",
				summary: "Screenshot z Photos nebo soubor z Files lze precist bez Pythonista bridge.",
				symbol: "text.viewfinder",
				tint: StudioPalette.mint
			),
			NativeFeatureCard(
				title: "Core ML inventory",
				summary: "Models slozka umi rychle ukazat, jestli je model nacitatelny a co exposeuje.",
				symbol: "cpu.fill",
				tint: StudioPalette.amber
			),
			NativeFeatureCard(
				title: "On-device editing",
				summary: "Textovy editor drzi Swift, Python, shell, plist i markdown bez dalsi appky.",
				symbol: "square.and.pencil",
				tint: StudioPalette.coral
			)
		]
	}

	var brokenModules: [BundledModuleStatus] {
		bundledReport?.bundled_modules.filter { !$0.ok || $0.error != nil } ?? []
	}

	var healthyModules: [BundledModuleStatus] {
		bundledReport?.bundled_modules.filter { $0.ok && $0.error == nil } ?? []
	}

	private func scanFolders() {
		let manager = FileManager.default
		folders = WorkspaceFolderKind.allCases.map { kind in
			let url = Self.url(for: kind)
			let count = (try? manager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).count) ?? 0
			return WorkspaceFolder(kind: kind, url: url, fileCount: count)
		}
	}

	private func scanDocuments() {
		let manager = FileManager.default
		var collected: [StudioDocument] = []

		for kind in WorkspaceFolderKind.allCases {
			let base = Self.url(for: kind)
			guard let enumerator = manager.enumerator(at: base, includingPropertiesForKeys: [.isRegularFileKey]) else {
				continue
			}

			for case let url as URL in enumerator {
				let ext = url.pathExtension.lowercased()
				guard Self.textExtensions.contains(ext) else { continue }
				collected.append(StudioDocument(url: url, relativePath: relativePath(for: url), icon: iconName(for: url)))
			}
		}

		documents = collected.sorted { $0.relativePath < $1.relativePath }
		if selectedDocument == nil, let first = documents.first {
			loadDocument(first)
		} else if let selectedDocument, !documents.contains(selectedDocument) {
			self.selectedDocument = nil
			editorText = ""
		}
	}

	private func loadReports() {
		runtimeReport = decodeLatest(RuntimeReport.self, matching: "runtime-report-*.json")
		bundledReport = decodeLatest(BundledModulesReport.self, matching: "bundled-modules-*.json")
	}

	private func scanModels() {
		let manager = FileManager.default
		let modelFolder = Self.url(for: .models)
		let items = (try? manager.contentsOfDirectory(at: modelFolder, includingPropertiesForKeys: nil)) ?? []
		var inventory: [CoreMLInventoryItem] = []

		for url in items where !url.hasDirectoryPath {
			let ext = url.pathExtension.lowercased()
			guard ["mlmodel", "mlmodelc", "mlpackage"].contains(ext) else { continue }

			do {
				let resolvedURL: URL
				let status: String
				if ext == "mlmodelc" {
					resolvedURL = url
					status = "Ready"
				} else {
					resolvedURL = try MLModel.compileModel(at: url)
					status = "Compiled"
				}
				let model = try MLModel(contentsOf: resolvedURL)
				let inputCount = model.modelDescription.inputDescriptionsByName.count
				let outputCount = model.modelDescription.outputDescriptionsByName.count
				inventory.append(
					CoreMLInventoryItem(
						title: url.lastPathComponent,
						detail: "\(inputCount) input / \(outputCount) output",
						status: status,
						symbol: "cpu.fill",
						tint: StudioPalette.mint
					)
				)
			} catch {
				inventory.append(
					CoreMLInventoryItem(
						title: url.lastPathComponent,
						detail: error.localizedDescription,
						status: "Needs attention",
						symbol: "exclamationmark.triangle.fill",
						tint: StudioPalette.coral
					)
				)
			}
		}

		if inventory.isEmpty {
			inventory = [
				CoreMLInventoryItem(
					title: "No models yet",
					detail: "Drop .mlmodel, .mlpackage nebo .mlmodelc do slozky Models.",
					status: "Waiting",
					symbol: "tray.fill",
					tint: StudioPalette.tide
				)
			]
		}

		modelItems = inventory.sorted { $0.title < $1.title }
	}

	private func decodeLatest<T: Decodable>(_ type: T.Type, matching pattern: String) -> T? {
		let manager = FileManager.default
		let reports = Self.url(for: .reports)
		guard let contents = try? manager.contentsOfDirectory(at: reports, includingPropertiesForKeys: [.contentModificationDateKey]) else {
			return nil
		}

		let candidates = contents.filter { url in
			let name = url.lastPathComponent
			if pattern.hasPrefix("runtime-report-") {
				return name.hasPrefix("runtime-report-") && name.hasSuffix(".json")
			}
			return name.hasPrefix("bundled-modules-") && name.hasSuffix(".json")
		}

		guard let latest = candidates.max(by: {
			let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
			let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
			return lhs < rhs
		}), let data = try? Data(contentsOf: latest) else {
			return nil
		}

		return try? JSONDecoder().decode(type, from: data)
	}

	private static func writeIfMissing(to url: URL, body: String) {
		guard !FileManager.default.fileExists(atPath: url.path) else { return }
		try? body.write(to: url, atomically: true, encoding: .utf8)
	}

	private func relativePath(for url: URL) -> String {
		url.path.replacingOccurrences(of: Self.documentsURL().path + "/", with: "")
	}

	private func iconName(for url: URL) -> String {
		switch url.pathExtension.lowercased() {
		case "swift":
			return "swift"
		case "py":
			return "terminal"
		case "sh":
			return "apple.terminal"
		case "plist", "json", "toml", "yaml", "yml":
			return "slider.horizontal.3"
		case "md", "txt":
			return "doc.text"
		default:
			return "doc.plaintext"
		}
	}
}
