import SwiftUI

struct WODManualView: View {
    @EnvironmentObject var historialVM: HistorialViewModel
    @State private var tipoSeleccionado: TipoDeWOD = .forTime
    @State private var tieneRondas: Bool = false
    @State private var cantidadRondas: Int = 1
    @State private var ejerciciosSeleccionados: [EjercicioManual] = []
    @State private var duracionPersonalizada: Int = 10

    /// Para intervalos
    @State private var tiempoTrabajo: Int = 180
    @State private var tiempoDescanso: Int = 90
    @State private var numeroIntervalos: Int = 5

    @State private var mostrarEjecucion = false
    @State private var keyboardVisible = false

    let opcionesEjercicios = CargadorEjercicios.cargaEjercicios()

    var duracionCalculada: Int {
        if tieneRondas {
            return cantidadRondas * ejerciciosSeleccionados.count
        } else {
            return ejerciciosSeleccionados.count
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section("Tipo de entrenamiento") {
                        Picker("Tipo", selection: $tipoSeleccionado) {
                            ForEach(
                                [
                                    TipoDeWOD.emom, .forTime, .amrap,
                                    .intervalos,
                                ],
                                id: \.self
                            ) { tipo in
                                Text(tipo.rawValue).tag(tipo)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if tipoSeleccionado == .intervalos {
                        ConfiguradorIntervalosView(
                            tiempoTrabajo: $tiempoTrabajo,
                            tiempoDescanso: $tiempoDescanso,
                            numeroIntervalos: $numeroIntervalos
                        )
                    } else {
                        seccionRondas
                        seccionEjercicios
                        seccionDuracion
                    }

                    Section {
                        Button("Iniciar WOD") {
                            mostrarEjecucion = true
                        }
                        .disabled(
                            tipoSeleccionado != .intervalos
                                && (ejerciciosSeleccionados.isEmpty
                                    || ejerciciosSeleccionados.allSatisfy {
                                        $0.nombre.isEmpty
                                    })
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                }

                if keyboardVisible {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        }
                }
            }
            .navigationTitle("WOD Manual")
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillShowNotification
                )
            ) { _ in
                keyboardVisible = true
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillHideNotification
                )
            ) { _ in
                keyboardVisible = false
            }
            .fullScreenCover(isPresented: $mostrarEjecucion) {
                EjecucionEntrenamientoView(
                    wod: crearWODGenerado(),
                    ejerciciosDetallados: crearEjerciciosDetallados(),
                    mostrarHojaFinalizacion: true,
                    mostrarEjercicios: true,
                    alFinalizar: { mostrarEjecucion = false }
                )
                .environmentObject(historialVM)
            }
        }
    }

    private var seccionRondas: some View {
        Section("Rondas") {
            if tipoSeleccionado == .emom {
                Toggle("Usar rondas", isOn: $tieneRondas)
                if tieneRondas {
                    Stepper(
                        "Rondas: \(cantidadRondas)",
                        value: $cantidadRondas,
                        in: 2...100
                    )
                }
            } else if tipoSeleccionado == .forTime {
                Toggle("Usar rondas", isOn: $tieneRondas)
                if tieneRondas {
                    Stepper(
                        "Rondas: \(cantidadRondas)",
                        value: $cantidadRondas,
                        in: 2...100
                    )
                } else {
                    Text("Rondas: 1 (por defecto)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } else if tipoSeleccionado == .amrap {
                Text("AMRAP - Tantas rondas como sea posible")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }

    private var seccionEjercicios: some View {
        Section("Ejercicios y descansos") {
            ForEach(
                Array(ejerciciosSeleccionados.enumerated()),
                id: \.element.id
            ) { indice, ejercicio in
                HStack {
                    Picker(
                        "Ejercicio",
                        selection: $ejerciciosSeleccionados[indice].nombre
                    ) {
                        Text("Seleccionar...").tag("")
                        ForEach(opcionesEjercicios, id: \.nombre) { ej in
                            Text(ej.nombre).tag(ej.nombre)
                        }
                        Text("Descanso").tag("Descanso")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: ejerciciosSeleccionados[indice].nombre) {
                        _,
                        nuevoNombre in
                        if nuevoNombre == "Descanso" {
                            ejerciciosSeleccionados[indice].tipo = .segundos
                            ejerciciosSeleccionados[indice].cantidad = 60
                        } else if let ejercicio = opcionesEjercicios.first(
                            where: { $0.nombre == nuevoNombre })
                        {
                            ejerciciosSeleccionados[indice].tipo =
                                ejercicio.tipo
                        }
                    }

                    Spacer()

                    /// Campo de cantidad de descanso en EMOM
                    if ejercicio.nombre == "Descanso"
                        && tipoSeleccionado == .emom
                    {
                        Text("60")
                            .frame(width: 60)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.secondary)
                    } else {
                        TextField(
                            "Cantidad",
                            value: $ejerciciosSeleccionados[indice].cantidad,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Text(EjercicioFormateador.obtenerUnidad(para: ejercicio))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                }
            }
            .onDelete { offsets in
                ejerciciosSeleccionados.remove(atOffsets: offsets)
            }

            Button(action: {
                ejerciciosSeleccionados.append(EjercicioManual())
            }) {
                Label("Añadir ejercicio", systemImage: "plus.circle")
            }

            Button(action: {
                /// Para EMOM, el descanso siempre es 60 segundos
                let cantidadDescanso = tipoSeleccionado == .emom ? 60 : 60
                ejerciciosSeleccionados.append(
                    EjercicioManual(
                        nombre: "Descanso",
                        cantidad: cantidadDescanso,
                        tipo: .segundos
                    )
                )
            }) {
                Label("Añadir descanso", systemImage: "pause.circle")
            }
        }
    }

    private var seccionDuracion: some View {
        Section("Duración (min)") {
            if tipoSeleccionado == .emom {
                Text("Duración EMOM: \(duracionCalculada) min")
                    .foregroundColor(.secondary)
            } else {
                Picker("Duración", selection: $duracionPersonalizada) {
                    ForEach(6...40, id: \.self) { min in
                        Text("\(min)")
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private func crearWODGenerado() -> WODGenerado {
        return WODFactory.crearWODManual(
            tipo: tipoSeleccionado,
            ejercicios: ejerciciosSeleccionados,
            duracion: duracionPersonalizada,
            rondas: cantidadRondas,
            tieneRondas: tieneRondas,
            tiempoTrabajo: tiempoTrabajo,
            tiempoDescanso: tiempoDescanso,
            numeroIntervalos: numeroIntervalos
        )
    }

    private func crearEjerciciosDetallados() -> [EjercicioDetallado]? {
        guard tipoSeleccionado != .intervalos else { return nil }

        return ejerciciosSeleccionados.filter { !$0.nombre.isEmpty }.map {
            ejercicio in
            EjercicioDetallado(
                nombre: ejercicio.nombre,
                cantidad: ejercicio.cantidad,
                unidad: EjercicioFormateador.obtenerUnidad(para: ejercicio)
            )
        }
    }
}

struct EjercicioManual: Identifiable {
    let id = UUID()
    var nombre: String = ""
    var cantidad: Int = 1
    var tipo: TipoDeEjercicio = .repeticiones
}
