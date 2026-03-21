import UIKit

@main
final class TopOpsLensAppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		let window = UIWindow(frame: UIScreen.main.bounds)
		window.backgroundColor = .black
		window.rootViewController = RootViewController()
		window.makeKeyAndVisible()
		self.window = window
		return true
	}
}
