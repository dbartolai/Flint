//
//  CompleteFlowSheet.swift
//  Flint
//

import Foundation
import SwiftUI
import PhotosUI

struct CompleteFlowSheet: View {
    @Bindable var prompt: Prompt
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showCamera: Bool = false
    @State private var sheetHeight: CGFloat = 0

    
    private var dayAndSlot: String {
        let dayOfWeek = prompt.timestamp.formatted(.dateTime.weekday(.wide))
        return "\(dayOfWeek) \(prompt.timeSlot.label)"
    }
    
    private struct SheetHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Capsule()
                    .fill(FlintColors.mutedGray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                Label(dayAndSlot, systemImage: prompt.timeSlot.systemIcon)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(FlintColors.warmWhite)
                    .padding(.top, 4)
                
                // Optional in-app note
                EntryEditor(prompt: prompt)
                    .padding(.horizontal)
                
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                
                // Camera and photo picker side by side
                HStack(spacing: 12) {
                    Button(action: { showCamera = true }) {
                        Label("Take Photo", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(FlintColors.warmWhite)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(FlintColors.warmWhite.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Upload Photo", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(FlintColors.warmWhite)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(FlintColors.warmWhite.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Button(action: complete) {
                    Label("Mark Complete", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(FlintColors.charcoal)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(FlintColors.warmAmber)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(FlintColors.softAmber.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                
                Spacer().frame(height: 8)
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: SheetHeightKey.self,
                        value: geo.size.height
                    )
                }
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FlintColors.darkCharcoal)
        .onPreferenceChange(SheetHeightKey.self) { height in
            sheetHeight = height
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(FlintColors.darkCharcoal)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { data in
                previewImage = UIImage(data: data)
                prompt.imageData = data
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    previewImage = UIImage(data: data)
                    prompt.imageData = data
                }
            }
        }
    }
    
    private func complete() {
        prompt.completed = true
        dismiss()
    }
}
