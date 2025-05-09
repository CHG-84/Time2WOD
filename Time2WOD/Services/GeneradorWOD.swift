import Foundation

struct GeneradorWOD {
    private static let service = WODGeneradorService()
    
    static func generarWOD(
        tipo: TipoDeWOD,
        dificultad: NivelDeDificultad,
        tiempo: Int,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        return service.generar(
            tipo: tipo,
            tiempo: tiempo,
            dificultad: dificultad,
            equipamiento: equipamiento,
            habilidades: habilidades
        )
    }
}
