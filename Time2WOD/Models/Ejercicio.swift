import Foundation

/// Tipo de datos que indica como se mide el ejercicio en cuestión
///  - repeticiones: cuenta número de repeticiones
///  - calorias: cuenta calorias quemadas
///  - metros: distancia recorrida
///  - segundos: duración de ejecución del ejercicio
enum TipoDeEjercicio: String, Codable {
    case repeticiones, calorias, metros, segundos
}

/// Modelo que representa un ejercicio concreto
/// Utiliza Identifiable y Codable, Identifiable para  poder usarse en SwiftUI de forma fácil
/// y Codable  se usa para poder codificar y decodificar  desde Firestore y JSON.
struct Ejercicio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let equipamiento: [String]
    let habilidades: [String]
    let tipo: TipoDeEjercicio
    let rendimientoPorMinuto: Int
    let tiempoPorRepeticion: Int
    let grupoMuscular: [String]
    let categoria: String
    let requierePeso: Bool
    let maxReps: Int?

    /// Inicializador completo, con valores por defecto para algunos campos
    init(
        id: UUID = UUID(),
        nombre: String,
        equipamiento: [String],
        habilidades: [String] = [],
        tipo: TipoDeEjercicio,
        rendimientoPorMinuto: Int,
        tiempoPorRepeticion: Int,
        grupoMuscular: [String],
        categoria: String,
        requierePeso: Bool = false,
        maxReps: Int? = nil
    ) {
        self.id = id
        self.nombre = nombre
        self.equipamiento = equipamiento
        self.habilidades = habilidades
        self.tipo = tipo
        self.rendimientoPorMinuto = rendimientoPorMinuto
        self.tiempoPorRepeticion = tiempoPorRepeticion
        self.grupoMuscular = grupoMuscular
        self.categoria = categoria
        self.requierePeso = requierePeso
        self.maxReps = maxReps
    }

    /// Claves para codificar y decodificar
    enum CodingKeys: String, CodingKey {
        case id, nombre, equipamiento, habilidades, tipo,
            rendimientoPorMinuto, tiempoPorRepeticion,
            grupoMuscular, categoria, requierePeso, maxReps
    }

    ///  Proporciona un id automático a los datos del JSON
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        nombre = try c.decode(String.self, forKey: .nombre)
        equipamiento = try c.decode([String].self, forKey: .equipamiento)
        habilidades =
            try c.decodeIfPresent([String].self, forKey: .habilidades) ?? []
        tipo = try c.decode(TipoDeEjercicio.self, forKey: .tipo)
        rendimientoPorMinuto = try c.decode(
            Int.self,
            forKey: .rendimientoPorMinuto
        )
        tiempoPorRepeticion = try c.decode(
            Int.self,
            forKey: .tiempoPorRepeticion
        )
        grupoMuscular = try c.decode([String].self, forKey: .grupoMuscular)
        categoria = try c.decode(String.self, forKey: .categoria)
        requierePeso =
            try c.decodeIfPresent(Bool.self, forKey: .requierePeso) ?? false
        maxReps = try c.decodeIfPresent(Int.self, forKey: .maxReps)
    }
}
