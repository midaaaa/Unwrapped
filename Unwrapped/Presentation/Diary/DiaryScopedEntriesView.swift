//
//  DiaryScopedEntriesView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct DiaryScopedEntriesView: View {
    let title: String
    let entries: [DiaryEntry]
    let namespace: Namespace.ID
    var onEntryTap: (DiaryEntry) -> Void = { _ in }
    var onDelete: (DiaryEntry) async -> Void = { _ in }
    var showsDeleteAction: Bool = true


    var body: some View {
        List {
            if entries.isEmpty {
                EmptyStateRow(
                    title: "No Entries",
                    systemImage: "book.closed",
                    description: Text("No diary entries match the current filters.")
                )
            } else {
                ForEach(entries) { entry in
                    if showsDeleteAction {
                        DiaryEntryRow(entry: entry, namespace: namespace, onTap: { onEntryTap(entry) })
                            .listSectionSeparator(.hidden, edges: [.top, .bottom])
                            .diaryEntrySwipeActions(entry: entry, isCompact: true) {
                                Task { await onDelete(entry) }
                            }
                    } else {
                        DiaryEntryRow(entry: entry, namespace: namespace, onTap: { onEntryTap(entry) })
                            .listSectionSeparator(.hidden, edges: [.top, .bottom])
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
