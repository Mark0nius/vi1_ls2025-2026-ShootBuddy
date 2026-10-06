//
//  SpotAddView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//

import SwiftUI
import PhotosUI
import UIKit

struct SpotAddView: View {
    @Bindable private var viewModel: SpotAddViewModel
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    init(viewModel: SpotAddViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                titleField
                addressFields
                lightConditionsSection
                photoSection
                noteField
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .alert(
            "Could not save spot",
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.state.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK") {
                viewModel.state.errorMessage = nil
            }
        } message: {
            Text(viewModel.state.errorMessage ?? "")
        }
    }

    // MARK: - Fields

    private var titleField: some View {
        @Bindable var viewModel = viewModel

        return textFieldRow(
            title: "Title",
            text: $viewModel.state.name,
            required: true
        )
        .backgroundField(cornerRadius: 8)
    }

    private var addressFields: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 0) {
            textFieldRow(
                title: "Street",
                text: $viewModel.state.street,
                required: true
            )

            Divider()

            textFieldRow(
                title: "House number",
                text: $viewModel.state.houseNumber,
                required: true,
                keyboard: .numbersAndPunctuation
            )

            Divider()

            textFieldRow(
                title: "Orientational number",
                text: $viewModel.state.orientationalNumber,
                keyboard: .numbersAndPunctuation
            )

            Divider()

            textFieldRow(
                title: "City",
                text: $viewModel.state.city,
                required: true
            )
        }
        .backgroundField(cornerRadius: 8)
    }

    private func textFieldRow(
        title: String,
        text: Binding<String>,
        required: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                HStack(spacing: 0) {
                    Text(title)
                        .foregroundStyle(Color.secondary.opacity(0.75))

                    if required {
                        Text("*")
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .allowsHitTesting(false)
            }

            TextField("", text: text)
                .foregroundStyle(.primary)
                .keyboardType(keyboard)
                .padding(.horizontal, 16)
        }
        .frame(height: 44)
    }

    // MARK: - Light conditions

    private var lightConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text("Light conditions")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.75))

                Text("*")
                    .foregroundStyle(.blue)

                Spacer()
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(LightType.allCases) { light in
                    lightConditionButton(light)
                }
            }
        }
        .padding(16)
        .backgroundField(cornerRadius: 8)
    }

    private func lightConditionButton(_ light: LightType) -> some View {
        let isSelected = viewModel.state.selectedLightConditions.contains(light)

        return Button {
            viewModel.toggleLightCondition(light)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: light.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        isSelected
                            ? light.color
                            : Color.primary.opacity(0.55)
                    )
                    .frame(width: 26, height: 26)
                    .background {
                        Circle()
                            .stroke(
                                isSelected
                                    ? light.color
                                    : Color.primary.opacity(0.18),
                                lineWidth: 1.5
                            )
                    }

                Text(light.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? Color.primary
                            : Color.primary.opacity(0.65)
                    )
                    .lineLimit(1)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(light.color)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? light.color.opacity(0.14)
                            : Color(.systemGray6)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? light.color.opacity(0.8)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photos

    private var photoSection: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.state.photos) { photo in
                photoPreview(photo)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                Divider()
            }

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 6,
                matching: .images
            ) {
                HStack {
                    Text("Add photo...")
                        .foregroundStyle(Color.secondary.opacity(0.75))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 58)
            }
            .buttonStyle(.plain)
        }
        .backgroundField(cornerRadius: 8)
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await viewModel.addPhotos(from: newItems)
                selectedPhotoItems.removeAll()
            }
        }
    }

    private func photoPreview(_ photo: Photo) -> some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 195)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray4))
                    .frame(height: 195)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
            }

            Button {
                viewModel.removePhoto(photo)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.red.opacity(0.75)))
            }
            .buttonStyle(.plain)
            .padding(8)
        }
    }

    // MARK: - Note

    private var noteField: some View {
        @Bindable var viewModel = viewModel

        return ZStack(alignment: .topLeading) {
            if viewModel.state.note.isEmpty {
                Text("Add note...")
                    .foregroundStyle(Color.secondary.opacity(0.75))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $viewModel.state.note)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
        }
        .frame(minHeight: 94)
        .backgroundField(cornerRadius: 8)
    }
}

// MARK: - Field background

private extension View {
    func backgroundField(cornerRadius: CGFloat) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemGray5))
        )
    }
}

#Preview {
    NavigationStack {
        SpotAddView(viewModel: SpotAddViewModel())
            .navigationTitle("New Spot")
            .navigationBarTitleDisplayMode(.inline)
    }
}
