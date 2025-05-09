import FirebaseAuth
import Foundation

@MainActor
class AutenticacionViewModel: ObservableObject {
    @Published var usuario: FirebaseAuth.User? = nil
    @Published var estaCargando = true
    @Published var mensajeError: String? = nil
    @Published var inicioSesion = false
    @Published var debugInfo: String = ""

    private var manejador: AuthStateDidChangeListenerHandle?

    init() {
        /// Escuchamos cambios de estado de Firebase Auth
        manejador = Auth.auth().addStateDidChangeListener {
            [weak self] _, usuarioFirebase in
            guard let self = self else { return }

            let estabaLogueado = self.usuario != nil

            /// Sólo consideramos "logueado" a usuarios que no sean anónimos
            if let u = usuarioFirebase, !u.isAnonymous {
                self.usuario = u
                /// Si no estaba logueado antes y ahora sí, activamos el flag
                if !estabaLogueado {
                    self.inicioSesion = true
                }
                self.debugInfo = "✅ Usuario autenticado: \(u.email ?? "Sin email")"
            } else {
                self.usuario = nil
                self.debugInfo = "❌ No hay usuario autenticado"
            }
            self.estaCargando = false
        }
        
        // Diagnóstico inicial
        diagnosticarEstadoAuth()
    }

    deinit {
        /// Eliminamos el listener
        if let h = manejador {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }

    /// Registra un nuevo usuario con e-mail y contraseña
    func registrarse(email: String, contrasena: String) async {
        estaCargando = true
        mensajeError = nil
        debugInfo = "🔄 Intentando registrar usuario..."
        
        defer { estaCargando = false }

        // Validaciones previas
        guard !email.isEmpty, !contrasena.isEmpty else {
            mensajeError = "Email y contraseña son requeridos"
            debugInfo = "❌ Validación fallida: campos vacíos"
            return
        }
        
        guard contrasena.count >= 6 else {
            mensajeError = "La contraseña debe tener al menos 6 caracteres"
            debugInfo = "❌ Validación fallida: contraseña muy corta"
            return
        }
        
        guard email.contains("@") else {
            mensajeError = "Email no válido"
            debugInfo = "❌ Validación fallida: email inválido"
            return
        }

        do {
            debugInfo = "🔄 Llamando a Firebase Auth..."
            let resultado = try await Auth.auth().createUser(
                withEmail: email,
                password: contrasena
            )
            
            debugInfo = "✅ Usuario creado: \(resultado.user.uid)"
            
            /// Enviar email de verificación
            try await resultado.user.sendEmailVerification()
            debugInfo += "\n📧 Email de verificación enviado"
            
            self.usuario = resultado.user
            self.inicioSesion = true
            
        } catch let error as NSError {
            self.mensajeError = error.localizedDescription
            
            // Diagnóstico detallado del error
            debugInfo = "❌ Error de registro:\n"
            debugInfo += "  Código: \(error.code)\n"
            debugInfo += "  Descripción: \(error.localizedDescription)\n"
            debugInfo += "  Dominio: \(error.domain)\n"
            
            // Errores específicos de Firebase Auth
            if let authError = AuthErrorCode(rawValue: error.code) {
                switch authError {
                case .emailAlreadyInUse:
                    self.mensajeError = "Este email ya está registrado"
                case .invalidEmail:
                    self.mensajeError = "Email no válido"
                case .weakPassword:
                    self.mensajeError = "Contraseña muy débil"
                case .networkError:
                    self.mensajeError = "Error de conexión. Verifica tu internet"
                case .tooManyRequests:
                    self.mensajeError = "Demasiados intentos. Espera un momento"
                default:
                    debugInfo += "  Tipo de error Auth: \(authError.localizedDescription)"
                }
            }
            
            print(debugInfo)
        }
    }

    /// Hace login con e-mail y contraseña
    func iniciarSesion(email: String, contrasena: String) async {
        estaCargando = true
        mensajeError = nil
        debugInfo = "🔄 Intentando iniciar sesión..."
        
        defer { estaCargando = false }

        do {
            let resultado = try await Auth.auth().signIn(
                withEmail: email,
                password: contrasena
            )
            self.usuario = resultado.user
            self.inicioSesion = true
            debugInfo = "✅ Sesión iniciada: \(resultado.user.email ?? "Sin email")"
            
        } catch let error as NSError {
            self.mensajeError = error.localizedDescription
            debugInfo = "❌ Error de login: \(error.localizedDescription)"
            print(debugInfo)
        }
    }

    /// Cierra la sesión actual
    func cerrarSesion() async {
        estaCargando = true
        defer {
            self.usuario = nil
            estaCargando = false
            self.inicioSesion = false
        }
        do {
            try Auth.auth().signOut()
            debugInfo = "✅ Sesión cerrada"
        } catch {
            self.mensajeError = error.localizedDescription
            debugInfo = "❌ Error al cerrar sesión: \(error.localizedDescription)"
        }
    }
    
    /// Diagnóstica el estado actual de Authentication
    private func diagnosticarEstadoAuth() {
        let auth = Auth.auth()
        
        debugInfo = "🔍 Diagnóstico de Authentication:\n"
        debugInfo += "  🔗 Auth inicializado: \(auth.app?.name ?? "No")\n"
        debugInfo += "  👤 Usuario actual: \(auth.currentUser?.email ?? "Ninguno")\n"
        debugInfo += "  🌐 Configuración válida: \(auth.app != nil ? "Sí" : "No")\n"
        
        print(debugInfo)
    }
}
