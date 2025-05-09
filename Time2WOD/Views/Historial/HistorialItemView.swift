import SwiftUI

struct HistorialItemView: View {
    @EnvironmentObject var historialVM: HistorialViewModel
    let item: WODCompletado

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            /// Fecha y botón de favorito
            HStack {
                Text(item.fecha, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    historialVM.toggleFavorito(for: item)
                }) {
                    Image(systemName: item.esFavorito ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
            }

            /// Tipo de entrenamiento con duración
            Text("\(item.wod.tipo.rawValue) \(item.wod.duracion)'")
                .font(.headline)
                .fontWeight(.bold)

            /// Resultado (tiempo total para FOR TIME o rondas para AMRAP)
            if item.wod.tipo == .forTime {
                if item.resultado.contains(":") {
                    Text("Tiempo total: \(item.resultado)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("Resultado: \(item.resultado)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else if item.wod.tipo == .amrap {
                Text("Rondas completadas: \(item.resultado)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else if item.wod.tipo == .intervalos
                && item.resultado.contains("calorías")
            {
                Text("Total: \(item.resultado)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                Text("Resultado: \(item.resultado)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            /// Lista de ejercicios
            VStack(alignment: .leading, spacing: 4) {
                Text("Ejercicios:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 2)

                ForEach(item.wod.ejercicios, id: \.self) { ejercicio in
                    let nombreEjercicio = extraerNombreEjercicio(de: ejercicio)
                    HStack {
                        Text("• \(ejercicio)")
                            .font(.caption)

                        Spacer()

                        /// Si tiene peso registrado, mostrarlo
                        if let peso = item.pesos[nombreEjercicio], !peso.isEmpty
                        {
                            Text("\(peso) kg")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
            }

            /// Notas (si existen)
            if !item.notas.isEmpty {
                Text("Notas: \(item.notas)")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }

    /// Extrae el nombre del ejercicio de la descripción
    private func extraerNombreEjercicio(de descripcion: String) -> String {
        /// Elimina prefijos o números y símbolos al inicio
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
}
