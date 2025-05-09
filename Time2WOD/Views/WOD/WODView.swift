import SwiftUI

struct WODView: View {
    @State private var mostrarHojaHabilidades = false
    @State private var mostrarHojaEquipamiento = false
    @State private var mostrarHojaNivel = false
    @State private var mostrarHojaTiempo = false

    @State private var habilidadesSeleccionadas: [String] = []
    @State private var equipamientoSeleccionado: [String] = []
    @State private var nivelSeleccionado: NivelDeDificultad? = nil
    @State private var tiempoSeleccionado: Int = 10
    @State private var wodGenerado: WODGenerado? = nil
    @State private var navegarADetalle = false

    var puedeGenerar: Bool {
        !habilidadesSeleccionadas.isEmpty
            && !equipamientoSeleccionado.isEmpty
            && nivelSeleccionado != nil
            && tiempoSeleccionado >= 6
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Selecciona tus preferencias:")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top)

                VStack(spacing: 15) {
                    botonSeleccion(
                        titulo: "Habilidades",
                        subtitulo: habilidadesSeleccionadas.isEmpty
                            ? "Seleccionar"
                            : "\(habilidadesSeleccionadas.count) seleccionadas",
                        icono: "figure.highintensity.intervaltraining"
                    ) { mostrarHojaHabilidades = true }

                    botonSeleccion(
                        titulo: "Equipamiento",
                        subtitulo: equipamientoSeleccionado.isEmpty
                            ? "Seleccionar"
                            : "\(equipamientoSeleccionado.count) seleccionados",
                        icono: "dumbbell"
                    ) { mostrarHojaEquipamiento = true }

                    botonSeleccion(
                        titulo: "Nivel",
                        subtitulo: nivelSeleccionado?.rawValue ?? "Seleccionar",
                        icono: "chart.bar.fill"
                    ) { mostrarHojaNivel = true }

                    botonSeleccion(
                        titulo: "Tiempo",
                        subtitulo: "\(tiempoSeleccionado) minutos",
                        icono: "clock"
                    ) { mostrarHojaTiempo = true }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    guard let nivel = nivelSeleccionado else { return }
                    // Aquí podrías usar siempre el mismo tipo o un tipo fijo, en lugar de random
                    let tipoAleatorio = TipoDeWOD.allCases.randomElement()!
                    wodGenerado = WODFactory.crearWODAutomatico(
                        tipo: tipoAleatorio,
                        dificultad: nivel,
                        tiempo: tiempoSeleccionado,
                        equipamiento: equipamientoSeleccionado,
                        habilidades: habilidadesSeleccionadas
                    )
                    navegarADetalle = true
                } label: {
                    Text("Generar WOD")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(puedeGenerar ? Color.red : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!puedeGenerar)
                .padding(.horizontal)
            }
            .navigationTitle("WOD")
            .navigationDestination(isPresented: $navegarADetalle) {
                if let wod = wodGenerado {
                    WODGeneradoDetalleView(wod: wod) {
                        navegarADetalle = false
                    }
                    .navigationTitle(wod.tipo.rawValue)
                }
            }
        }
        .sheet(isPresented: $mostrarHojaHabilidades) {
            SelectorHabilidadesView(
                habilidadesSeleccionadas: $habilidadesSeleccionadas
            )
        }
        .sheet(isPresented: $mostrarHojaEquipamiento) {
            SelectorEquipamientoView(
                equipamientoSeleccionado: $equipamientoSeleccionado
            )
        }
        .sheet(isPresented: $mostrarHojaNivel) {
            SelectorDeNivelView(nivelSeleccionado: $nivelSeleccionado)
        }
        .sheet(isPresented: $mostrarHojaTiempo) {
            SelectorDeTiempoView(tiempoSeleccionado: $tiempoSeleccionado)
        }
    }

    @ViewBuilder
    private func botonSeleccion(
        titulo: String,
        subtitulo: String,
        icono: String,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            HStack {
                Image(systemName: icono)
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 40)
                VStack(alignment: .leading) {
                    Text(titulo).font(.headline)
                    Text(subtitulo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
