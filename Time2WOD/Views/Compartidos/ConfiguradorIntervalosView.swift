//
//  ConfiguradorIntervalosView.swift
//  Time2WOD
//
//  Created by Carlos Hermida Gómez on 28/5/25.
//


import SwiftUI

struct ConfiguradorIntervalosView: View {
    @Binding var tiempoTrabajo: Int
    @Binding var tiempoDescanso: Int
    @Binding var numeroIntervalos: Int
    
    let opcionesTrabajo = [
        (60, "01:00"),
        (90, "01:30"),
        (120, "02:00"),
        (150, "02:30"),
        (180, "03:00"),
        (210, "03:30"),
        (240, "04:00"),
        (270, "04:30"),
        (300, "05:00"),
    ]
    
    let opcionesDescanso = [
        (30, "00:30"),
        (60, "01:00"),
        (90, "01:30"),
        (120, "02:00"),
    ]
    
    var tiempoTotal: String {
        let totalSeconds = (tiempoTrabajo + tiempoDescanso) * numeroIntervalos
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        Group {
            Section(header: Text("Tiempo de Trabajo")) {
                Picker("Trabajo", selection: $tiempoTrabajo) {
                    ForEach(opcionesTrabajo, id: \.0) { segundos, texto in
                        Text(texto).tag(segundos)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Tiempo de Descanso")) {
                Picker("Descanso", selection: $tiempoDescanso) {
                    ForEach(opcionesDescanso, id: \.0) { segundos, texto in
                        Text(texto).tag(segundos)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Número de Intervalos")) {
                Stepper(value: $numeroIntervalos, in: 1...20) {
                    Text("Intervalos: \(numeroIntervalos)")
                }
            }
            
            Section {
                Text("Tiempo total: \(tiempoTotal)")
                    .foregroundColor(.secondary)
            }
        }
    }
}
