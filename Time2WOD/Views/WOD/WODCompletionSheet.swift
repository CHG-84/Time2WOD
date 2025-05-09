import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct HojaFinalizacionWOD: View {
    @EnvironmentObject var historialVM: HistorialViewModel

    let wod: WODGenerado
    let rondasCompletadas: Int
    let tiempoTranscurrido: Int
    var alCancelar: () -> Void

    @State private var puntuacion: String = ""
    @State private var notas: String = ""
    @State private var pesos: [String: String] = [:]
    @State private var caloriasTotales: String = ""

    /// Ejercicios cargados para verificar cuáles requieren peso
    private let ejercicios = CargadorEjercicios.cargaEjercicios()

    /// Referencia a Firestore
    private let db = Firestore.firestore()

    private var tituloEntrenamiento: String {
        "\(wod.tipo.rawValue) \(wod.duracion)'"
    }

    /// Formatea el tiempo transcurrido
    private var tiempoTranscurridoFormateado: String {
        let minutos = tiempoTranscurrido / 60
        let segundos = tiempoTranscurrido % 60
        return String(format: "%02d:%02d", minutos, segundos)
    }

    /// Comprobar si el entrenamiento es de intervalos con calorías
    private var esIntervaloConCalorias: Bool {
        if wod.tipo == .intervalos {
            /// Buscar si algún ejercicio contiene "calorías" o "cal"
            return wod.ejercicios.joined().lowercased().contains("cal")
        }
        return false
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Resumen")) {
                    Text(tituloEntrenamiento)
                        .font(.headline)

                    if wod.tipo == .amrap {
                        Text("Rondas completadas: \(rondasCompletadas)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else if wod.tipo == .forTime
                        && wod.requiereContadorDeRondas
                    {
                        if let rondasTotales = wod.rondas,
                            rondasCompletadas >= rondasTotales
                        {
                            Text(
                                "Tiempo total: \(tiempoTranscurridoFormateado)"
                            )
                            .font(.subheadline)
                            .foregroundColor(.green)
                        } else {
                            Text("Rondas completadas: \(rondasCompletadas)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }

                /// Sección de resultado (solo para FOR TIME sin rondas)
                if wod.tipo == .forTime && !wod.requiereContadorDeRondas {
                    Section(header: Text("Tiempo")) {
                        TextField("Tiempo (mm:ss)", text: $puntuacion)
                    }
                }

                /// Sección para calorías (solo para intervalos con calorías)
                if esIntervaloConCalorias {
                    Section(header: Text("Total de Calorías")) {
                        TextField("Calorías totales", text: $caloriasTotales)
                            .keyboardType(.numberPad)
                    }
                }

                /// Sección de ejercicios
                Section(header: Text("Ejercicios")) {
                    ForEach(wod.ejercicios, id: \.self) {
                        descripcionEjercicio in
                        let nombreEjercicio = extraerNombreEjercicio(
                            de: descripcionEjercicio
                        )
                        if requierePeso(nombreEjercicio) {
                            HStack {
                                Text(descripcionEjercicio)
                                Spacer()
                                TextField(
                                    "kg",
                                    text: Binding(
                                        get: { pesos[nombreEjercicio] ?? "" },
                                        set: { pesos[nombreEjercicio] = $0 }
                                    )
                                )
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            }
                        } else {
                            Text(descripcionEjercicio)
                        }
                    }
                }

                /// Sección de notas
                Section(header: Text("Notas")) {
                    TextEditor(text: $notas)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Completar WOD")
            .navigationBarItems(
                leading: Button("Cancelar", action: alCancelar),
                trailing: Button("Guardar") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )

                    let pesosFiltrados = pesos.filter { !$0.value.isEmpty }

                    /// Preparar el resultado según el tipo de WOD
                    var resultado: String
                    if wod.tipo == .amrap {
                        resultado = "\(rondasCompletadas) rondas"
                    } else if wod.tipo == .forTime
                        && wod.requiereContadorDeRondas
                    {
                        if let rondasTotales = wod.rondas,
                            rondasCompletadas >= rondasTotales
                        {
                            resultado = tiempoTranscurridoFormateado
                            /// Tiempo total para FOR TIME completado
                        } else {
                            resultado = "\(rondasCompletadas) rondas"
                            /// Rondas parciales si no se completó
                        }
                    } else if wod.tipo == .forTime {
                        resultado =
                            puntuacion.isEmpty
                            ? tiempoTranscurridoFormateado : puntuacion
                        /// Usar tiempo registrado o ingresado
                    } else {
                        resultado =
                            puntuacion.isEmpty ? "Completado" : puntuacion
                    }

                    /// Si es un intervalo de calorías, añadir el total
                    if esIntervaloConCalorias && !caloriasTotales.isEmpty {
                        resultado = "\(caloriasTotales) calorías"
                    }

                    /// Crear notas con información adicional si es necesario
                    var notasFinales = notas
                    if esIntervaloConCalorias && !caloriasTotales.isEmpty
                        && !notas.isEmpty
                    {
                        notasFinales =
                            "Total: \(caloriasTotales) calorías\n\n" + notas
                    } else if esIntervaloConCalorias && !caloriasTotales.isEmpty
                    {
                        notasFinales = "Total: \(caloriasTotales) calorías"
                    }

                    /// Guardar el entrenamiento usando el método de conveniencia
                    historialVM.guardar(
                        wod: wod,
                        resultado: resultado,
                        notas: notasFinales,
                        pesos: pesosFiltrados
                    )

                    alCancelar()/// cerrar después de guardar
                }
                .disabled(
                    wod.tipo == .forTime && !wod.requiereContadorDeRondas
                        && puntuacion.isEmpty
                )
            )
        }
    }

    /// Extrae el nombre del ejercicio de la descripción
    private func extraerNombreEjercicio(de descripcion: String) -> String {
        // Elimina prefijos como "• 10 " o "1: 15 " o números y símbolos al inicio
        let limpio = descripcion.replacingOccurrences(
            of: "^[•\\d:\\s]+",
            with: "",
            options: .regularExpression
        )

        if limpio.contains("cal en ") {
            return limpio.components(separatedBy: "cal en ").last ?? limpio
        }

        if limpio.contains("m de ") {
            return limpio.components(separatedBy: "m de ").last ?? limpio
        }

        if limpio.contains("seg de ") {
            return limpio.components(separatedBy: "seg de ").last ?? limpio
        }

        if let primerNumero = limpio.rangeOfCharacter(from: .decimalDigits) {
            let despuesDelNumero = limpio[primerNumero.upperBound...]
                .trimmingCharacters(in: .whitespaces)
            return despuesDelNumero
        }

        return limpio
    }

    private func requierePeso(_ nombreEjercicio: String) -> Bool {
        /// Buscar el ejercicio en la lista de ejercicios cargados
        return ejercicios.first {
            $0.nombre.lowercased() == nombreEjercicio.lowercased()
        }?.requierePeso ?? false
    }
}
