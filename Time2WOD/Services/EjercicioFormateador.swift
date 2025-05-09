//
//  EjercicioFormateador.swift
//  Time2WOD
//
//  Created by Carlos Hermida Gómez on 28/5/25.
//


import Foundation

/// Servicio para formatear ejercicios de manera consistente en toda la aplicación
struct EjercicioFormateador {
    
    /// Formatea un ejercicio manual para mostrar en la UI
    static func formatearEjercicioManual(_ ejercicio: EjercicioManual) -> String {
        if ejercicio.nombre == "Descanso" {
            return "\(ejercicio.cantidad) seg de Descanso"
        }
        
        switch ejercicio.tipo {
        case .repeticiones:
            return "\(ejercicio.cantidad) \(ejercicio.nombre)"
        case .calorias:
            return "\(ejercicio.cantidad) cal en \(ejercicio.nombre)"
        case .metros:
            return "\(ejercicio.cantidad)m de \(ejercicio.nombre)"
        case .segundos:
            return "\(ejercicio.cantidad) seg de \(ejercicio.nombre)"
        }
    }
    
    /// Formatea un ejercicio detallado para mostrar en la UI
    static func formatearEjercicioDetallado(_ ejercicio: EjercicioDetallado) -> String {
        return "\(ejercicio.cantidad) \(ejercicio.unidad) \(ejercicio.nombre)"
    }
    
    /// Formatea un ejercicio del modelo para mostrar en la UI
    static func formatearEjercicio(ejercicio: Ejercicio, repeticiones: Int) -> String {
        switch ejercicio.tipo {
        case .repeticiones:
            return "• \(repeticiones) \(ejercicio.nombre)"
        case .calorias:
            return "• \(repeticiones) cal en \(ejercicio.nombre)"
        case .metros:
            return "• \(repeticiones)m de \(ejercicio.nombre)"
        case .segundos:
            return "• \(repeticiones) seg de \(ejercicio.nombre)"
        }
    }
    
    /// Obtiene la unidad de medida para un ejercicio
    static func obtenerUnidad(para ejercicio: EjercicioManual) -> String {
        if ejercicio.nombre == "Descanso" {
            return "seg"
        }
        
        if ["Row", "Assault Bike", "Ski"].contains(ejercicio.nombre) {
            return "kcal"
        }
        
        if ejercicio.nombre == "Run" {
            return "m"
        }
        
        switch ejercicio.tipo {
        case .repeticiones: return ""
        case .calorias: return "kcal"
        case .metros: return "m"
        case .segundos: return "seg"
        }
    }
    
    /// Formatea tiempo en segundos a formato legible
    static func formatearTiempo(_ segundos: Int) -> String {
        let minutos = segundos / 60
        let segs = segundos % 60
        return String(format: "%d:%02d", minutos, segs)
    }
    
    /// Formatea tiempo para configuración de intervalos
    static func formatearTiempoParaConfiguracion(_ segundos: Int) -> String {
        let minutos = segundos / 60
        let segs = segundos % 60
        return "\(minutos):\(String(format: "%02d", segs))"
    }
    
    /// Formatea tiempo para mostrar en intervalos (2'30")
    static func formatearTiempoIntervalos(_ segundos: Int) -> String {
        let mins = segundos / 60
        let secs = segundos % 60
        if secs == 0 {
            return "\(mins)'"
        } else {
            return "\(mins)'\(secs)\""
        }
    }
}
