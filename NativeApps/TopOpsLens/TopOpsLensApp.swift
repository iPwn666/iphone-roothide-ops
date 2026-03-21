import SwiftUI
import UIKit

@main
final class TopOpsLensAppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		let window = UIWindow(frame: UIScreen.main.bounds)
		window.backgroundColor = UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)
		window.rootViewController = UIHostingController(rootView: RootView())
		window.makeKeyAndVisible()
		self.window = window
		return true
	}
}
