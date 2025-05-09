//
//  EjercicioFiltrador.swift
//  Time2WOD
//
//  Created by Carlos Hermida Gómez on 28/5/25.
//


import Foundation

/// Servicio para filtrar ejercicios de manera consistente
struct EjercicioFiltrador {
    
    /// Filtra ejercicios por equipamiento y habilidades
    static func filtrarPorEquipamientoYHabilidades(
        ejercicios: [Ejercicio],
        equipamiento: [String],
        habilidades: [String]
    ) -> [Ejercicio] {
        return ejercicios.filter {
            $0.equipamiento.allSatisfy(equipamiento.contains) &&
            ($0.habilidades.isEmpty || !Set($0.habilidades).isDisjoint(with: Set(habilidades)))
        }
    }
    
    /// Filtra ejercicios por coherencia de grupo muscular
    static func filtrarPorCoherencia(_ compatibles: [Ejercicio]) -> [Ejercicio] {
        guard let primer = compatibles.randomElement(),
              let grupo = primer.grupoMuscular.first else {
            return compatibles
        }
        
        // Si es full body o cardio, no filtramos más
        if grupo == "full body" || grupo == "cardio" {
            return compatibles
        }
        
        // Filtramos por grupo muscular, incluyendo full body y cardio
        return compatibles.filter {
            $0.grupoMuscular.contains(grupo) ||
            $0.grupoMuscular.contains("full body") ||
            $0.grupoMuscular.contains("cardio")
        }
    }
    
    /// Evita duplicados de Box y Burpees
    static func evitarDuplicadosBoxYBurpees(
        ejercicios: [Ejercicio],
        boxCount: inout Int,
        burpeeCount: inout Int
    ) -> [Ejercicio] {
        return ejercicios.filter { ejercicio in
            if ejercicio.equipamiento.contains("Box") && boxCount >= 1 {
                return false
            }
            if ejercicio.nombre.lowercased().contains("burpee") && burpeeCount >= 1 {
                return false
            }
            
            if ejercicio.equipamiento.contains("Box") {
                boxCount += 1
            }
            if ejercicio.nombre.lowercased().contains("burpee") {
                burpeeCount += 1
            }
            
            return true
        }
    }
    
    /// Identifica si un ejercicio es de cardio
    static func esEjercicioCardio(_ ejercicio: Ejercicio) -> Bool {
        let nombresCardio = ["Run", "Row", "Assault Bike", "Ski"]
        return nombresCardio.contains(ejercicio.nombre) || ejercicio.categoria == "cardio"
    }
}
