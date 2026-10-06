//
//  PresetFormViewModel.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 14.06.2026.
//
import SwiftUI

// Stores and validates the editable values used by the add and edit preset form.
@Observable
final class PresetFormViewModel {
    // Existing preset ID. A nil value means the form is creating a new preset.
    private(set) var presetID: UUID?

    var name: String
    var setUpMinutes: String
    var averageShootMinutes: String
    var packUpMinutes: String

    // Initializes an empty form or pre-fills it with an existing preset.
    init(preset: ShootPreset? = nil) {
        presetID = preset?.id
        name = preset?.name ?? ""
        setUpMinutes = preset.map { String($0.setUpMinutes) } ?? ""
        averageShootMinutes = preset.map { String($0.averageShootMinutes) } ?? ""
        packUpMinutes = preset.map { String($0.packUpMinutes) } ?? ""
    }

    // Indicates whether the form is editing an existing preset.
    var isEditing: Bool {
        presetID != nil
    }

    // Returns the navigation title appropriate for the current form mode.
    var title: String {
        isEditing ? "Edit Preset" : "Create Preset"
    }

    // Enables saving only when required fields contain valid non-negative values.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && parsedSetUpMinutes != nil
            && parsedPackUpMinutes != nil
            && (averageShootMinutes.isEmpty || parsedAverageShootMinutes != nil)
    }

    // Converts the form strings into a domain model ready to be saved.
    // Returns nil when a required numeric value cannot be parsed.
    func makePreset() -> ShootPreset? {
        guard
            let setUpMinutes = parsedSetUpMinutes,
            let packUpMinutes = parsedPackUpMinutes
        else {
            return nil
        }

        return ShootPreset(
            id: presetID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            setUpMinutes: setUpMinutes,
            averageShootMinutes: parsedAverageShootMinutes ?? 0,
            packUpMinutes: packUpMinutes
        )
    }

    private var parsedSetUpMinutes: Int? {
        nonNegativeInteger(from: setUpMinutes)
    }

    private var parsedAverageShootMinutes: Int? {
        nonNegativeInteger(from: averageShootMinutes)
    }

    private var parsedPackUpMinutes: Int? {
        nonNegativeInteger(from: packUpMinutes)
    }

    // Parses user input and rejects negative or non-numeric values.
    private func nonNegativeInteger(from string: String) -> Int? {
        guard let number = Int(string), number >= 0 else {
            return nil
        }
        return number
    }
}
