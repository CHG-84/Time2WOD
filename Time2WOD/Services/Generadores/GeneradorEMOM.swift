import Foundation

/// Generador para WODs de tipo EMOM
struct GeneradorEMOM: WODGeneradorProtocolo {
    let tipo: TipoDeWOD = .emom

    func generar(
        tiempo: Int,
        dificultad: NivelDeDificultad,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        /// Cargado y filtrado de ejercicios válidos
        let todos = CargadorEjercicios.cargaEjercicios()
        let compatibles = EjercicioFiltrador.filtrarPorEquipamientoYHabilidades(
            ejercicios: todos,
            equipamiento: equipamiento,
            habilidades: habilidades
        )
        let coherentes = EjercicioFiltrador.filtrarPorCoherencia(compatibles)

        /// Calcula número de bloques (cada minuto un bloque)
        let maxBloques = min(max(tiempo, 2), 8)
        /// al menos 2, hasta 8 bloques
        var bloques = maxBloques
        /// Buscamos divisor exacto para repartir uniformemente
        for b in (2...maxBloques).reversed() where tiempo % b == 0 {
            bloques = b
            break
        }

        /// Seleccionar ejercicios, sin repetir Box ni Burpees
        var seleccionados: [Ejercicio] = []
        var boxCount = 0
        var burpeeCount = 0

        for ex in coherentes.shuffled() {
            guard seleccionados.count < bloques else { break }
            if ex.equipamiento.contains("Box") && boxCount >= 1 { continue }
            if ex.nombre.lowercased().contains("burpee") && burpeeCount >= 1 {
                continue
            }
            seleccionados.append(ex)
            if ex.equipamiento.contains("Box") { boxCount += 1 }
            if ex.nombre.lowercased().contains("burpee") { burpeeCount += 1 }
        }

        /// Si faltan bloques, añadimos descansos
        if seleccionados.count < bloques {
            let descanso = Ejercicio(
                nombre: "Descanso",
                equipamiento: [],
                habilidades: [],
                tipo: .segundos,
                rendimientoPorMinuto: 0,
                tiempoPorRepeticion: 0,
                grupoMuscular: ["cardio"],
                categoria: "cardio",
                requierePeso: false,
                maxReps: nil
            )
            seleccionados += Array(
                repeating: descanso,
                count: bloques - seleccionados.count
            )
        }

        /// Formatear cada bloque con su etiqueta y repeticiones
        let ejercicios = seleccionados.enumerated().map { idx, ex -> String in
            let etiqueta = "\(idx + 1):"
            if ex.nombre == "Descanso" {
                return "\(etiqueta) Rest"
            }
            // usamos rendimientoPorMinuto como reps
            var reps = ex.rendimientoPorMinuto
            if let cap = ex.maxReps {
                reps = min(reps, cap)
            }
            
            var ejercicioFormateado = EjercicioFormateador.formatearEjercicio(ejercicio: ex, repeticiones: reps)
            // Quitar el bullet point y añadir la etiqueta
            ejercicioFormateado = ejercicioFormateado.replacingOccurrences(of: "• ", with: "\(etiqueta) ")
            return ejercicioFormateado
        }

        /// Devuelve WODGenerado con rondas = minutos / bloques
        let ciclos = tiempo / bloques
        return WODGenerado(
            tipo: tipo,
            ejercicios: ejercicios,
            duracion: tiempo,
            dificultad: dificultad,
            requiereContadorDeRondas: true,
            rondas: ciclos
        )
    }
}
