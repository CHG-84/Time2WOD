import FirebaseFirestore
import Foundation

/// WOD completado por el usuario y su estado en Firestore
struct WODCompletado: Identifiable, Codable {
    @DocumentID var id: String?
    /// Para Firestore (reemplaza UUID)
    let localId: UUID
    /// ID local para uso antes de guardar en Firestore
    let fecha: Date
    let wod: WODGenerado
    let resultado: String
    let notas: String
    let pesos: [String: String]
    var esFavorito: Bool = false

    /// Init local
    init(
        id: String? = nil,
        localId: UUID = UUID(),
        /// Generamos un UUID único para cada objeto
        fecha: Date = Date(),
        wod: WODGenerado,
        resultado: String,
        notas: String,
        pesos: [String: String] = [:]
    ) {
        self.id = id
        self.localId = localId
        self.fecha = fecha
        self.wod = wod
        self.resultado = resultado
        self.notas = notas
        self.pesos = pesos
    }

    /// Propiedad para usar como ID en las vistas
    var uniqueId: String {
        return id ?? localId.uuidString
    }
}
