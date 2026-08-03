//
//  DiaryMoodTagFilterSheet.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct DiaryMoodTagFilterSheet: View {
    @Binding var selectedTags: Set<MoodTag>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(MoodTag.allCases, id: \.self) { tag in
                        chip(for: tag)
                    }
                }
                .padding()
            }
            .navigationTitle("Mood Tags")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { selectedTags = [] }
                        .disabled(selectedTags.isEmpty)
                }
            }
        }
    }

    private func chip(for tag: MoodTag) -> some View {
        MoodTagChip(tag: tag, isSelected: selectedTags.contains(tag)) {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }
    }
}

#if DEBUG
#Preview {
    DiaryMoodTagFilterSheet(selectedTags: .constant([.happy, .energetic]))
}
#endif
