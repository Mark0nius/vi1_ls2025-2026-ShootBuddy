//
//  SettingsViewModel.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 14.06.2026.
//
import SwiftUI

// Coordinates the Settings screen state with the persistent data store.
@Observable
final class SettingsViewModel {
    var state = SettingsViewState()
    
    private let dataManager: DataManaging
    
    init(dataManager: DataManaging = DIContainer.shared.resolve()) {
        self.dataManager = dataManager
    }
    
    // Loads all saved presets and selects the first one when no current preset exists.
    func fetchPresets() {
        state.presets = dataManager.fetchPresets()
        
        // Validate that the current preset ID still exists
        if let currentID = state.currentPresetID {
            if !state.presets.contains(where: { $0.id == currentID }) {
                // Current preset was deleted, clear it
                state.currentPresetID = nil
            }
        }
        
        // If no valid preset is selected, select the first one
        if state.currentPresetID == nil {
            state.currentPresetID = state.presets.first?.id
        }
    }
    
    // Creates or updates a preset, then reloads the displayed list.
    func savePreset(_ preset: ShootPreset) {
        dataManager.savePreset(preset)
        fetchPresets()
    }
    
    // Deletes a preset and clears the selection when the active preset was removed.
    func deletePreset(_ preset: ShootPreset) {
        dataManager.deletePreset(preset)
        
        if state.currentPresetID == preset.id {
            state.currentPresetID = nil
        }
        
        fetchPresets()
    }
    
    // MARK: - Static Access
    
    /// Provides access to the current transport mode without needing a view model instance
    /// Useful for route generation and other parts of the app
    static var currentTransportMode: TransportMode {
        // Load directly from UserDefaults when needed
        guard let rawValue = UserDefaults.standard.string(forKey: "preferredTransportMode"),
              let mode = TransportMode(rawValue: rawValue) else {
            return .driving
        }
        return mode
    }
}
