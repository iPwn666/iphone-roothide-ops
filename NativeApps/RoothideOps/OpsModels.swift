import Foundation
import SwiftUI

struct OpsMetric: Identifiable {
	let id = UUID()
	let title: String
	let value: String
	let detail: String
	let symbol: String
	let tint: Color
}

struct OpsSection: Identifiable {
	let id = UUID()
	let title: String
	let body: String
	let bullets: [String]
}

struct OpsArticle: Identifiable {
	let id = UUID()
	let title: String
	let summary: String
	let symbol: String
	let tint: Color
	let sections: [OpsSection]
}

struct RecoveryFlow: Identifiable {
	let id = UUID()
	let title: String
	let summary: String
	let symbol: String
	let tint: Color
	let steps: [String]
	let note: String?
}

struct ToolkitItem: Identifiable {
	let id = UUID()
	let title: String
	let summary: String
	let symbol: String
	let location: String
	let category: String
}
