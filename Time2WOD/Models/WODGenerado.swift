import Foundation

/// Representa un WOD ya generado, para iniciar o guardar
struct WODGenerado: Identifiable, Codable {
    let id: UUID
    let tipo: TipoDeWOD
    let ejercicios: [String]
    let duracion: Int  // en minutos
    let dificultad: NivelDeDificultad
    let requiereContadorDeRondas: Bool
    let rondas: Int?

    /// Inicializador por defecto
    init(
        id: UUID = UUID(),
        tipo: TipoDeWOD,
        ejercicios: [String],
        duracion: Int,
        dificultad: NivelDeDificultad,
        requiereContadorDeRondas: Bool,
        rondas: Int?
    ) {
        self.id = id
        self.tipo = tipo
        self.ejercicios = ejercicios
        self.duracion = duracion
        self.dificultad = dificultad
        self.requiereContadorDeRondas = requiereContadorDeRondas
        self.rondas = rondas
    }

    /// Decodificación personalizada
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        tipo = try container.decode(TipoDeWOD.self, forKey: .tipo)
        ejercicios = try container.decode([String].self, forKey: .ejercicios)
        duracion = try container.decode(Int.self, forKey: .duracion)
        dificultad = try container.decode(
            NivelDeDificultad.self,
            forKey: .dificultad
        )
        requiereContadorDeRondas = try container.decode(
            Bool.self,
            forKey: .requiereContadorDeRondas
        )
        rondas = try container.decodeIfPresent(Int.self, forKey: .rondas)
    }

    /// Mapeo de claves para Codable
    enum CodingKeys: String, CodingKey {
        case id, tipo, ejercicios, duracion, dificultad,
            requiereContadorDeRondas, rondas
    }
}
