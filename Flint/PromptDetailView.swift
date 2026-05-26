//
//  PromptDetailView.swift
//  Flint
//
//  Created by Drake Bartolai on 3/3/26.
//

import Foundation
import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt
    
    var body: some View {
        ZStack {
            FlintColors.darkCharcoal.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Label(prompt.timeSlot.label, systemImage: prompt.timeSlot.systemIcon)
                        .font(.subheadline)
                        .foregroundStyle(FlintColors.mutedGray)
                    
                    Text(prompt.prompt)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(FlintColors.warmWhite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(prompt.timestamp, format: .dateTime.month(.wide).day().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(FlintColors.mutedGray)
                    
                    if let note = prompt.entry {
                        Text(note)
                            .font(.system(.body, design: .serif))
                            .foregroundColor(FlintColors.warmWhite.opacity(0.85))
                            .padding(.horizontal)
                    }
                    
                    if let imageData = prompt.imageData,
                       let uiImage = UIImage(data: imageData) {
                        VStack(spacing: 8) {
                            Text("Uploaded Image")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(FlintColors.softAmber)
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
