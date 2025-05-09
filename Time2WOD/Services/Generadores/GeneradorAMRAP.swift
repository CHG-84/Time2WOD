import Foundation

/// Generador para modalidad AMRAP
struct GeneradorAMRAP: WODGeneradorProtocolo {
    let tipo: TipoDeWOD = .amrap

    func generar(
        tiempo: Int,
        dificultad: NivelDeDificultad,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        /// Carga y filtrado inicial de los ejercicios
        let todos = CargadorEjercicios.cargaEjercicios()
        let compatibles = EjercicioFiltrador.filtrarPorEquipamientoYHabilidades(
            ejercicios: todos,
            equipamiento: equipamiento,
            habilidades: habilidades
        )
        let coherentes = EjercicioFiltrador.filtrarPorCoherencia(compatibles)

        /// Se ajustan tiempos y limites
        let numEjercicios = Int.random(in: 3...6)
        let maxEjs = min(numEjercicios, coherentes.count)
        /// Reserva un 85% del tiempo total para trabajo efectivo
        var trabajoEfectivo = Double(tiempo * 60) * 0.85
        var ejercicios = [String]()
        var boxCount = 0
        var burpeeCount = 0

        /// Elección de ejercicios siguiendo una coherencia
        for ex in coherentes.shuffled() {
            /// Solo se permite un ejercicio que use cajón
            if ex.equipamiento.contains("Box") && boxCount >= 1 { continue }
            /// Solo se permite una variedad de burpee
            if ex.nombre.lowercased().contains("burpee") && burpeeCount >= 1 {
                continue
            }

            /// calcula repeticiones base con más variabilidad segun dificultad
            let tiempoObjetivoSegundos =
                Double(tiempo * 60) * Double.random(in: 0.75...0.90)
            let tiempoPorEjercicio = tiempoObjetivoSegundos / Double(maxEjs)
            let idealRondas =
                tiempoPorEjercicio / Double(ex.tiempoPorRepeticion)
            let base = Int(idealRondas * Double.random(in: 0.8...1.2))

            let factor: Double = {
                switch dificultad {
                case .bajo: return Double.random(in: 0.7...0.9)
                case .medio: return Double.random(in: 0.9...1.1)
                case .alto: return Double.random(in: 1.1...1.3)
                }
            }()
            var reps = max(1, Int((Double(base) * factor).rounded()))

            if ex.tipo == .segundos {
                reps = [30, 45].randomElement()!
            }
            if let cap = ex.maxReps {
                reps = min(reps, cap)
            }

            /// calcular el tiempo estimado  y si se pasa del tiempo de trabajo efectivo, se descarta
            let tiempoEstimado = Double(reps * ex.tiempoPorRepeticion)
            guard tiempoEstimado <= trabajoEfectivo else { continue }

            /// Formatea la descripción según el tipo de ejercicio
            let desc = EjercicioFormateador.formatearEjercicio(ejercicio: ex, repeticiones: reps)

            /// guardamos en la lista y quitados del tiempo de trabajo
            ejercicios.append(desc)
            trabajoEfectivo -= tiempoEstimado

            /// actualiza contadores de cajón y burpee
            if ex.equipamiento.contains("Box") { boxCount += 1 }
            if ex.nombre.lowercased().contains("burpee") { burpeeCount += 1 }

            if ejercicios.count >= maxEjs { break }
        }

        return WODGenerado(
            tipo: tipo,
            ejercicios: ejercicios,
            duracion: tiempo,
            dificultad: dificultad,
            requiereContadorDeRondas: true,
            rondas: nil
        )
    }
}
