import UIKit
import SwiftUI

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		prepareDocumentsWorkspace()

		let window = UIWindow(frame: UIScreen.main.bounds)
		window.backgroundColor = .systemBackground
		window.rootViewController = UIHostingController(rootView: RootView())
		window.makeKeyAndVisible()
		self.window = window
		return true
	}

	private func prepareDocumentsWorkspace() {
		let fileManager = FileManager.default
		guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return
		}

		["Exports", "Imports", "Logs", "Scripts"].forEach { folder in
			let folderURL = documentsURL.appendingPathComponent(folder, isDirectory: true)
			try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
		}

		let readmeURL = documentsURL.appendingPathComponent("README.txt")
		if !fileManager.fileExists(atPath: readmeURL.path) {
			let body = """
			Roothide Ops Documents

			Tato slozka je primo viditelna v aplikaci Soubory.
			Doporuceny workflow:
			- Imports: sem kopiruj soubory z Mac/Linux hostu nebo z SMB share
			- Exports: odtud sdilej logy, plisty a archivovane vystupy
			- Logs: ukladej sem provozni vystupy a diagnostiku
			- Scripts: nouzove shell nebo Python helpery pro telefon
			"""
			try? body.write(to: readmeURL, atomically: true, encoding: .utf8)
		}
	}
}
