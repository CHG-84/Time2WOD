import SwiftUI

struct SelectorDeNivelView: View {
    @Binding var nivelSeleccionado: NivelDeDificultad?
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationView {
            List {
                ForEach(NivelDeDificultad.allCases) { nivel in
                    Button(action: {
                        nivelSeleccionado = nivel
                    }) {
                        HStack {
                            Text(nivel.rawValue)
                            Spacer()
                            if nivelSeleccionado == nivel {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Nivel De Dificultad")
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
