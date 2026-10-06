//
//  SettingsViewState.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 14.06.2026.
//
import SwiftUI

// Contains the mutable UI state displayed by the Settings screen.
@Observable
final class SettingsViewState {
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let transportMode = "preferredTransportMode"
        static let currentPresetID = "currentPresetID"
    }
    
    // MARK: - State Properties
    
    // Presets currently loaded from the persistent store.
    var presets: [ShootPreset] = []

    // ID selected by the Current preset picker.
    var currentPresetID: UUID? {
        didSet {
            saveCurrentPresetID()
        }
    }
    
    // Preferred transport mode for route generation
    var preferredTransportMode: TransportMode {
        didSet {
            saveTransportMode()
        }
    }

    // Controls presentation of the add preset sheet.
    var isAddingPreset = false
    
    // MARK: - Initialization
    
    init() {
        // Load persisted settings from UserDefaults
        self.currentPresetID = Self.loadCurrentPresetID()
        self.preferredTransportMode = Self.loadTransportMode()
    }
    
    // MARK: - UserDefaults Persistence
    
    private static func loadTransportMode() -> TransportMode {
        guard let rawValue = UserDefaults.standard.string(forKey: Keys.transportMode),
              let mode = TransportMode(rawValue: rawValue) else {
            return .driving // Default to driving
        }
        return mode
    }
    
    private func saveTransportMode() {
        UserDefaults.standard.set(preferredTransportMode.rawValue, forKey: Keys.transportMode)
    }
    
    private static func loadCurrentPresetID() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: Keys.currentPresetID) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    private func saveCurrentPresetID() {
        if let id = currentPresetID {
            UserDefaults.standard.set(id.uuidString, forKey: Keys.currentPresetID)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.currentPresetID)
        }
    }
}
