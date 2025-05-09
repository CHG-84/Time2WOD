import SwiftUI
import AVFoundation
import AudioToolbox

struct EjecucionEntrenamientoView: View {
    @EnvironmentObject var historialVM: HistorialViewModel
    @StateObject private var temporizadorService: TemporizadorService
    @Environment(\.dismiss) private var dismiss
    
    let wod: WODGenerado
    let ejerciciosDetallados: [EjercicioDetallado]?
    let mostrarHojaFinalizacion: Bool
    let mostrarEjercicios: Bool
    var alFinalizar: () -> Void
    
    @State private var mostrarHoja = false
    @State private var mostrarConfirmacionSalir = false
    
    init(
        wod: WODGenerado,
        ejerciciosDetallados: [EjercicioDetallado]?,
        mostrarHojaFinalizacion: Bool,
        mostrarEjercicios: Bool = true,
        alFinalizar: @escaping () -> Void
    ) {
        self.wod = wod
        self.ejerciciosDetallados = ejerciciosDetallados
        self.mostrarHojaFinalizacion = mostrarHojaFinalizacion
        self.mostrarEjercicios = mostrarEjercicios
        self.alFinalizar = alFinalizar
        _temporizadorService = StateObject(wrappedValue: TemporizadorService(
            wod: wod,
            ejerciciosDetallados: ejerciciosDetallados,
            alFinalizar: alFinalizar
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Color de fondo: azul para descanso en intervalos, negro para trabajo/normal
                (wod.tipo == .intervalos && temporizadorService.estaEnDescanso
                    ? Color.blue : Color.black)
                    .edgesIgnoringSafeArea(.all)

                if temporizadorService.entrenamientoFinalizado {
                    vistaFinalizacion
                } else {
                    vistaPrincipal(geometry: geometry)
                }
            }
        }
        .onAppear {
            temporizadorService.iniciar()
        }
        .sheet(isPresented: $mostrarHoja) {
            if mostrarHojaFinalizacion {
                HojaFinalizacionWOD(
                    wod: wod,
                    rondasCompletadas: obtenerRondasCompletadas(),
                    tiempoTranscurrido: temporizadorService.tiempoTranscurrido,
                    alCancelar: alFinalizar
                )
                .environmentObject(historialVM)
            }
        }
        .alert("¿Salir del entrenamiento?", isPresented: $mostrarConfirmacionSalir) {
            Button("Cancelar", role: .cancel) {}
            Button("Salir", role: .destructive) {
                temporizadorService.detener()
                alFinalizar()
            }
        } message: {
            Text("¿Estás seguro de que quieres salir? Se perderá el progreso actual.")
        }
    }
    
    private func vistaPrincipal(geometry: GeometryProxy) -> some View {
        VStack(spacing: 25) {
            // Título del WOD
            Text(wod.tipo.rawValue)
                .font(.system(size: 42, weight: .bold)) // Incrementado de 36 a 42
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Temporizador principal - ocupa casi todo el ancho
            temporizadorPrincipal(geometry: geometry)
                .padding(.vertical, 15)
            
            // Información específica del tipo
            informacionTipo
                .padding(.horizontal)
            
            // Lista de ejercicios (si corresponde)
            if mostrarEjercicios {
                seccionEjercicios
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Controles
            controlesEjecucion
                .padding(.horizontal)
                .padding(.bottom, 30)
        }
    }
    
    private var vistaFinalizacion: some View {
        VStack(spacing: 40) {
            Text("¡Entrenamiento Finalizado!")
                .font(.system(size: 38, weight: .bold)) // Incrementado de 32 a 38
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Mostrar resultado según el tipo
            Group {
                switch wod.tipo {
                case .amrap:
                    Text("Rondas completadas: \(temporizadorService.rondas)")
                        .font(.system(size: 32, weight: .semibold)) // Incrementado
                        .foregroundColor(.green)
                case .forTime:
                    if !temporizadorService.tiempoFinalizacion.isEmpty {
                        Text("Tiempo: \(temporizadorService.tiempoFinalizacion)")
                            .font(.system(size: 32, weight: .semibold)) // Incrementado
                            .foregroundColor(.green)
                    } else {
                        Text("Rondas completadas: \(temporizadorService.rondas)")
                            .font(.system(size: 32, weight: .semibold)) // Incrementado
                            .foregroundColor(.green)
                    }
                case .emom:
                    Text("Tiempo completado: \(wod.duracion) minutos")
                        .font(.system(size: 32, weight: .semibold)) // Incrementado
                        .foregroundColor(.green)
                case .intervalos:
                    Text("Intervalos completados: \(temporizadorService.intervaloActual - 1)")
                        .font(.system(size: 32, weight: .semibold)) // Incrementado
                        .foregroundColor(.green)
                }
            }
            .multilineTextAlignment(.center)
            
            HStack(spacing: 25) {
                if mostrarHojaFinalizacion {
                    Button("Guardar Entrenamiento") {
                        mostrarHoja = true
                    }
                    .font(.title2) // Mantenido
                    .padding(.vertical, 15)
                    .padding(.horizontal, 20)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button("Cerrar") {
                    alFinalizar()
                }
                .font(.title2) // Mantenido
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func temporizadorPrincipal(geometry: GeometryProxy) -> some View {
        VStack(spacing: 15) {
            // Temporizador que ocupa casi todo el ancho de pantalla
            Text(temporizadorService.obtenerTiempoMostrar())
                .font(.system(size: min(geometry.size.width * 0.25, 140), weight: .bold, design: .monospaced))
                .foregroundColor(.red)
                .minimumScaleFactor(0.5) // Permite reducir si es necesario
                .lineLimit(1)
            
            // Información adicional para intervalos
            if wod.tipo == .intervalos {
                Text(temporizadorService.formatearTiempoRestanteFase())
                    .font(.system(size: 28, weight: .medium)) // Incrementado de title a 28pt
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
        }
    }
    
    private var informacionTipo: some View {
        Group {
            switch wod.tipo {
            case .amrap:
                VStack(spacing: 20) {
                    Text("Rondas: \(temporizadorService.rondas)")
                        .font(.system(size: 60, weight: .bold)) // Incrementado de 50 a 60
                        .foregroundColor(.white)
                    
                    Button(action: {
                        temporizadorService.incrementarRondas()
                    }) {
                        Text("RONDA COMPLETADA")
                            .font(.system(size: 22, weight: .semibold)) // Incrementado
                            .foregroundColor(.black)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 25)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                
            case .forTime:
                VStack(spacing: 20) {
                    HStack {
                        Text("Rondas: \(temporizadorService.rondas)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let rondasTotales = wod.rondas {
                            Text("/ \(rondasTotales)")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        temporizadorService.incrementarRondas()
                    }) {
                        Text("RONDA COMPLETADA")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 25)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                
            case .emom:
                VStack(spacing: 15) {
                    Text("Minuto \(temporizadorService.minutoActual + 1)")
                        .font(.system(size: 32, weight: .semibold)) // Incrementado
                        .foregroundColor(.white)
                }
                
            case .intervalos:
                VStack(spacing: 15) {
                    Text("Intervalo \(temporizadorService.intervaloActual) de \(wod.rondas ?? 0)")
                        .font(.system(size: 26, weight: .medium)) // Incrementado
                        .foregroundColor(.white)
                    
                    Text(temporizadorService.estaEnTrabajo ? "TRABAJO" : "DESCANSO")
                        .font(.system(size: 36, weight: .bold)) // Incrementado
                        .foregroundColor(temporizadorService.estaEnTrabajo ? .green : .cyan)
                }
            }
        }
    }
    
    private var seccionEjercicios: some View {
        Group {
            if wod.tipo == .intervalos {
                // Para intervalos, mostrar ejercicios solo durante el trabajo
                if temporizadorService.estaEnTrabajo {
                    if let ejercicios = ejerciciosDetallados {
                        EjerciciosEnEjecucionView(
                            ejercicios: ejercicios,
                            ejercicioActualIndex: -1,
                            tipo: wod.tipo
                        )
                    } else {
                        EjerciciosBasicoView(
                            ejercicios: Array(wod.ejercicios.dropFirst())
                        )
                    }
                }
            } else {
                // Para otros tipos, mostrar ejercicios normalmente
                if let ejercicios = ejerciciosDetallados {
                    EjerciciosEnEjecucionView(
                        ejercicios: ejercicios,
                        ejercicioActualIndex: temporizadorService.ejercicioActualIndex,
                        tipo: wod.tipo
                    )
                } else {
                    EjerciciosBasicoView(ejercicios: wod.ejercicios)
                }
            }
        }
    }
    
    private var controlesEjecucion: some View {
        HStack(spacing: 25) {
            Button(action: {
                mostrarConfirmacionSalir = true
            }) {
                Text("Salir")
                    .font(.system(size: 20, weight: .semibold)) // Incrementado
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 25)
                    .frame(minWidth: 140) // Incrementado
                    .background(Color.gray)
                    .cornerRadius(12)
            }
            
            Button(action: {
                temporizadorService.detener()
                if mostrarHojaFinalizacion {
                    mostrarHoja = true
                } else {
                    alFinalizar()
                }
            }) {
                Text("Finalizar")
                    .font(.system(size: 20, weight: .semibold)) // Incrementado
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 25)
                    .frame(minWidth: 140) // Incrementado
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
    }
    
    private func obtenerRondasCompletadas() -> Int {
        switch wod.tipo {
        case .intervalos:
            return temporizadorService.intervaloActual - 1
        default:
            return temporizadorService.rondas
        }
    }
}
