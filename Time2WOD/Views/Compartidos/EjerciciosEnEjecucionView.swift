import SwiftUI

struct EjerciciosEnEjecucionView: View {
    let ejercicios: [EjercicioDetallado]
    let ejercicioActualIndex: Int
    let tipo: TipoDeWOD

    var body: some View {
        ScrollView {
            VStack(spacing: 12) { // Incrementado spacing
                ForEach(Array(ejercicios.enumerated()), id: \.element.id) {
                    index,
                    ejercicio in
                    HStack {
                        /// Indicador visual para EMOM
                        if tipo == .emom {
                            Circle()
                                .fill(
                                    index == ejercicioActualIndex
                                        ? Color.green : Color.gray
                                )
                                .frame(width: 16, height: 16) // Incrementado de 12 a 16
                        } else {
                            Text("•")
                                .font(.title2) // Incrementado
                                .foregroundColor(.white)
                        }

                        Text(
                            "\(ejercicio.cantidad) \(ejercicio.unidad) \(ejercicio.nombre)"
                        )
                        .font(.title) // Incrementado de body a title3
                        .foregroundColor(
                            tipo == .emom && index == ejercicioActualIndex
                                ? .green : .white
                        )
                        .fontWeight(
                            tipo == .emom && index == ejercicioActualIndex
                                ? .bold : .regular
                        )

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8) // Incrementado de 4 a 8
                    .background(
                        tipo == .emom && index == ejercicioActualIndex
                            ? Color.green.opacity(0.2) : Color.clear
                    )
                    .cornerRadius(10) // Incrementado de 8 a 10
                }
            }
        }
        .frame(maxHeight: 250) // Incrementado de 200 a 250
    }
}

struct EjerciciosBasicoView: View {
    let ejercicios: [String]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) { // Incrementado spacing
                ForEach(ejercicios, id: \.self) { ejercicio in
                    HStack {
                        Text(ejercicio)
                            .font(.title3) // Incrementado de body a title3
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6) // Añadido padding vertical
                }
            }
        }
        .frame(maxHeight: 250) // Incrementado de 200 a 250
    }
}
