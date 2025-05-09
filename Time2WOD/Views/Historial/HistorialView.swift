import SwiftUI

struct HistorialView: View {
    @EnvironmentObject var historialVM: HistorialViewModel
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            ForEach(historialVM.historial, id: \.uniqueId) { item in
                HistorialItemView(item: item)
            }
            .onDelete(perform: historialVM.borrar)
        }
        .navigationTitle("Historial")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Borrar todo", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar", role: .destructive) {
                historialVM.borrarTodo()
            }
        } message: {
            Text(
                "¿Estás seguro de que quieres borrar todo el historial? Esta acción no se puede deshacer."
            )
        }
        .onAppear {
            Task {
                await historialVM.cargarHistorial()
            }
        }
    }
}
