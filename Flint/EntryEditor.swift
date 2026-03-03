//
//  EntryEditor.swift
//  Flint
//
//  Created by Drake Bartolai on 3/3/26.
//

import Foundation
import SwiftUI

struct EntryEditor: View {
    @Bindable var prompt: Prompt
    @FocusState private var isFocused: Bool
    
    private var noteBinding: Binding<String> {
        Binding(
            get: { prompt.entry ?? "" },
            set: { prompt.entry = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: noteBinding)
                .font(.system(.body, design: .serif))
                .foregroundColor(FlintColors.warmWhite)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: 36, maxHeight: 180)
                .fixedSize(horizontal: false, vertical: true)
            
            if (prompt.entry ?? "").isEmpty {
                Text("What's on your mind...")
                    .font(.system(.body, design: .serif))
                    .foregroundColor(FlintColors.mutedGray.opacity(0.6))
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding(12)
        .background(FlintColors.darkCharcoal)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? FlintColors.warmAmber.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
