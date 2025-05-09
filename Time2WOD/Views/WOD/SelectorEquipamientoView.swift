import SwiftUI

struct SelectorEquipamientoView: View {
    @Binding var equipamientoSeleccionado: [String]
    @Environment(\.dismiss) private var cerrar

    let equipamiento = [
        "Assault Bike", "Barbell", "Bench", "Box", "Dip Bars",
        "Dumbells", "Jump Rope", "Kettlebell", "Med Ball", "Peg Board",
        "Pull Up Bar", "Rack", "Rings", "Rope To Climb", "Rowing Machine",
        "Running Area", "Sandbag", "SkiErg"
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(equipamiento, id: \.self) { item in
                    Button(action: {
                        if equipamientoSeleccionado.contains(item) {
                            equipamientoSeleccionado.removeAll { $0 == item }
                        } else {
                            equipamientoSeleccionado.append(item)
                        }
                    }) {
                        HStack {
                            Text(item)
                            Spacer()
                            if equipamientoSeleccionado.contains(item) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Equipamiento")
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
