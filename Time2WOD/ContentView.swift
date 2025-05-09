import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AutenticacionViewModel
    @EnvironmentObject var historialVM: HistorialViewModel
    @State private var pestanaSeleccionada = 0

    var body: some View {
        Group {
            if authVM.usuario != nil {
                TabView(selection: $pestanaSeleccionada) {
                    WODView()
                        .tabItem {
                            Label("WOD", systemImage: "dumbbell.fill")
                        }
                        .tag(0)

                    WODManualView()
                        .tabItem {
                            Label("WOD Manual", systemImage: "pencil")
                        }
                        .tag(1)

                    TemporizadoresView()
                        .tabItem {
                            Label("Temporizadores", systemImage: "timer")
                        }
                        .tag(2)

                    PerfilView()
                        .tabItem {
                            Label("Perfil", systemImage: "person.fill")
                        }
                        .tag(3)
                        .environmentObject(historialVM)
                }
                .accentColor(.red)
                .task {
                    // Cargar historial cuando se inicia sesión
                    if authVM.inicioSesion {
                        await historialVM.cargarHistorial()
                        authVM.inicioSesion = false
                    }
                }
            } else {
                LoginView()
            }
        }
    }
}
