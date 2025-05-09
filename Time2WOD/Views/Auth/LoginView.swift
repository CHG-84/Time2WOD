import SwiftUI

/// Vista de Login con diagnósticos
struct LoginView: View {
    @EnvironmentObject var authVM: AutenticacionViewModel

    @State private var email = ""
    @State private var contrasena = ""
    @State private var mostrandoRegistro = false
    @State private var mostrarDebug = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Time2WOD")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Form {
                    Section("Correo") {
                        TextField("tu@correo.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    Section("Contraseña") {
                        SecureField("••••••••", text: $contrasena)
                    }
                    
                    // Mostrar errores
                    if let error = authVM.mensajeError {
                        Section("Error") {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    // Debug info (solo en desarrollo)
                    if !authVM.debugInfo.isEmpty {
                        Section("Estado de Firebase") {
                            Button(mostrarDebug ? "Ocultar Debug" : "Mostrar Debug") {
                                mostrarDebug.toggle()
                            }
                            
                            if mostrarDebug {
                                Text(authVM.debugInfo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                Button(authVM.estaCargando ? "Entrando..." : "Entrar") {
                    Task {
                        await authVM.iniciarSesion(
                            email: email,
                            contrasena: contrasena
                        )
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    !email.isEmpty && !contrasena.isEmpty && !authVM.estaCargando
                        ? Color.blue : Color.gray
                )
                .cornerRadius(8)
                .disabled(email.isEmpty || contrasena.isEmpty || authVM.estaCargando)
                .padding(.horizontal)

                Button("¿No tienes cuenta? Regístrate") {
                    mostrandoRegistro = true
                }
                .padding(.top)

                Spacer()
            }
            .navigationTitle("Iniciar Sesión")
            .sheet(isPresented: $mostrandoRegistro) {
                RegistroView()
                    .environmentObject(authVM)
            }
        }
    }
}
