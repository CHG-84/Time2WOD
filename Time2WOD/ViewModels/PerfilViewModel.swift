import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

@MainActor
class PerfilViewModel: ObservableObject {
    @Published var nombre = ""
    @Published var apellidos = ""
    @Published var peso = ""
    @Published var estatura = ""
    @Published var urlImagenPerfil: URL?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var idUsuario: String? {
        Auth.auth().currentUser?.uid
    }

    func cargarPerfil() async {
        guard let uid = idUsuario else { return }
        do {
            let snapshot = try await db.collection("usuarios").document(uid)
                .getDocument()
            if let data = snapshot.data() {
                nombre = data["nombre"] as? String ?? ""
                apellidos = data["apellidos"] as? String ?? ""
                peso = data["peso"] as? String ?? ""
                estatura = data["estatura"] as? String ?? ""

                if let urlString = data["urlImagenPerfil"] as? String,
                    let url = URL(string: urlString)
                {
                    urlImagenPerfil = url
                }
            }
        } catch {
            print("Error al cargar perfil: \(error.localizedDescription)")
        }
    }

    func guardarPerfil() async {
        guard let uid = idUsuario else { return }
        var data: [String: Any] = [
            "nombre": nombre,
            "apellidos": apellidos,
            "peso": peso,
            "estatura": estatura,
        ]

        if let url = urlImagenPerfil {
            data["urlImagenPerfil"] = url.absoluteString
        }

        do {
            try await db.collection("usuarios").document(uid).setData(
                data,
                merge: true
            )
            print("Perfil guardado correctamente")
        } catch {
            print("Error al guardar perfil: \(error.localizedDescription)")
        }
    }

    func cerrarSesion() {
        try? Auth.auth().signOut()
    }

    func actualizarImagenPerfil(imagen: UIImage) async -> Bool {
        guard let uid = idUsuario else {
            return false
        }

        guard let datosImagen = imagen.jpegData(compressionQuality: 0.7) else {
            return false
        }

        let referenciaStorage = storage.reference().child(
            "imagenes_perfil/\(uid).jpg"
        )

        /// Crear metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        /// Subir la imagen usando una promesa
        return await withCheckedContinuation { continuation in
            let tareaSubida = referenciaStorage.putData(
                datosImagen,
                metadata: metadata
            ) { metadata, error in
                if let error = error {
                    continuation.resume(returning: false)
                    return
                }

                /// Obtener la URL de descarga
                referenciaStorage.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(returning: false)
                        return
                    }

                    guard let urlDescarga = url else {
                        continuation.resume(returning: false)
                        return
                    }

                    /// Actualizar la URL local
                    Task { @MainActor in
                        self.urlImagenPerfil = urlDescarga

                        /// Actualizar URL en Firestore
                        do {
                            try await self.db.collection("usuarios").document(
                                uid
                            ).updateData([
                                "urlImagenPerfil": urlDescarga.absoluteString
                            ])
                            print(
                                "Imagen de perfil actualizada correctamente en Firestore"
                            )
                            continuation.resume(returning: true)
                        } catch {
                            print(
                                "Error al actualizar Firestore: \(error.localizedDescription)"
                            )
                            continuation.resume(returning: false)
                        }
                    }
                }
            }
        }
    }
}
