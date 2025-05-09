import Foundation

/// Modelo para ejercicios con información detallada para la ejecución
struct EjercicioDetallado: Identifiable {
    let id = UUID()
    let nombre: String
    let cantidad: Int
    let unidad: String
}
