import Foundation

/// Para cargar y decodificar los ejercicios del JSON
struct CargadorEjercicios {
    /// Lee el fichero y devuelve un array 'Ejercicio'
    static func cargaEjercicios(from archivo: String = "ejercicios")
        -> [Ejercicio]
    {
        guard
            let url = Bundle.main.url(
                forResource: archivo,
                withExtension: "json"
            )
        else {
            print("No se encontró \(archivo).json en el bundle.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)

            /// Intentamos decodificar
            return try JSONDecoder().decode([Ejercicio].self, from: data)

        } catch let error as DecodingError {
            /// Captura detallada de errores de decodificación
            print("Error de DecodingError cargando \(archivo).json:")
            switch error {
            case .typeMismatch(let type, let context):
                print("  • Type '\(type)' mismatch:", context.debugDescription)
                print("    in codingPath:", context.codingPath)
            case .valueNotFound(let type, let context):
                print(
                    "  • Valor de tipo '\(type)' no encontrado:",
                    context.debugDescription
                )
                print("    in codingPath:", context.codingPath)
            case .keyNotFound(let key, let context):
                print(
                    "  • Clave '\(key)' no encontrada:",
                    context.debugDescription
                )
                print("    in codingPath:", context.codingPath)
            case .dataCorrupted(let context):
                print("  • Datos corruptos:", context.debugDescription)
            @unknown default:
                print("  • Error desconocido:", error)
            }
        } catch {
            /// Cualquier otro error (lectura de fichero, etc)
            print("Error genérico cargando \(archivo).json:", error)
        }
        /// Si falla, devuelve un array vacío y no se cargan los ejercicios
        return []
    }
}
