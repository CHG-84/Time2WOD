import Foundation

/// Generador para WODs de tipo FOR TIME
struct GeneradorForTime: WODGeneradorProtocolo {
    let tipo: TipoDeWOD = .forTime

    func generar(
        tiempo: Int,
        dificultad: NivelDeDificultad,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        /// Carga y filtrado inicial
        let todos = CargadorEjercicios.cargaEjercicios()
        let compatibles = todos.filter {
            $0.equipamiento.allSatisfy(equipamiento.contains) &&
            ($0.habilidades.isEmpty || !Set($0.habilidades).isDisjoint(with: Set(habilidades)))
        }
        let coherentes = filtrarCoherencia(compatibles)

        /// Decidir aleatoriamente si usar rondas
        /// Para entrenamientos muy cortos (<8 min), favorecemos rondas
        /// Para entrenamientos muy largos (>20 min), favorecemos sin rondas
        let probabilidadRondas: Double = {
            if tiempo < 8 { return 0.8 }      /// 80% probabilidad de rondas
            else if tiempo > 20 { return 0.3 } /// 30% probabilidad de rondas
            else { return 0.5 }               /// 50% probabilidad de rondas
        }()
        
        let usaRondas = Double.random(in: 0...1) < probabilidadRondas
        
        /// Calcular el tiempo objetivo (85-90% del tiempo total)
        let tiempoObjetivoSegundos = Double(tiempo * 60) * 0.87
        
        /// Generar ejercicios
        if usaRondas {
            return generarConRondas(
                coherentes: coherentes,
                tiempoObjetivo: tiempoObjetivoSegundos,
                dificultad: dificultad,
                tiempo: tiempo,
                equipamiento: equipamiento
            )
        } else {
            return generarSinRondas(
                coherentes: coherentes,
                tiempoObjetivo: tiempoObjetivoSegundos,
                dificultad: dificultad,
                tiempo: tiempo,
                equipamiento: equipamiento
            )
        }
    }
    
    private func generarConRondas(
        coherentes: [Ejercicio],
        tiempoObjetivo: Double,
        dificultad: NivelDeDificultad,
        tiempo: Int,
        equipamiento: [String]
    ) -> WODGenerado {
        /// Separar ejercicios de cardio y no cardio
        let ejerciciosCardio = coherentes.filter { esEjercicioCardio($0) }
        let ejerciciosNoCardio = coherentes.filter { !esEjercicioCardio($0) }
        
        /// Determinar número de ejercicios (3-5)
        let numEjercicios = Int.random(in: 3...6)
        var ejerciciosSeleccionados: [Ejercicio] = []
        var boxCount = 0
        var burpeeCount = 0
        
        /// Intentar incluir un ejercicio de cardio si está disponible
        if let cardio = ejerciciosCardio.randomElement(), ejerciciosSeleccionados.count < numEjercicios {
            ejerciciosSeleccionados.append(cardio)
        }
        
        /// Añadir el resto de ejercicios
        for ex in ejerciciosNoCardio.shuffled() {
            if ejerciciosSeleccionados.count >= numEjercicios { break }
            if ex.equipamiento.contains("Box") && boxCount >= 1 { continue }
            if ex.nombre.lowercased().contains("burpee") && burpeeCount >= 1 { continue }
            
            ejerciciosSeleccionados.append(ex)
            if ex.equipamiento.contains("Box") { boxCount += 1 }
            if ex.nombre.lowercased().contains("burpee") { burpeeCount += 1 }
        }
        
        /// Si no tenemos suficientes, añadir más ejercicios de cardio
        while ejerciciosSeleccionados.count < numEjercicios && !ejerciciosCardio.isEmpty {
            if let cardio = ejerciciosCardio.randomElement(), !ejerciciosSeleccionados.contains(where: { $0.id == cardio.id }) {
                ejerciciosSeleccionados.append(cardio)
            } else {
                break
            }
        }
        
        /// Calcular repeticiones base para cada ejercicio
        var ejerciciosConReps: [(Ejercicio, Int)] = []
        var tiempoEstimadoPorRonda = 0.0
        
        for ex in ejerciciosSeleccionados {
            let repsBase = calcularRepeticionesBase(ejercicio: ex, dificultad: dificultad)
            let tiempoEjercicio = Double(repsBase * ex.tiempoPorRepeticion)
            tiempoEstimadoPorRonda += tiempoEjercicio
            ejerciciosConReps.append((ex, repsBase))
        }
        
        /// Calcular número de rondas necesarias
        let rondasNecesarias = max(2, Int(ceil(tiempoObjetivo / tiempoEstimadoPorRonda)))
        let rondasFinales = min(5, rondasNecesarias)
        
        let tiempoTotalEstimado = tiempoEstimadoPorRonda * Double(rondasFinales)
        print("⏱️ Tiempo estimado: \(tiempoTotalEstimado/60) minutos para \(rondasFinales) rondas")
        
        /// Formatear ejercicios
        let ejerciciosFormateados = ejerciciosConReps.map { (ex, reps) in
            formatearEjercicio(ejercicio: ex, repeticiones: reps)
        }
        
        return WODGenerado(
            tipo: tipo,
            ejercicios: ejerciciosFormateados,
            duracion: tiempo,
            dificultad: dificultad,
            requiereContadorDeRondas: true,
            rondas: rondasFinales
        )
    }
    
    private func generarSinRondas(
        coherentes: [Ejercicio],
        tiempoObjetivo: Double,
        dificultad: NivelDeDificultad,
        tiempo: Int,
        equipamiento: [String]
    ) -> WODGenerado {
        /// Separar ejercicios de cardio y no cardio
        let ejerciciosCardio = coherentes.filter { esEjercicioCardio($0) }
        let ejerciciosNoCardio = coherentes.filter { !esEjercicioCardio($0) }
        
        /// Verificar disponibilidad de equipamiento de cardio
        let tieneRunning = equipamiento.contains("Running Area")
        let tieneRowing = equipamiento.contains("Rowing Machine")
        let tieneAssaultBike = equipamiento.contains("Assault Bike")
        let tieneSkiErg = equipamiento.contains("SkiErg")
        
        /// Estructura para el entrenamiento
        var estructura: [Ejercicio] = []
        
        /// Intentar empezar con correr si está disponible
        if tieneRunning, let run = ejerciciosCardio.first(where: { $0.nombre == "Run" }) {
            estructura.append(run)
        }
        
        /// Número de bloques de ejercicios (entre 3 y 5)
        let numBloques = Int.random(in: 3...6)
        
        /// Crear bloques de ejercicios intercalados con cardio
        var cardioDisponible = [Ejercicio]()
        if tieneRowing, let row = ejerciciosCardio.first(where: { $0.nombre == "Row" }) {
            cardioDisponible.append(row)
        }
        if tieneAssaultBike, let bike = ejerciciosCardio.first(where: { $0.nombre == "Assault Bike" }) {
            cardioDisponible.append(bike)
        }
        if tieneSkiErg, let ski = ejerciciosCardio.first(where: { $0.nombre == "Ski" }) {
            cardioDisponible.append(ski)
        }
        if tieneRunning, let run = ejerciciosCardio.first(where: { $0.nombre == "Run" }) {
            cardioDisponible.append(run)
        }
        
        /// Mezclar el cardio disponible
        cardioDisponible.shuffle()
        
        /// Filtrar ejercicios no cardio para evitar duplicados
        var ejerciciosNoCardioFiltrados = ejerciciosNoCardio
        var boxCount = 0
        var burpeeCount = 0
        
        /// Crear bloques de ejercicios con estructura más variable
        let ejerciciosPorBloque = Int.random(in: 1...3) // 1-3 ejercicios por bloque
        for i in 0..<numBloques {
            /// Añadir ejercicios variables por bloque
            for _ in 0..<ejerciciosPorBloque {
                if ejerciciosNoCardioFiltrados.isEmpty { break }
                
                /// Seleccionar ejercicio evitando duplicados de box y burpees
                var ejercicioSeleccionado: Ejercicio?
                
                for (index, ex) in ejerciciosNoCardioFiltrados.enumerated() {
                    if ex.equipamiento.contains("Box") && boxCount >= 1 { continue }
                    if ex.nombre.lowercased().contains("burpee") && burpeeCount >= 2 { continue }
                    
                    ejercicioSeleccionado = ex
                    ejerciciosNoCardioFiltrados.remove(at: index)
                    
                    if ex.equipamiento.contains("Box") { boxCount += 1 }
                    if ex.nombre.lowercased().contains("burpee") { burpeeCount += 1 }
                    
                    break
                }
                
                if let ex = ejercicioSeleccionado {
                    estructura.append(ex)
                }
            }
            
            /// Decidir aleatoriamente si añadir cardio (70% probabilidad)
            if i < numBloques - 1 && !cardioDisponible.isEmpty && Double.random(in: 0...1) < 0.7 {
                let cardioIndex = i % cardioDisponible.count
                estructura.append(cardioDisponible[cardioIndex])
            }
        }
        
        /// Intentar terminar con running si está disponible y no es el último ejercicio añadido
        if tieneRunning, let run = ejerciciosCardio.first(where: { $0.nombre == "Run" }),
           estructura.last?.nombre != "Run" {
            estructura.append(run)
        }
        
        /// Calcular tiempo total disponible y distribuirlo entre los ejercicios
        let tiempoPorEjercicio = tiempoObjetivo / Double(estructura.count)
        
        /// Asignar repeticiones a cada ejercicio
        var ejerciciosConReps: [(Ejercicio, Int)] = []
        var tiempoAcumulado = 0.0
        
        for ex in estructura {
            /// Calcular repeticiones para este ejercicio
            var repsFinales: Int
            
            if esEjercicioCardio(ex) {
                /// Para cardio, usar valores específicos
                switch ex.nombre {
                case "Run":
                    repsFinales = [200, 400, 600].randomElement()!
                case "Row":
                    repsFinales = Int.random(in: 12...20) // calorías
                case "Assault Bike":
                    repsFinales = Int.random(in: 10...18) // calorías
                case "Ski":
                    repsFinales = Int.random(in: 10...18) // calorías
                default:
                    repsFinales = calcularRepeticionesParaTiempo(ejercicio: ex, tiempoObjetivo: tiempoPorEjercicio, dificultad: dificultad)
                }
            } else {
                /// Para ejercicios no cardio, calcular basado en el tiempo objetivo
                repsFinales = calcularRepeticionesParaTiempo(ejercicio: ex, tiempoObjetivo: tiempoPorEjercicio, dificultad: dificultad)
            }
            
            /// Aplicar límites máximos si existen
            if let maxReps = ex.maxReps {
                repsFinales = min(repsFinales, maxReps)
            }
            
            /// Calcular tiempo para este ejercicio
            let tiempoEjercicio = Double(repsFinales * ex.tiempoPorRepeticion)
            tiempoAcumulado += tiempoEjercicio
            
            ejerciciosConReps.append((ex, repsFinales))
        }
        
        /// Formatear ejercicios
        let ejerciciosFormateados = ejerciciosConReps.map { (ex, reps) in
            formatearEjercicio(ejercicio: ex, repeticiones: reps)
        }
        
        return WODGenerado(
            tipo: tipo,
            ejercicios: ejerciciosFormateados,
            duracion: tiempo,
            dificultad: dificultad,
            requiereContadorDeRondas: false,
            rondas: nil
        )
    }
    
    private func calcularRepeticionesBase(ejercicio: Ejercicio, dificultad: NivelDeDificultad) -> Int {
        let factorDificultad: Double = {
            switch dificultad {
            case .bajo: return Double.random(in: 0.6...0.8)
            case .medio: return Double.random(in: 0.8...1.2)
            case .alto: return Double.random(in: 1.1...1.5)
            }
        }()
        
        /// Añadir factor de variabilidad adicional
        let factorVariabilidad = Double.random(in: 0.7...1.3)
        
        var repsBase: Int
        
        switch ejercicio.tipo {
        case .repeticiones:
            /// Usar rendimientoPorMinuto como base y ajustar con más variabilidad
            repsBase = Int(Double(ejercicio.rendimientoPorMinuto) * factorDificultad * factorVariabilidad * Double.random(in: 0.6...1.0))
        case .calorias:
            /// Para calorías, usar valores más conservadores pero variables
            repsBase = Int(Double(ejercicio.rendimientoPorMinuto) * factorDificultad * factorVariabilidad * Double.random(in: 0.4...0.8))
        case .metros:
            if ejercicio.nombre.lowercased().contains("run") {
                /// Para correr, usar distancias más variadas
                let distancias = [100, 200, 300, 400, 500, 600, 800]
                repsBase = distancias.randomElement()!
            } else if ejercicio.nombre == "Handstand Walk" {
                repsBase = [5, 10, 15, 20].randomElement()!
            } else {
                repsBase = Int(Double(ejercicio.rendimientoPorMinuto) * factorDificultad * factorVariabilidad * Double.random(in: 0.3...0.7))
            }
        case .segundos:
            /// Para ejercicios de tiempo, usar valores más variados
            repsBase = [20, 30, 45, 60, 90].randomElement()!
        }
        
        /// Aplicar límites máximos si existen
        if let maxReps = ejercicio.maxReps {
            repsBase = min(repsBase, maxReps)
        }
        
        return max(1, repsBase)
    }
    
    private func calcularRepeticionesParaTiempo(ejercicio: Ejercicio, tiempoObjetivo: Double, dificultad: NivelDeDificultad) -> Int {
        /// Calcular cuántas repeticiones se necesitan para alcanzar el tiempo objetivo
        let repsNecesarias = Int(tiempoObjetivo / Double(ejercicio.tiempoPorRepeticion))
        
        /// Ajustar según dificultad
        let factorDificultad: Double = {
            switch dificultad {
            case .bajo: return 0.8
            case .medio: return 1.0
            case .alto: return 1.2
            }
        }()
        
        let repsAjustadas = Int(Double(repsNecesarias) * factorDificultad)
        
        /// Asegurar un mínimo razonable según el tipo de ejercicio
        let repsMinimas: Int = {
            switch ejercicio.tipo {
            case .repeticiones: return 5
            case .calorias: return 10
            case .metros: return ejercicio.nombre == "Handstand Walk" ? 5 : 100
            case .segundos: return 30
            }
        }()
        
        return max(repsMinimas, repsAjustadas)
    }
    
    private func formatearEjercicio(ejercicio: Ejercicio, repeticiones: Int) -> String {
        switch ejercicio.tipo {
        case .repeticiones:
            return "• \(repeticiones) \(ejercicio.nombre)"
        case .calorias:
            return "• \(repeticiones) cal en \(ejercicio.nombre)"
        case .metros:
            return "• \(repeticiones)m de \(ejercicio.nombre)"
        case .segundos:
            return "• \(repeticiones) seg de \(ejercicio.nombre)"
        }
    }
    
    private func esEjercicioCardio(_ ejercicio: Ejercicio) -> Bool {
        let nombresCardio = ["Run", "Row", "Assault Bike", "Ski"]
        return nombresCardio.contains(ejercicio.nombre)
    }
}

private extension GeneradorForTime {
    func filtrarCoherencia(_ compatibles: [Ejercicio]) -> [Ejercicio] {
        guard let primer = compatibles.randomElement(),
              let grupo = primer.grupoMuscular.first else {
            return compatibles
        }
        if grupo == "full body" || grupo == "cardio" {
            return compatibles
        }
        return compatibles.filter {
            $0.grupoMuscular.contains(grupo) ||
            $0.grupoMuscular.contains("full body") ||
            $0.grupoMuscular.contains("cardio")
        }
    }
}
