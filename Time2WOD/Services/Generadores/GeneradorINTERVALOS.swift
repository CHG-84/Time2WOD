import Foundation

/// Generador para WODs de tipo INTERVALOS
struct GeneradorINTERVALOS: WODGeneradorProtocolo {
    let tipo: TipoDeWOD = .intervalos

    func generar(
        tiempo: Int,
        dificultad: NivelDeDificultad,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        /// No permitimos intervalos mayores de 12 minutos
        let tiempoEstimado = min(tiempo, 12)
        /// Opciones de trabajo en segundos: 2:00, 2:30, 3:00
        let opcionesTrabajo = [120, 150, 180]
        // Mapeo descanso asociado
        let descansoAsociado: [Int: Int] = [
            120: 30,
            150: 60,
            180: 90,
        ]
        /// Elegir aleatorio
        let work = opcionesTrabajo.randomElement()!
        let descanso = descansoAsociado[work]!
        /// Calcular número de ciclos
        let rondas = (tiempoEstimado * 60) / (work + descanso)

        /// Carga y filtrado inicial por equipamiento y habilidades
        let todos = CargadorEjercicios.cargaEjercicios()
        let compatibles = EjercicioFiltrador.filtrarPorEquipamientoYHabilidades(
            ejercicios: todos,
            equipamiento: equipamiento,
            habilidades: habilidades
        )
        let coherentes = EjercicioFiltrador.filtrarPorCoherencia(compatibles)

        /// Seleccionar un ejercicio aleatorio
        let ex = coherentes.randomElement()

        /// Construir descripción del ejercicio
        let ejercicioDesc: String = {
            guard let ex = ex else { return "Rest" }
            switch ex.tipo {
            case .repeticiones:
                return "Máximas repeticiones de \(ex.nombre)"
            case .calorias:
                return "Máximas calorías en \(ex.nombre)"
            case .metros:
                return "Máximos metros de \(ex.nombre)"
            case .segundos:
                return "Máximos segundos de \(ex.nombre)"
            }
        }()

        /// Montar la lista de instrucciones
        let ejercicios = [
            "\(rondas)x \(EjercicioFormateador.formatearTiempoIntervalos(work)) on / \(EjercicioFormateador.formatearTiempoIntervalos(descanso)) off",
            ejercicioDesc,
        ]

        /// Devolver el WOD generado
        return WODGenerado(
            tipo: tipo,
            ejercicios: ejercicios,
            duracion: tiempo,
            dificultad: dificultad,
            requiereContadorDeRondas: true,
            rondas: rondas
        )
    }
}
