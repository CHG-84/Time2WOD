import SwiftUI

struct SelectorHabilidadesView: View {
    @Binding var habilidadesSeleccionadas: [String]
    @Environment(\.dismiss) private var cerrar

    let habilidades = [
        "Box Jumps", "Burpees", "Chest To Bar", "Double Unders",
        "Handstand", "Handstand Push Ups", "Handstand Walk",
        "Muscle Ups", "Pistols", "Pull Ups", "Rope Climbs", "Run", "Snatch"
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(habilidades, id: \.self) { habilidad in
                    Button(action: {
                        if habilidadesSeleccionadas.contains(habilidad) {
                            habilidadesSeleccionadas.removeAll { $0 == habilidad }
                        } else {
                            habilidadesSeleccionadas.append(habilidad)
                        }
                    }) {
                        HStack {
                            Text(habilidad)
                            Spacer()
                            if habilidadesSeleccionadas.contains(habilidad) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Habilidades")
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
