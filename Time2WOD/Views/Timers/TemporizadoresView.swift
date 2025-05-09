import SwiftUI

enum TipoTemporizador: String, CaseIterable {
    case AMRAP = "AMRAP"
    case EMOM = "EMOM"
    case ForTime = "FOR TIME"
    case Intervalos = "INTERVALOS"
}

struct TemporizadoresView: View {
    @State private var selectedTimerType: TipoTemporizador = .AMRAP
    @State private var duracion: Int = 10
    @State private var tieneRondas: Bool = false
    @State private var cantidadRondas: Int = 1

    /// Para intervalos - opciones predefinidas en segundos
    @State private var tiempoTrabajo: Int = 120
    @State private var tiempoDescanso: Int = 60
    @State private var numberOfIntervals = 3

    @State private var mostrarTemporizador = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tipo de Temporizador")) {
                    Picker("Selecciona un tipo", selection: $selectedTimerType)
                    {
                        ForEach(TipoTemporizador.allCases, id: \.self) { tipo in
                            Text(tipo.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if selectedTimerType == .Intervalos {
                    ConfiguradorIntervalosView(
                        tiempoTrabajo: $tiempoTrabajo,
                        tiempoDescanso: $tiempoDescanso,
                        numeroIntervalos: $numberOfIntervals
                    )
                } else {
                    Section(header: Text("Duración")) {
                        Stepper(value: $duracion, in: 1...60) {
                            Text("Duración: \(duracion) minutos")
                        }
                    }
                    
                    if selectedTimerType == .ForTime {
                        Section("Rondas") {
                            Toggle("Usar rondas", isOn: $tieneRondas)
                            if tieneRondas {
                                Stepper("Rondas: \(cantidadRondas)", value: $cantidadRondas, in: 2...10)
                            } else {
                                Text("Rondas: 1 (por defecto)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section {
                    Button("Iniciar") {
                        mostrarTemporizador = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Temporizadores")
        }
        .fullScreenCover(isPresented: $mostrarTemporizador) {
            EjecucionEntrenamientoView(
                wod: crearWODTemporizador(),
                ejerciciosDetallados: nil,
                mostrarHojaFinalizacion: false,
                mostrarEjercicios: false // No mostrar ejercicios en temporizadores libres
            ) {
                mostrarTemporizador = false
            }
        }
    }

    private func crearWODTemporizador() -> WODGenerado {
        let wodBase = WODFactory.crearWODTemporizador(
            tipo: selectedTimerType,
            duracion: duracion,
            tiempoTrabajo: tiempoTrabajo,
            tiempoDescanso: tiempoDescanso,
            numeroIntervalos: numberOfIntervals
        )
        
        if selectedTimerType == .ForTime {
            return WODGenerado(
                tipo: wodBase.tipo,
                ejercicios: wodBase.ejercicios,
                duracion: wodBase.duracion,
                dificultad: wodBase.dificultad,
                requiereContadorDeRondas: true,
                rondas: tieneRondas ? cantidadRondas : 1
            )
        }
        return wodBase
    }
}
