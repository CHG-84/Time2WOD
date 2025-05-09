import Foundation

/// Tipos de entrenamiento
enum TipoDeWOD: String, CaseIterable, Identifiable, Codable {
    case forTime = "For Time"
    case amrap = "AMRAP"
    case emom = "EMOM"
    case intervalos = "Intervalos"

    /// Para usar como id en pickers o ForEach
    var id: String { self.rawValue }
}
