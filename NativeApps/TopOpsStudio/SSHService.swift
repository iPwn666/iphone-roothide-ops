import Foundation
import SSHClient

enum SSHServiceError: LocalizedError {
	case invalidPort
	case missingCredentials

	var errorDescription: String? {
		switch self {
		case .invalidPort:
			return "SSH port neni validni cislo."
		case .missingCredentials:
			return "Vypln SSH username a password."
		}
	}
}

enum SSHService {
	static func run(host: String, port: String, username: String, password: String, command: String) async throws -> String {
		guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
			  !password.isEmpty else {
			throw SSHServiceError.missingCredentials
		}

		guard let parsedPort = UInt16(port.trimmingCharacters(in: .whitespacesAndNewlines)) else {
			throw SSHServiceError.invalidPort
		}

		let connection = SSHConnection(
			host: host.trimmingCharacters(in: .whitespacesAndNewlines),
			port: parsedPort,
			authentication: SSHAuthentication(
				username: username.trimmingCharacters(in: .whitespacesAndNewlines),
				method: .password(.init(password)),
				hostKeyValidation: .acceptAll()
			)
		)

		try await start(connection)
		defer {
			Task {
				await cancel(connection)
			}
		}

		let response = try await execute(connection, command: command)
		let standard = response.standardOutput.flatMap { String(data: $0, encoding: .utf8) } ?? ""
		let error = response.errorOutput.flatMap { String(data: $0, encoding: .utf8) } ?? ""
		let combined = [standard, error].filter { !$0.isEmpty }.joined(separator: standard.isEmpty || error.isEmpty ? "" : "\n")
		return """
		$ \(command)
		exit: \(response.status.exitStatus)

		\(combined.isEmpty ? "(no output)" : combined)
		"""
	}

	private static func start(_ connection: SSHConnection) async throws {
		try await withCheckedThrowingContinuation { continuation in
			connection.start { result in
				continuation.resume(with: result)
			}
		}
	}

	private static func execute(_ connection: SSHConnection, command: String) async throws -> SSHCommandResponse {
		try await withCheckedThrowingContinuation { continuation in
			connection.execute(SSHCommand(command)) { result in
				continuation.resume(with: result)
			}
		}
	}

	private static func cancel(_ connection: SSHConnection) async {
		await withCheckedContinuation { continuation in
			connection.cancel {
				continuation.resume()
			}
		}
	}
}
