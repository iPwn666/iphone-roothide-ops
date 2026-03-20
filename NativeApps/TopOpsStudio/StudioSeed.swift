import Foundation

struct StudioSeed: Decodable {
	let smbHost: String?
	let lanHost: String?
	let wireGuardHost: String?
	let usbForwardPort: String?
	let sshUsername: String?
	let sshPassword: String?
	let sshPort: String?
	let sshCustomCommand: String?
	let openAIModel: String?
	let notes: String?
}
