//
//  SettingsView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 14.06.2026.
//
import SwiftUI

// Displays the saved presets and provides navigation for creating or editing them.
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14){
                Text("Transport")
                    .font(.headline)
                
                Divider()
                transportModePicker
                
                Spacer()
                    .frame(height: 10)
                
                Text("Presets")
                    .font(.headline)
                
                Divider()
                currentPresetPicker
                presetList
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.state.isAddingPreset = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear {
                viewModel.fetchPresets()
            }
            .sheet(isPresented: $viewModel.state.isAddingPreset) {
                NavigationStack {
                    PresetFormView { preset in
                        viewModel.savePreset(preset)
                    }
                }
            }
        }
    }
    
    // Picker bound to the preset that should be used as the active app preset.
    private var currentPresetPicker: some View {
        @Bindable var viewModel = viewModel
        
        return HStack {
            Text("Current preset")
            Spacer()
            Picker(
                "Current preset",
                selection: Binding(
                    get: {
                        // Ensure the selected ID exists in the presets list
                        if let currentID = viewModel.state.currentPresetID,
                           viewModel.state.presets.contains(where: { $0.id == currentID }) {
                            return currentID
                        }
                        return nil
                    },
                    set: { newValue in
                        viewModel.state.currentPresetID = newValue
                    }
                )
            ) {
                Text("None").tag(nil as UUID?)
                
                ForEach(viewModel.state.presets) { preset in
                    Text(preset.name)
                        .tag(preset.id as UUID?)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // Picker for selecting transport mode (driving vs walking)
    private var transportModePicker: some View {
        @Bindable var viewModel = viewModel
        
        return HStack {
            Text("Travel mode")
            Spacer()
            Picker(
                "Transport mode",
                selection: $viewModel.state.preferredTransportMode
            ) {
                ForEach(TransportMode.allCases) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // List of saved presets. Selecting a row opens the shared form in edit mode.
    private var presetList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.state.presets) { preset in
                NavigationLink {
                    PresetFormView(
                        preset: preset,
                        onSave: { updatedPreset in
                            viewModel.savePreset(updatedPreset)
                        },
                        onDelete: { deletedPreset in
                            viewModel.deletePreset(deletedPreset)
                        }
                    )
                } label: {
                    HStack {
                        Text(preset.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                }
                
                if preset.id != viewModel.state.presets.last?.id {
                    Divider()
                        .padding(.leading, 12)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
