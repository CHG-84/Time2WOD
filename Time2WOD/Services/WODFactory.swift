import Foundation

/// Factory unificado para crear WODs desde cualquier fuente
struct WODFactory {
    
    /// Crear WOD automático (desde WODView)
    static func crearWODAutomatico(
        tipo: TipoDeWOD,
        dificultad: NivelDeDificultad,
        tiempo: Int,
        equipamiento: [String],
        habilidades: [String]
    ) -> WODGenerado {
        return GeneradorWOD.generarWOD(
            tipo: tipo,
            dificultad: dificultad,
            tiempo: tiempo,
            equipamiento: equipamiento,
            habilidades: habilidades
        )
    }
    
    /// Crear WOD manual (desde WODManualView)
    static func crearWODManual(
        tipo: TipoDeWOD,
        ejercicios: [EjercicioManual],
        duracion: Int,
        rondas: Int?,
        tieneRondas: Bool,
        // Para intervalos
        tiempoTrabajo: Int = 180,
        tiempoDescanso: Int = 90,
        numeroIntervalos: Int = 5
    ) -> WODGenerado {
        
        let ejerciciosTexto: [String]
        let duracionFinal: Int
        let rondasFinal: Int?
        let requiereContador: Bool
        
        if tipo == .intervalos {
            ejerciciosTexto = crearEjerciciosIntervalos(
                tiempoTrabajo: tiempoTrabajo,
                tiempoDescanso: tiempoDescanso,
                numeroIntervalos: numeroIntervalos,
                ejercicios: ejercicios
            )
            duracionFinal = (tiempoTrabajo + tiempoDescanso) * numeroIntervalos / 60
            rondasFinal = numeroIntervalos
            requiereContador = true
        } else {
            ejerciciosTexto = ejercicios.filter { !$0.nombre.isEmpty }.map { ejercicio in
                EjercicioFormateador.formatearEjercicioManual(ejercicio)
            }
        
            if tipo == .emom {
                // Para EMOM: duración = rondas * número de ejercicios
                let numEjercicios = ejercicios.filter { !$0.nombre.isEmpty }.count
                duracionFinal = tieneRondas ? (rondas ?? 1) * numEjercicios : numEjercicios
                rondasFinal = tieneRondas ? rondas : 1
            } else if tipo == .forTime {
                // Para FOR TIME: siempre usar rondas (mínimo 1)
                duracionFinal = duracion
                rondasFinal = tieneRondas ? rondas : 1
            } else {
                // Para AMRAP
                duracionFinal = duracion
                rondasFinal = tieneRondas ? rondas : nil
            }
        
            requiereContador = tieneRondas || tipo == .emom || tipo == .amrap || tipo == .forTime
        }
        
        return WODGenerado(
            tipo: tipo,
            ejercicios: ejerciciosTexto,
            duracion: duracionFinal,
            dificultad: .medio,
            requiereContadorDeRondas: requiereContador,
            rondas: rondasFinal
        )
    }
    
    /// Crear WOD para temporizador (desde TemporizadoresView)
    static func crearWODTemporizador(
        tipo: TipoTemporizador,
        duracion: Int,
        // Para intervalos
        tiempoTrabajo: Int = 120,
        tiempoDescanso: Int = 60,
        numeroIntervalos: Int = 3
    ) -> WODGenerado {
        
        switch tipo {
        case .Intervalos:
            let ejercicios = [
                "\(numeroIntervalos)x \(EjercicioFormateador.formatearTiempo(tiempoTrabajo)) on / \(EjercicioFormateador.formatearTiempo(tiempoDescanso)) off"
            ]
            let duracionTotal = (tiempoTrabajo + tiempoDescanso) * numeroIntervalos / 60
            
            return WODGenerado(
                tipo: .intervalos,
                ejercicios: ejercicios,
                duracion: duracionTotal,
                dificultad: .medio,
                requiereContadorDeRondas: true,
                rondas: numeroIntervalos
            )
            
        case .AMRAP:
            return WODGenerado(
                tipo: .amrap,
                ejercicios: ["Temporizador libre"],
                duracion: duracion,
                dificultad: .medio,
                requiereContadorDeRondas: true,
                rondas: nil
            )
            
        case .EMOM:
            return WODGenerado(
                tipo: .emom,
                ejercicios: ["Temporizador libre"],
                duracion: duracion,
                dificultad: .medio,
                requiereContadorDeRondas: true,
                rondas: duracion
            )
            
        case .ForTime:
            return WODGenerado(
                tipo: .forTime,
                ejercicios: ["Temporizador libre"],
                duracion: duracion,
                dificultad: .medio,
                requiereContadorDeRondas: false,
                rondas: nil
            )
        }
    }
    
    // MARK: - Métodos auxiliares privados
    
    private static func crearEjerciciosIntervalos(
        tiempoTrabajo: Int,
        tiempoDescanso: Int,
        numeroIntervalos: Int,
        ejercicios: [EjercicioManual]
    ) -> [String] {
        var resultado = [
            "\(numeroIntervalos)x \(EjercicioFormateador.formatearTiempoParaConfiguracion(tiempoTrabajo)) on / \(EjercicioFormateador.formatearTiempoParaConfiguracion(tiempoDescanso)) off"
        ]
        
        let ejerciciosFiltrados = ejercicios.filter { !$0.nombre.isEmpty }
        resultado += ejerciciosFiltrados.map { EjercicioFormateador.formatearEjercicioManual($0) }
        
        return resultado
    }
}
