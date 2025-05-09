import SwiftUI

struct RegistroView: View {
    @EnvironmentObject var authVM: AutenticacionViewModel
    @Environment(\.dismiss) private var cerrar

    @State private var email = ""
    @State private var contrasena = ""
    @State private var confirmarContrasena = ""
    @State private var mostrarDebug = false

    var contrasenasCoinciden: Bool {
        !contrasena.isEmpty && contrasena == confirmarContrasena
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Crear cuenta")
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
                        SecureField("••••••", text: $contrasena)
                        SecureField(
                            "Repite contraseña",
                            text: $confirmarContrasena
                        )
                        if !confirmarContrasena.isEmpty && !contrasenasCoinciden
                        {
                            Text("No coinciden").foregroundColor(.red).font(
                                .caption
                            )
                        }
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
                        Section("Debug Info") {
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

                Button(authVM.estaCargando ? "Registrando..." : "Registrarme") {
                    Task {
                        guard contrasenasCoinciden else {
                            authVM.mensajeError = "Las contraseñas no coinciden"
                            return
                        }

                        await authVM.registrarse(
                            email: email,
                            contrasena: contrasena
                        )
                        
                        // Si el registro fue exitoso, cerrar
                        if authVM.usuario != nil {
                            cerrar()
                        }
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    contrasenasCoinciden && !email.isEmpty && !authVM.estaCargando
                        ? Color.blue : Color.gray
                )
                .cornerRadius(8)
                .disabled(email.isEmpty || !contrasenasCoinciden || authVM.estaCargando)
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        cerrar()
                    }
                }
            }
        }
    }
}
