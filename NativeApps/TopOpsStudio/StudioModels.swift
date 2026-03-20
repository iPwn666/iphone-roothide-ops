import Foundation
import SwiftUI

enum WorkspaceFolderKind: String, CaseIterable, Identifiable {
	case projects = "Projects"
	case imports = "Imports"
	case exports = "Exports"
	case reports = "Reports"
	case models = "Models"
	case snippets = "Snippets"

	var id: String { rawValue }

	var summary: String {
		switch self {
		case .projects:
			return "Zdrojaky a male on-device projekty."
		case .imports:
			return "Soubory z Files, SMB nebo AirDropu."
		case .exports:
			return "Vystupy pripravené ke sdileni."
		case .reports:
			return "JSON a TXT reporty z Pythonista workflow."
		case .models:
			return "Core ML modely pro inventory a test import."
		case .snippets:
			return "Rychle ukazky, shell helpery a poznámky."
		}
	}

	var symbol: String {
		switch self {
		case .projects:
			return "folder.badge.gearshape"
		case .imports:
			return "square.and.arrow.down"
		case .exports:
			return "square.and.arrow.up"
		case .reports:
			return "chart.bar.doc.horizontal"
		case .models:
			return "cpu"
		case .snippets:
			return "curlybraces"
		}
	}
}

struct WorkspaceFolder: Identifiable {
	let kind: WorkspaceFolderKind
	let url: URL
	let fileCount: Int
	var id: String { kind.id }
}

struct StudioDocument: Identifiable, Hashable {
	let url: URL
	let relativePath: String
	let icon: String
	var id: URL { url }
	var title: String { url.lastPathComponent }
}

enum StarterTemplate: String, CaseIterable, Identifiable {
	case swiftUtility
	case pythonBridge
	case shellHelper
	case note

	var id: String { rawValue }

	var title: String {
		switch self {
		case .swiftUtility:
			return "Swift Utility"
		case .pythonBridge:
			return "Python Bridge"
		case .shellHelper:
			return "Shell Helper"
		case .note:
			return "Ops Note"
		}
	}

	var symbol: String {
		switch self {
		case .swiftUtility:
			return "swift"
		case .pythonBridge:
			return "terminal"
		case .shellHelper:
			return "apple.terminal"
		case .note:
			return "doc.text"
		}
	}

	var tint: Color {
		switch self {
		case .swiftUtility:
			return StudioPalette.amber
		case .pythonBridge:
			return StudioPalette.tide
		case .shellHelper:
			return StudioPalette.coral
		case .note:
			return StudioPalette.mint
		}
	}
}

struct NativeFeatureCard: Identifiable {
	let title: String
	let summary: String
	let symbol: String
	let tint: Color
	let id = UUID()
}

struct PythonistaModule: Decodable, Identifiable {
	let module: String
	let ok: Bool
	let file: String?
	let version: String?

	var id: String { module }
}

struct RuntimeReport: Decodable {
	let timestamp: String
	let python_version: String
	let executable: String
	let platform: String
	let machine: String
	let system: String
	let release: String
	let cwd: String
	let toolkit_dir: String
	let workspace_dir: String
	let vendor_dir: String
	let home: String
	let sys_path: [String]
	let pythonista_modules: [PythonistaModule]
}

struct BundledModuleStatus: Decodable, Identifiable {
	let module: String
	let ok: Bool
	let file: String?
	let version: String?
	let error: String?

	var id: String { module }
}

struct BundledModulesReport: Decodable {
	let bundled_modules: [BundledModuleStatus]
}

struct CoreMLInventoryItem: Identifiable {
	let title: String
	let detail: String
	let status: String
	let symbol: String
	let tint: Color
	var id: String { title + status }
}
