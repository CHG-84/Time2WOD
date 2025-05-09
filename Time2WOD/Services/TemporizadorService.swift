import Foundation
import AVFoundation
import AudioToolbox

/// Servicio para manejar la lógica de temporizadores
class TemporizadorService: ObservableObject {
    // MARK: - Estados publicados
    @Published var tiempoTranscurrido = 0
    @Published var tiempoRestante = 0
    @Published var estaPausado = false
    @Published var rondas = 0
    @Published var ejercicioActualIndex = 0
    @Published var minutoActual = 0
    @Published var estaEnDescanso = false
    @Published var intervaloActual = 1
    @Published var estaEnTrabajo = true
    @Published var segundosEnFaseActual = 0
    @Published var entrenamientoFinalizado = false
    @Published var tiempoFinalizacion: String = ""
    
    // MARK: - Propiedades privadas
    private var temporizador: Timer?
    private var wod: WODGenerado
    private var ejerciciosDetallados: [EjercicioDetallado]?
    private var tiempoTrabajo: Int = 0
    private var tiempoDescanso: Int = 0
    private var numeroIntervalos: Int = 0
    private var duracionTotalSegundos: Int
    private var alFinalizar: () -> Void
    
    // MARK: - Inicialización
    init(wod: WODGenerado, ejerciciosDetallados: [EjercicioDetallado]?, alFinalizar: @escaping () -> Void) {
        self.wod = wod
        self.ejerciciosDetallados = ejerciciosDetallados
        self.alFinalizar = alFinalizar
        self.duracionTotalSegundos = wod.duracion * 60
        
        // Configurar según el tipo de WOD
        configurarSegunTipo()
    }
    
    // MARK: - Métodos públicos
    
    func iniciar() {
        iniciarTemporizador()
    }
    
    func pausar() {
        estaPausado = true
    }
    
    func reanudar() {
        estaPausado = false
    }
    
    func detener() {
        detenerTemporizador()
        finalizarEntrenamiento()
    }
    
    func incrementarRondas() {
        rondas += 1
        AudioServicesPlaySystemSound(1104) // Sonido de incremento
        
        // Verificar si se completaron todas las rondas en FOR TIME
        if wod.tipo == .forTime {
            if let rondasTotales = wod.rondas, rondas >= rondasTotales {
                // Completó todas las rondas
                tiempoFinalizacion = formatearTiempo(tiempoTranscurrido)
                detenerTemporizador()
                finalizarEntrenamiento()
            } else if wod.rondas == nil {
                // Sin rondas específicas, se considera completado
                tiempoFinalizacion = formatearTiempo(tiempoTranscurrido)
                detenerTemporizador()
                finalizarEntrenamiento()
            }
        }
    }
    
    // MARK: - Métodos privados
    
    private func configurarSegunTipo() {
        switch wod.tipo {
        case .amrap:
            tiempoRestante = duracionTotalSegundos
        case .forTime:
            tiempoRestante = duracionTotalSegundos
        case .emom:
            tiempoTranscurrido = 0
        case .intervalos:
            configurarIntervalos()
            tiempoTranscurrido = 0
            estaEnTrabajo = true
            segundosEnFaseActual = 0
        }
    }
    
    private func configurarIntervalos() {
        if let primerEjercicio = wod.ejercicios.first {
            parsearConfiguracionIntervalos(primerEjercicio)
        }
        
        // Valores por defecto si no se pudieron parsear
        if tiempoTrabajo == 0 { tiempoTrabajo = 180 }
        if tiempoDescanso == 0 { tiempoDescanso = 90 }
        if numeroIntervalos == 0 { numeroIntervalos = wod.rondas ?? 5 }
    }
    
    private func parsearConfiguracionIntervalos(_ configuracion: String) {
        // Formato esperado: "5x 3:00 on / 1:30 off"
        let componentes = configuracion.components(separatedBy: " ")
        
        // Extraer número de intervalos
        if let primerComponente = componentes.first,
           let numeroStr = primerComponente.components(separatedBy: "x").first,
           let numero = Int(numeroStr) {
            numeroIntervalos = numero
        }
        
        // Buscar tiempo de trabajo (antes de "on")
        for (index, componente) in componentes.enumerated() {
            if componente == "on" && index > 0 {
                let tiempoTrabajoStr = componentes[index - 1]
                tiempoTrabajo = parsearTiempo(tiempoTrabajoStr)
                break
            }
        }
        
        // Buscar tiempo de descanso (antes de "off")
        for (index, componente) in componentes.enumerated() {
            if componente == "off" && index > 0 {
                let tiempoDescansoStr = componentes[index - 1]
                tiempoDescanso = parsearTiempo(tiempoDescansoStr)
                break
            }
        }
    }
    
    private func parsearTiempo(_ tiempoStr: String) -> Int {
        // Formato "3:00" o "1:30"
        if tiempoStr.contains(":") {
            let componentes = tiempoStr.components(separatedBy: ":")
            if componentes.count == 2,
               let minutos = Int(componentes[0]),
               let segundos = Int(componentes[1]) {
                return minutos * 60 + segundos
            }
        }
        
        // Formato "180s"
        if tiempoStr.hasSuffix("s") {
            let numeroStr = String(tiempoStr.dropLast())
            if let segundos = Int(numeroStr) {
                return segundos
            }
        }
        
        // Formato "3'" o "3'30""
        if tiempoStr.contains("'") {
            let sinComillas = tiempoStr.replacingOccurrences(of: "\"", with: "")
            let componentes = sinComillas.components(separatedBy: "'")
            if let minutos = Int(componentes[0]) {
                var segundos = 0
                if componentes.count > 1 && !componentes[1].isEmpty {
                    segundos = Int(componentes[1]) ?? 0
                }
                return minutos * 60 + segundos
            }
        }
        
        return 0
    }
    
    private func iniciarTemporizador() {
        temporizador = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, !self.estaPausado else { return }
            
            switch self.wod.tipo {
            case .amrap:
                self.manejarAMRAP()
            case .forTime:
                self.manejarForTime()
            case .emom:
                self.manejarEMOM()
            case .intervalos:
                self.manejarIntervalos()
            }
        }
    }
    
    private func manejarAMRAP() {
        tiempoTranscurrido += 1
        tiempoRestante = max(0, duracionTotalSegundos - tiempoTranscurrido)
        
        if tiempoRestante <= 0 {
            // Tiempo agotado
            AudioServicesPlaySystemSound(1005) // Sonido de finalización
            detenerTemporizador()
            finalizarEntrenamiento()
        }
    }
    
    private func manejarForTime() {
        tiempoTranscurrido += 1
        tiempoRestante = max(0, duracionTotalSegundos - tiempoTranscurrido)
        
        if tiempoRestante <= 0 {
            // Tiempo agotado sin completar
            AudioServicesPlaySystemSound(1005) // Sonido de finalización
            detenerTemporizador()
            finalizarEntrenamiento()
        }
    }
    
    private func manejarEMOM() {
        tiempoTranscurrido += 1
        let nuevoMinuto = tiempoTranscurrido / 60
        let segundosEnMinuto = tiempoTranscurrido % 60
        
        // Cambio de minuto
        if nuevoMinuto != minutoActual {
            minutoActual = nuevoMinuto
            if let ejercicios = ejerciciosDetallados {
                ejercicioActualIndex = minutoActual % ejercicios.count
            } else {
                ejercicioActualIndex = minutoActual % wod.ejercicios.count
            }
            
            // Verificar si el ejercicio actual es un descanso
            if let ejercicios = ejerciciosDetallados {
                let ejercicioActual = ejercicios[ejercicioActualIndex]
                estaEnDescanso = ejercicioActual.nombre.contains("Descanso") || ejercicioActual.nombre.contains("Rest")
            } else {
                let ejercicioActual = wod.ejercicios[ejercicioActualIndex]
                estaEnDescanso = ejercicioActual.contains("Rest") || ejercicioActual.contains("Descanso")
            }
        }
        
        // Pitidos en los últimos 3 segundos de cada minuto
        if segundosEnMinuto >= 57 && segundosEnMinuto < 60 {
            if tiempoTranscurrido < duracionTotalSegundos {
                AudioServicesPlaySystemSound(1057) // Pitido de aviso
            }
        }
        
        // Verificar finalización
        if tiempoTranscurrido >= duracionTotalSegundos {
            AudioServicesPlaySystemSound(1005) // Sonido de finalización diferente
            detenerTemporizador()
            finalizarEntrenamiento()
        }
    }
    
    private func manejarIntervalos() {
        tiempoTranscurrido += 1
        segundosEnFaseActual += 1
        
        let tiempoLimiteFase = estaEnTrabajo ? tiempoTrabajo : tiempoDescanso
        
        // Pitidos en los últimos 3 segundos de cualquier fase
        if segundosEnFaseActual >= tiempoLimiteFase - 3 && segundosEnFaseActual < tiempoLimiteFase {
            AudioServicesPlaySystemSound(1057) // Pitido de aviso
        }
        
        // Cambiar de fase cuando se acaba el tiempo
        if segundosEnFaseActual >= tiempoLimiteFase {
            segundosEnFaseActual = 0
            
            if estaEnTrabajo {
                // Termina el trabajo, empieza el descanso
                estaEnTrabajo = false
                estaEnDescanso = true
            } else {
                // Termina el descanso, empieza el siguiente intervalo
                estaEnTrabajo = true
                estaEnDescanso = false
                intervaloActual += 1
                
                // Verificar si hemos completado todos los intervalos
                if intervaloActual > numeroIntervalos {
                    AudioServicesPlaySystemSound(1005) // Sonido de finalización SOLO aquí
                    detenerTemporizador()
                    finalizarEntrenamiento()
                    return
                }
            }
            
            // NO reproducir sonido al cambiar de fase, solo cambio visual
        }
    }
    
    private func finalizarEntrenamiento() {
        entrenamientoFinalizado = true
    }
    
    private func detenerTemporizador() {
        temporizador?.invalidate()
        temporizador = nil
    }
    
    // MARK: - Métodos de formateo
    
    func formatearTiempo(_ segundosTotales: Int) -> String {
        let minutos = segundosTotales / 60
        let segundos = segundosTotales % 60
        return String(format: "%02d:%02d", minutos, segundos)
    }
    
    func formatearTiempoRestanteFase() -> String {
        let tiempoLimiteFase = estaEnTrabajo ? tiempoTrabajo : tiempoDescanso
        let restante = max(0, tiempoLimiteFase - segundosEnFaseActual)
        return formatearTiempo(restante)
    }
    
    func obtenerTiempoMostrar() -> String {
        switch wod.tipo {
        case .amrap, .forTime:
            return formatearTiempo(tiempoRestante)
        case .emom:
            return formatearTiempo(tiempoTranscurrido)
        case .intervalos:
            return formatearTiempo(tiempoTranscurrido)
        }
    }
    
    func obtenerEjercicioActual() -> String? {
        guard wod.tipo == .emom else { return nil }
        
        if let ejercicios = ejerciciosDetallados {
            guard ejercicioActualIndex < ejercicios.count else { return nil }
            let ejercicio = ejercicios[ejercicioActualIndex]
            return "\(ejercicio.cantidad) \(ejercicio.unidad) \(ejercicio.nombre)"
        } else {
            guard ejercicioActualIndex < wod.ejercicios.count else { return nil }
            return wod.ejercicios[ejercicioActualIndex]
        }
    }
    
    // MARK: - Limpieza
    
    deinit {
        detenerTemporizador()
    }
}
