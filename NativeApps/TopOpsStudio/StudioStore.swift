import CoreML
import Foundation
import SwiftUI
import UIKit
import Vision
import CoreFoundation

@MainActor
final class StudioStore: ObservableObject {
	private enum DefaultsKey {
		static let smbHost = "TopOpsStudio.smbHost"
		static let lanHost = "TopOpsStudio.lanHost"
		static let wireGuardHost = "TopOpsStudio.wireGuardHost"
		static let usbForwardPort = "TopOpsStudio.usbForwardPort"
		static let sshUsername = "TopOpsStudio.sshUsername"
		static let sshPort = "TopOpsStudio.sshPort"
		static let sshCustomCommand = "TopOpsStudio.sshCustomCommand"
	}

	@Published var folders: [WorkspaceFolder] = []
	@Published var documents: [StudioDocument] = []
	@Published var workspaceFiles: [WorkspaceItem] = []
	@Published var selectedFile: WorkspaceItem?
	@Published var editorText = ""
	@Published var runtimeReport: RuntimeReport?
	@Published var bundledReport: BundledModulesReport?
	@Published var modelItems: [CoreMLInventoryItem] = []
	@Published var ocrText = ""
	@Published var plistFields: [PlistField] = []
	@Published var lastError: String?
	@Published var smbHost: String
	@Published var lanHost: String
	@Published var wireGuardHost: String
	@Published var usbForwardPort: String
	@Published var sshUsername: String
	@Published var sshPort: String
	@Published var sshPassword: String
	@Published var sshCustomCommand: String
	@Published var sshOutput = ""
	@Published var sshBusy = false

	private var loadedPlistObject: [String: Any]?

	static let textExtensions = Set(["swift", "py", "sh", "js", "json", "plist", "md", "txt", "yaml", "yml", "toml"])

	init() {
		let defaults = UserDefaults.standard
		self.smbHost = defaults.string(forKey: DefaultsKey.smbHost) ?? "iPwnZu.local"
		self.lanHost = defaults.string(forKey: DefaultsKey.lanHost) ?? "192.168.50.42"
		self.wireGuardHost = defaults.string(forKey: DefaultsKey.wireGuardHost) ?? "10.77.0.2"
		self.usbForwardPort = defaults.string(forKey: DefaultsKey.usbForwardPort) ?? "2222"
		self.sshUsername = defaults.string(forKey: DefaultsKey.sshUsername) ?? "mobile"
		self.sshPort = defaults.string(forKey: DefaultsKey.sshPort) ?? "22"
		self.sshCustomCommand = defaults.string(forKey: DefaultsKey.sshCustomCommand) ?? "uname -a"
		self.sshPassword = KeychainStore.load(account: "sshPassword")
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
		scanFiles()
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
				let item = WorkspaceItem(
					url: destination,
					relativePath: relativePath(for: destination),
					folderName: destination.deletingLastPathComponent().lastPathComponent,
					icon: iconName(for: destination),
					fileSize: Int64((try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0),
					modifiedAt: try? destination.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
					isEditableText: true,
					isPlist: destination.pathExtension.lowercased() == "plist"
				)
				loadFile(item)
			}
		} catch {
			lastError = error.localizedDescription
		}
	}

	func loadFile(_ file: WorkspaceItem) {
		selectedFile = file
		loadedPlistObject = nil
		plistFields = []

		if file.isPlist {
			loadPlistFile(file)
			return
		}

		guard file.isEditableText else {
			editorText = ""
			return
		}

		do {
			editorText = try String(contentsOf: file.url, encoding: .utf8)
		} catch {
			editorText = ""
			lastError = "Soubor nejde otevrit: \(file.title)"
		}
	}

	func saveSelectedFile() {
		guard let file = selectedFile else { return }
		if file.isPlist {
			saveSelectedPlist()
			return
		}

		do {
			try editorText.write(to: file.url, atomically: true, encoding: .utf8)
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

	var connectionProfiles: [ConnectionProfile] {
		[
			ConnectionProfile(
				title: "SSH",
				summary: "Preferovane endpointy pro root a mobile pristup.",
				symbol: "point.3.connected.trianglepath.dotted",
				tint: StudioPalette.tide,
				endpoints: [
					ConnectionEndpoint(label: "WireGuard root", value: "ssh root@\(wireGuardHost)", note: "Primarni vzdaleny pristup."),
					ConnectionEndpoint(label: "WireGuard mobile", value: "ssh mobile@\(wireGuardHost)", note: "Bezpecnejsi vychozi shell."),
					ConnectionEndpoint(label: "USB root", value: "ssh -p \(usbForwardPort) root@127.0.0.1", note: "Kdyz Wi-Fi nebo WG spadne."),
					ConnectionEndpoint(label: "USB mobile", value: "ssh -p \(usbForwardPort) mobile@127.0.0.1", note: "Rychly local recovery fallback.")
				]
			),
			ConnectionProfile(
				title: "SMB",
				summary: "Files-friendly handoff bez dalsi appky.",
				symbol: "externaldrive.connected.to.line.below.fill",
				tint: StudioPalette.mint,
				endpoints: [
					ConnectionEndpoint(label: "Bonjour", value: "smb://\(smbHost)/iPhoneDrop", note: "Nejpohodlnejsi varianta v aplikaci Soubory."),
					ConnectionEndpoint(label: "LAN", value: "smb://\(lanHost)/iPhoneDrop", note: "Kdyz mDNS zrovna nedrzi."),
					ConnectionEndpoint(label: "WireGuard", value: "smb://10.77.0.1/iPhoneDrop", note: "Pro mobilni data pres tunel.")
				]
			),
			ConnectionProfile(
				title: "System paths",
				summary: "Nejcastejsi cesty pro Filzu, SSH a recovery workflow.",
				symbol: "folder.badge.gearshape",
				tint: StudioPalette.amber,
				endpoints: [
					ConnectionEndpoint(label: "JB root", value: "/var/jb", note: "Bootstrap a tweak vrstva."),
					ConnectionEndpoint(label: "root home", value: "/var/root", note: "Root shell a .ssh/.gnupg."),
					ConnectionEndpoint(label: "mobile docs", value: "/private/var/mobile/Documents", note: "Soubory, exporty a import queue.")
				]
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

	private func scanFiles() {
		let manager = FileManager.default
		var collected: [WorkspaceItem] = []

		for kind in WorkspaceFolderKind.allCases {
			let base = Self.url(for: kind)
			guard let enumerator = manager.enumerator(at: base, includingPropertiesForKeys: [.isRegularFileKey]) else {
				continue
			}

			for case let url as URL in enumerator {
				let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
				guard values?.isRegularFile == true else { continue }
				let ext = url.pathExtension.lowercased()
				collected.append(
					WorkspaceItem(
						url: url,
						relativePath: relativePath(for: url),
						folderName: kind.rawValue,
						icon: iconName(for: url),
						fileSize: Int64(values?.fileSize ?? 0),
						modifiedAt: values?.contentModificationDate,
						isEditableText: Self.textExtensions.contains(ext),
						isPlist: ext == "plist"
					)
				)
			}
		}

		workspaceFiles = collected.sorted { $0.relativePath < $1.relativePath }
		documents = workspaceFiles
			.filter { $0.isEditableText }
			.map { StudioDocument(url: $0.url, relativePath: $0.relativePath, icon: $0.icon) }

		if selectedFile == nil, let first = workspaceFiles.first(where: { $0.isEditableText }) {
			loadFile(first)
		} else if let selectedFile, !workspaceFiles.contains(selectedFile) {
			self.selectedFile = nil
			editorText = ""
			plistFields = []
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

	private func loadPlistFile(_ file: WorkspaceItem) {
		do {
			let data = try Data(contentsOf: file.url)
			let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

			guard let dictionary = object as? [String: Any] else {
				editorText = ""
				plistFields = []
				loadedPlistObject = nil
				lastError = "Plist inspector zatim podporuje jen top-level dictionary."
				return
			}

			loadedPlistObject = dictionary
			plistFields = dictionary.keys.sorted().map { key in
				let value = dictionary[key] as Any
				return field(for: key, value: value)
			}

			if let xmlData = try? PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0),
			   let xml = String(data: xmlData, encoding: .utf8) {
				editorText = xml
			} else {
				editorText = ""
			}
		} catch {
			loadedPlistObject = nil
			plistFields = []
			editorText = ""
			lastError = "Plist nejde nacist: \(error.localizedDescription)"
		}
	}

	private func field(for key: String, value: Any) -> PlistField {
		switch value {
		case let value as String:
			return PlistField(key: key, valueText: value, kind: .string, isEditable: true)
		case let value as NSNumber:
			if CFGetTypeID(value) == CFBooleanGetTypeID() {
				return PlistField(key: key, valueText: value.boolValue ? "true" : "false", kind: .bool, isEditable: true)
			}
			if value.doubleValue.rounded() == value.doubleValue {
				return PlistField(key: key, valueText: String(value.intValue), kind: .integer, isEditable: true)
			}
			return PlistField(key: key, valueText: String(value.doubleValue), kind: .double, isEditable: true)
		case let value as Date:
			return PlistField(
				key: key,
				valueText: ISO8601DateFormatter().string(from: value),
				kind: .date,
				isEditable: true
			)
		case let value as [Any]:
			return PlistField(key: key, valueText: "Array (\(value.count) items)", kind: .array, isEditable: false)
		case let value as [String: Any]:
			return PlistField(key: key, valueText: "Dictionary (\(value.count) keys)", kind: .dictionary, isEditable: false)
		case let value as Data:
			return PlistField(key: key, valueText: "Data (\(value.count) bytes)", kind: .data, isEditable: false)
		default:
			return PlistField(key: key, valueText: String(describing: value), kind: .unknown, isEditable: false)
		}
	}

	func updatePlistField(_ field: PlistField, value: String) {
		guard let index = plistFields.firstIndex(where: { $0.id == field.id }) else { return }
		plistFields[index].valueText = value
	}

	func persistConnectionSettings() {
		let defaults = UserDefaults.standard
		defaults.set(smbHost, forKey: DefaultsKey.smbHost)
		defaults.set(lanHost, forKey: DefaultsKey.lanHost)
		defaults.set(wireGuardHost, forKey: DefaultsKey.wireGuardHost)
		defaults.set(usbForwardPort, forKey: DefaultsKey.usbForwardPort)
		defaults.set(sshUsername, forKey: DefaultsKey.sshUsername)
		defaults.set(sshPort, forKey: DefaultsKey.sshPort)
		defaults.set(sshCustomCommand, forKey: DefaultsKey.sshCustomCommand)
		KeychainStore.save(sshPassword, account: "sshPassword")
	}

	func copyToClipboard(_ value: String) {
		UIPasteboard.general.string = value
	}

	func exportConnectionPack() {
		let destination = Self.url(for: .exports).appendingPathComponent("Connection-Pack.md")
		let body = """
		# TopOps Studio Connection Pack

		## SSH
		- root via WireGuard: `ssh root@\(wireGuardHost)`
		- mobile via WireGuard: `ssh mobile@\(wireGuardHost)`
		- root via USB: `ssh -p \(usbForwardPort) root@127.0.0.1`
		- mobile via USB: `ssh -p \(usbForwardPort) mobile@127.0.0.1`

		## SMB
		- Bonjour: `smb://\(smbHost)/iPhoneDrop`
		- LAN: `smb://\(lanHost)/iPhoneDrop`
		- WireGuard: `smb://10.77.0.1/iPhoneDrop`

		## Paths
		- `/var/jb`
		- `/var/root`
		- `/private/var/mobile/Documents`
		"""

		do {
			try body.write(to: destination, atomically: true, encoding: .utf8)
			refreshWorkspace()
		} catch {
			lastError = "Export connection packu selhal: \(error.localizedDescription)"
		}
	}

	func runSSHCommand(_ command: String) {
		let actualCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !actualCommand.isEmpty else { return }
		persistConnectionSettings()
		sshBusy = true
		sshOutput = "Connecting to \(wireGuardHost):\(sshPort)..."

		Task {
			do {
				let output = try await SSHService.run(
					host: wireGuardHost,
					port: sshPort,
					username: sshUsername,
					password: sshPassword,
					command: actualCommand
				)
				await MainActor.run {
					self.sshOutput = output
					self.sshBusy = false
				}
			} catch {
				await MainActor.run {
					self.sshOutput = "Command failed\n\n\(error.localizedDescription)"
					self.sshBusy = false
					self.lastError = error.localizedDescription
				}
			}
		}
	}

	private func saveSelectedPlist() {
		guard let file = selectedFile, var dictionary = loadedPlistObject else {
			lastError = "Neni nacteny zadny plist."
			return
		}

		for field in plistFields {
			guard field.isEditable else { continue }
			switch field.kind {
			case .string:
				dictionary[field.key] = field.valueText
			case .integer:
				guard let value = Int(field.valueText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
					lastError = "Klic \(field.key) ocekava integer."
					return
				}
				dictionary[field.key] = value
			case .double:
				guard let value = Double(field.valueText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
					lastError = "Klic \(field.key) ocekava decimal."
					return
				}
				dictionary[field.key] = value
			case .bool:
				let normalized = field.valueText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
				guard ["true", "false", "1", "0", "yes", "no"].contains(normalized) else {
					lastError = "Klic \(field.key) ocekava bool."
					return
				}
				dictionary[field.key] = ["true", "1", "yes"].contains(normalized)
			case .date:
				let formatter = ISO8601DateFormatter()
				guard let value = formatter.date(from: field.valueText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
					lastError = "Klic \(field.key) ocekava ISO8601 datum."
					return
				}
				dictionary[field.key] = value
			case .array, .dictionary, .data, .unknown:
				break
			}
		}

		do {
			let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
			try data.write(to: file.url, options: .atomic)
			loadedPlistObject = dictionary
			editorText = String(data: data, encoding: .utf8) ?? ""
			refreshWorkspace()
			if let refreshed = workspaceFiles.first(where: { $0.url == file.url }) {
				loadFile(refreshed)
			}
		} catch {
			lastError = "Plist nejde ulozit: \(error.localizedDescription)"
		}
	}
}
