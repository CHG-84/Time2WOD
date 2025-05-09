import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class HistorialViewModel: ObservableObject {
    @Published var historial: [WODCompletado] = []
    private let db = Firestore.firestore()

    func cargarHistorial() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await db.collection("usuarios")
                .document(userId)
                .collection("workouts")
                .order(by: "fecha", descending: true)
                .getDocuments()

            let fetched = snapshot.documents.compactMap {
                doc -> WODCompletado? in
                try? doc.data(as: WODCompletado.self)
            }

            self.historial = fetched

        } catch {
            print("Error al cargar historial: \(error.localizedDescription)")
        }
    }

    /// Método para guardar desde WODCompletionSheet
    func guardar(
        wod: WODGenerado,
        resultado: String,
        notas: String,
        pesos: [String: String]
    ) {
        let completado = WODCompletado(
            fecha: Date(),
            wod: wod,
            resultado: resultado,
            notas: notas,
            pesos: pesos
        )

        historial.append(completado)

        Task {
            guardarEnFirestore(completado)
        }
    }

    private func guardarEnFirestore(_ wodCompletado: WODCompletado) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try db.collection("usuarios")
                .document(userId)
                .collection("workouts")
                .addDocument(from: wodCompletado) { error in
                    if let error = error {
                        print(
                            "Error al guardar WOD: \(error.localizedDescription)"
                        )
                    } else {
                        print("WOD guardado correctamente en Firestore")
                    }
                }
        } catch {
            print("Error al preparar documento: \(error.localizedDescription)")
        }
    }

    func borrar(at offsets: IndexSet) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        for index in offsets {
            let entrenamiento = historial[index]
            if let id = entrenamiento.id {
                db.collection("usuarios")
                    .document(userId)
                    .collection("workouts")
                    .document(id)
                    .delete { error in
                        if let error = error {
                            print(
                                "Error al borrar entrenamiento: \(error.localizedDescription)"
                            )
                        }
                    }
            }
        }
        historial.remove(atOffsets: offsets)
    }

    func borrarTodo() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        for entrenamiento in historial {
            if let id = entrenamiento.id {
                db.collection("usuarios")
                    .document(userId)
                    .collection("workouts")
                    .document(id)
                    .delete { error in
                        if let error = error {
                            print(
                                "Error al borrar: \(error.localizedDescription)"
                            )
                        }
                    }
            }
        }
        historial.removeAll()
    }

    func toggleFavorito(for item: WODCompletado) {
        guard
            let index = historial.firstIndex(where: {
                $0.uniqueId == item.uniqueId
            })
        else { return }

        historial[index].esFavorito.toggle()

        if let userId = Auth.auth().currentUser?.uid {
            if let id = item.id {
                let docRef =
                    db
                    .collection("usuarios")
                    .document(userId)
                    .collection("workouts")
                    .document(id)

                docRef.updateData(["esFavorito": historial[index].esFavorito]) {
                    error in
                    if let error = error {
                        print(
                            "Error al actualizar favorito: \(error.localizedDescription)"
                        )
                    } else {
                        print("Estado de favorito actualizado correctamente.")
                    }
                }
            }
        }
    }
}
