import FirebaseCore
import UIKit

/// Configura Firebase al lanzar la aplicación
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        /// Inicializa el SDK de Firebase con el GoogleService-Info.plist
        FirebaseApp.configure()
        return true
    }
}
