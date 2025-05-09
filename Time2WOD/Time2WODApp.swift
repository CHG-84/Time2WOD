import SwiftUI

@main
struct Time2WODApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var perfilViewModel = PerfilViewModel()
    @StateObject private var authViewModel = AutenticacionViewModel()
    @StateObject private var historialViewModel = HistorialViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(perfilViewModel)
                .environmentObject(authViewModel)
                .environmentObject(historialViewModel)
        }
    }
}
