//
//  PresetFormView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 14.06.2026.
//
import SwiftUI

// Shared form used for both creating a new preset and editing an existing one.
struct PresetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PresetFormViewModel

    // The original value is retained so deletion does not depend on edited form fields.
    private let originalPreset: ShootPreset?
    let onSave: (ShootPreset) -> Void
    let onDelete: ((ShootPreset) -> Void)?

    // Creates an empty add form when preset is nil, otherwise creates an edit form.
    init(
        preset: ShootPreset? = nil,
        onSave: @escaping (ShootPreset) -> Void,
        onDelete: ((ShootPreset) -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: PresetFormViewModel(preset: preset)
        )
        originalPreset = preset
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 16) {
            TextField("Preset name*", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)

            VStack(spacing: 0) {
                minutesField(
                    "Set up time*",
                    text: $viewModel.setUpMinutes
                )

                Divider()

                minutesField(
                    "Average shoot time",
                    text: $viewModel.averageShootMinutes
                )

                Divider()

                minutesField(
                    "Pack up time*",
                    text: $viewModel.packUpMinutes
                )
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let originalPreset, let onDelete {
                Button("Delete preset", role: .destructive) {
                    onDelete(originalPreset)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()
        }
        .padding()
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if originalPreset == nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard let preset = viewModel.makePreset() else {
                        return
                    }

                    onSave(preset)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(!viewModel.isValid)
            }
        }
    }

    // Builds a numeric text field with a number-pad keyboard.
    private func minutesField(
        _ title: String,
        text: Binding<String>
    ) -> some View {
        TextField(title, text: text)
            .keyboardType(.numberPad)
            .padding(12)
    }
}
