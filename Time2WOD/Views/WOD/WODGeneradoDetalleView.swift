import SwiftUI

struct WODGeneradoDetalleView: View {
    let wod: WODGenerado
    var alIniciar: (() -> Void)? = nil
    @State private var iniciarEntrenamiento = false

    var body: some View {
        VStack(spacing: 0) {
            // Contenido desplazable
            ScrollView {
                VStack(spacing: 20) {
                    // Título grande
                    Text(wod.tipo.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    // Lista de ejercicios con iconos
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(wod.ejercicios, id: \.self) { ejercicio in
                            HStack {
                                if ejercicio.lowercased().contains("run") {
                                    Label(ejercicio, systemImage: "figure.run")
                                } else if ejercicio.lowercased().contains("rest") || ejercicio.lowercased().contains("descanso") {
                                    Label(ejercicio, systemImage: "pause.circle")
                                } else {
                                    Label(ejercicio, systemImage: "dumbbell")
                                }
                                Spacer()
                            }
                            .font(.body)
                        }
                    }

                    // Datos finales
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Duración: \(wod.duracion) min")
                            .font(.headline)
                        Text("Dificultad: \(wod.dificultad.rawValue)")
                            .font(.headline)
                        if let r = wod.rondas {
                            Text("Rondas: \(r)")
                                .font(.headline)
                        }
                    }
                    .padding(.vertical)

                    // Espacio extra para que no quede oculto tras el botón
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(wod.tipo.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $iniciarEntrenamiento) {
            EjecucionEntrenamientoView(
                wod: wod,
                ejerciciosDetallados: nil,
                mostrarHojaFinalizacion: true,
                mostrarEjercicios: true
            ) {
                iniciarEntrenamiento = false
                alIniciar?()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("INICIAR") {
                iniciarEntrenamiento = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
