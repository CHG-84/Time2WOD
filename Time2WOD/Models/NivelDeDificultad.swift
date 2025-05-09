import Foundation

/// Niveles de dificultad del ejercicio
enum NivelDeDificultad: String, CaseIterable, Identifiable, Codable {
    case bajo = "Bajo"
    case medio = "Medio"
    case alto = "Alto"

    var id: String { self.rawValue }
}
