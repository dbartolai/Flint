//
//  PhotoPicker.swift
//  Flint
//
//  Created by Drake Bartolai on 3/3/26.
//

import Foundation
import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Bindable var prompt: Prompt
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Label("Add Photo", systemImage: "camera")
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    prompt.imageData = data
                    prompt.completed = true
                }
            }
        }
    }
}
