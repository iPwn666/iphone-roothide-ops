import SwiftUI
import UIKit

@main
final class TopOpsStudioAppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		StudioStore.ensureWorkspace()

		let window = UIWindow(frame: UIScreen.main.bounds)
		window.backgroundColor = .systemBackground
		window.rootViewController = UIHostingController(rootView: RootView())
		window.makeKeyAndVisible()
		self.window = window
		return true
	}
}
