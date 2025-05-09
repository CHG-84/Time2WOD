import Foundation

/// Se encarga de delegar en el generador concreto según el tipo
class WODGeneradorService {
    private let generadores: [TipoDeWOD: WODGeneradorProtocolo]

    init(
        amrap: WODGeneradorProtocolo = GeneradorAMRAP(),
        emom: WODGeneradorProtocolo = GeneradorEMOM(),
        forTime: WODGeneradorProtocolo = GeneradorForTime(),
        intervals: WODGeneradorProtocolo = GeneradorINTERVALOS()
    ) {
        self.generadores = [
            amrap.tipo: amrap,
            emom.tipo: emom,
            forTime.tipo: forTime,
            intervals.tipo: intervals,
        ]
    }

    func generar(
        tipo: TipoDeWOD,
        tiempo: Int,
        dificultad: NivelDeDificultad,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        guard let gen = generadores[tipo] else {
            fatalError("No hay generador para \(tipo)")
        }
        return gen.generar(
            tiempo: tiempo,
            dificultad: dificultad,
            equipamiento: equipamiento,
            habilidades: habilidades
        )
    }
}
