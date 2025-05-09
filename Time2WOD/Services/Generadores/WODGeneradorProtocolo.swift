import Foundation

/// Interfaz común para todos los generadores de WOD
protocol WODGeneradorProtocolo {
    /// El tipo de WOD que genera este generador
    var tipo: TipoDeWOD { get }

    func generar(
        tiempo: Int,
        dificultad: NivelDeDificultad,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado
}
