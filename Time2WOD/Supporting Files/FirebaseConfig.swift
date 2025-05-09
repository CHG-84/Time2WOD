//
//  FirebaseConfig.swift
//  Time2WOD
//
//  Created by Carlos Hermida Gómez on 28/5/25.
//


import Foundation
import FirebaseCore
import FirebaseAuth

/// Configuración segura de Firebase con diagnósticos
struct FirebaseConfig {
    
    /// Configura Firebase con el archivo de configuración
    static func configure() {
        // Verificar que existe el archivo de configuración
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              FileManager.default.fileExists(atPath: path) else {
            fatalError("❌ GoogleService-Info.plist no encontrado. Asegúrate de añadirlo al proyecto.")
        }
        
        // Configurar Firebase
        FirebaseApp.configure()
        
        print("✅ Firebase configurado correctamente")
        
        // Diagnóstico adicional
        diagnosticarConfiguracion()
    }
    
    /// Verifica que la configuración es válida
    static func verificarConfiguracion() -> Bool {
        guard let app = FirebaseApp.app() else {
            print("❌ Firebase no está configurado")
            return false
        }
        
        guard let projectID = app.options.projectID,
              !projectID.isEmpty else {
            print("❌ Project ID no válido")
            return false
        }
        
        print("✅ Firebase configurado para proyecto: \(projectID)")
        return true
    }
    
    /// Diagnóstica la configuración de Firebase
    private static func diagnosticarConfiguracion() {
        guard let app = FirebaseApp.app() else {
            print("❌ No se pudo obtener la instancia de Firebase")
            return
        }
        
        let options = app.options
        
        print("🔍 Diagnóstico de Firebase:")
        print("  📱 Bundle ID: \(options.bundleID ?? "No definido")")
        print("  🆔 Project ID: \(options.projectID ?? "No definido")")
        print("  🔑 API Key: \(options.apiKey?.prefix(10) ?? "No definido")...")
        print("  🌐 Database URL: \(options.databaseURL ?? "No definido")")
        print("  📧 Client ID: \(options.clientID?.prefix(20) ?? "No definido")...")
        
        // Verificar Authentication
        verificarAuthentication()
    }
    
    /// Verifica que Authentication está disponible
    private static func verificarAuthentication() {
        do {
            let auth = Auth.auth()
            print("✅ Firebase Authentication inicializado")
            print("  👤 Usuario actual: \(auth.currentUser?.email ?? "Ninguno")")
            
            // Verificar configuración de Auth
            if let app = auth.app {
                print("  🔗 Auth conectado a app: \(app.name)")
            }
            
        } catch {
            print("❌ Error al inicializar Authentication: \(error.localizedDescription)")
        }
    }
}
