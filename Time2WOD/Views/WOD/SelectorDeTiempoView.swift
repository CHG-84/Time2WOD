import SwiftUI

struct SelectorDeTiempoView: View {
    @Binding var tiempoSeleccionado: Int
    @Environment(\.dismiss) private var cerrar

    let opciones = Array(stride(from: 6, through: 40, by: 1))

    var body: some View {
        NavigationView {
            List {
                ForEach(opciones, id: \.self) { valor in
                    Button(action: {
                        tiempoSeleccionado = valor
                    }) {
                        HStack {
                            Text("\(valor) minutos")
                            Spacer()
                            if tiempoSeleccionado == valor {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Duración del WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        cerrar()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        cerrar()
                    }
                }

            }
        }
    }
}
