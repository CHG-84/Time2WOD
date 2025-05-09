import FirebaseStorage
import SwiftUI

/// Vista del perfil de usuario
struct PerfilView: View {
    @EnvironmentObject var perfilVM: PerfilViewModel
    @EnvironmentObject var historialVM: HistorialViewModel
    @State private var mostrandoEditarPerfil = false
    @State private var mostrandoSelectorImagen = false
    @State private var imagenEntrada: UIImage?
    @State private var imagenPerfil: Image?
    @State private var estaCargando = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    /// Sección de información personal
                    VStack(spacing: 15) {
                        Text("Información Personal")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack(spacing: 20) {
                            /// Imagen de perfil
                            seccionImagenPerfil

                            /// Información del usuario
                            seccionInfoUsuario
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        /// Botones de acción
                        Button(action: {
                            mostrandoEditarPerfil = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Editar Perfil")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }

                    /// Sección de historial
                    VStack(spacing: 15) {
                        NavigationLink(
                            destination: HistorialView().environmentObject(
                                historialVM
                            )
                        ) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.red)
                                Text("Historial de Entrenamientos")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 30)

                    /// Botón de cerrar sesión
                    Button(action: {
                        perfilVM.cerrarSesion()
                    }) {
                        Text("Cerrar Sesión")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Perfil")
            .task {
                await perfilVM.cargarPerfil()
                await cargarImagenPerfil()
            }
            .sheet(
                isPresented: $mostrandoEditarPerfil,
                onDismiss: {
                    Task {
                        await perfilVM.cargarPerfil()
                        await cargarImagenPerfil()
                    }
                }
            ) {
                EditarPerfilView(
                    nombre: perfilVM.nombre,
                    apellidos: perfilVM.apellidos,
                    peso: perfilVM.peso,
                    estatura: perfilVM.estatura,
                    imagenPerfilInicial: imagenEntrada
                )
                .environmentObject(perfilVM)
            }
        }
    }

    private var seccionImagenPerfil: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)

            if estaCargando {
                ProgressView()
            } else if let imagenPerfil = imagenPerfil {
                imagenPerfil
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
        }
    }

    private var seccionInfoUsuario: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(perfilVM.nombre) \(perfilVM.apellidos)")
                .font(.title3)
                .fontWeight(.bold)

            if !perfilVM.estatura.isEmpty {
                Text("Estatura: \(perfilVM.estatura) cm")
                    .foregroundColor(.secondary)
            }

            if !perfilVM.peso.isEmpty {
                Text("Peso: \(perfilVM.peso) kg")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func cargarImagenPerfil() async {
        guard let idUsuario = perfilVM.idUsuario else { return }

        await MainActor.run {
            estaCargando = true
        }

        /// Si tenemos una URL en el viewModel, intentamos cargar desde ahí
        if let urlImagen = perfilVM.urlImagenPerfil {
            do {
                let (datos, _) = try await URLSession.shared.data(
                    from: urlImagen
                )
                if let imagenUI = UIImage(data: datos) {
                    await MainActor.run {
                        self.imagenEntrada = imagenUI
                        self.imagenPerfil = Image(uiImage: imagenUI)
                        self.estaCargando = false
                    }
                    return
                }
            } catch {
                print(
                    "Error al cargar desde URL: \(error.localizedDescription)"
                )
            }
        }

        /// Si no hay URL o falla la carga desde URL, intentamos cargar desde Storage
        await cargarImagenDesdeStorage(idUsuario: idUsuario)
    }

    func cargarImagenDesdeStorage(idUsuario: String) async {
        let referenciaStorage = Storage.storage().reference().child(
            "imagenes_perfil/\(idUsuario).jpg"
        )

        do {
            let datos = try await referenciaStorage.data(
                maxSize: 5 * 1024 * 1024
            )
            if let imagenUI = UIImage(data: datos) {
                await MainActor.run {
                    self.imagenEntrada = imagenUI
                    self.imagenPerfil = Image(uiImage: imagenUI)
                    self.estaCargando = false
                }
            }
        } catch {
            print(
                "Error al cargar imagen desde Storage: \(error.localizedDescription)"
            )
            await MainActor.run {
                self.estaCargando = false
            }
        }
    }
}

struct EditarPerfilView: View {
    @Environment(\.dismiss) private var cerrar
    @EnvironmentObject var perfilVM: PerfilViewModel
    @State private var mostrandoSelectorImagen = false
    @State private var imagenEntrada: UIImage?
    @State private var estaGuardando = false

    @State var nombre: String
    @State var apellidos: String
    @State var peso: String
    @State var estatura: String

    let imagenPerfilInicial: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Foto de Perfil")) {
                    HStack {
                        Spacer()
                        ZStack {
                            if let imagenEntrada = imagenEntrada {
                                Image(uiImage: imagenEntrada)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let imagenInicial = imagenPerfilInicial {
                                Image(uiImage: imagenInicial)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }

                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 120, height: 120)
                        }
                        .onTapGesture {
                            mostrandoSelectorImagen = true
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)

                    Button("Cambiar Foto") {
                        mostrandoSelectorImagen = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section(header: Text("Información Personal")) {
                    TextField("Nombre", text: $nombre)
                    TextField("Apellidos", text: $apellidos)
                    TextField("Peso (kg)", text: $peso)
                        .keyboardType(.decimalPad)
                    TextField("Estatura (cm)", text: $estatura)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        cerrar()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(estaGuardando ? "Guardando..." : "Guardar") {
                        guardarPerfil()
                    }
                    .disabled(estaGuardando)
                }
            }
            .sheet(isPresented: $mostrandoSelectorImagen) {
                SelectorImagen(imagen: $imagenEntrada)
            }
        }
    }

    func guardarPerfil() {
        estaGuardando = true

        /// Actualizar datos del perfil
        perfilVM.nombre = nombre
        perfilVM.apellidos = apellidos
        perfilVM.peso = peso
        perfilVM.estatura = estatura

        Task {
            /// Guardar imagen si se seleccionó una nueva
            if let nuevaImagen = imagenEntrada {
                let exito = await perfilVM.actualizarImagenPerfil(
                    imagen: nuevaImagen
                )
                if !exito {
                    print("Error al actualizar la imagen de perfil")
                }
            }

            await perfilVM.guardarPerfil()

            await MainActor.run {
                estaGuardando = false
                cerrar()
            }
        }
    }
}

struct SelectorImagen: UIViewControllerRepresentable {
    @Binding var imagen: UIImage?
    @Environment(\.dismiss) private var cerrar

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let selector = UIImagePickerController()
        selector.delegate = context.coordinator
        selector.allowsEditing = true
        return selector
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinador {
        Coordinador(self)
    }

    class Coordinador: NSObject, UIImagePickerControllerDelegate,
        UINavigationControllerDelegate
    {
        let padre: SelectorImagen

        init(_ padre: SelectorImagen) {
            self.padre = padre
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController
                .InfoKey: Any]
        ) {
            if let imagenEditada = info[.editedImage] as? UIImage {
                padre.imagen = imagenEditada
            } else if let imagenOriginal = info[.originalImage] as? UIImage {
                padre.imagen = imagenOriginal
            }

            padre.cerrar()
        }
    }
}
