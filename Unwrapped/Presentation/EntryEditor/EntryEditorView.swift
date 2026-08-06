//
//  EntryEditorView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 25.07.2026.
//

import SwiftUI

struct EntryEditorView: View {
    @Bindable var viewModel: EntryEditorViewModel
    let onSave: () -> Void
    var onDelete: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardConfirmation = false

    private enum Field: Hashable { case body }
    @FocusState private var focusedField: Field?

    @State private var isTitleFocused = false
    @State private var titleHeight: CGFloat = EntryEditorView.lineHeight

    private static let lineHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight
    private static let titleMinHeight = lineHeight
    private static let titleMaxHeight = lineHeight * 3 + 6

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecondsRulerPicker(
                        progressMs: $viewModel.progressMs,
                        durationMs: viewModel.pickableDurationMs
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                switch viewModel.currentKind {
                case .quickTap:
                    reactionSection
                case .detailed:
                    detailedSection
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("UNWRAP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    deleteButton
                }

                if viewModel.showsToggle {
                    ToolbarItem(placement: .topBarLeading) {
                        toggleButton
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    confirmButton
                }
            }
            .errorAlert("Couldn't save entry", message: $viewModel.errorMessage)
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .background(
            DismissAttemptDetector { showDiscardConfirmation = true }
        )
        .alert(
            "You have unsaved changes",
            isPresented: $showDiscardConfirmation
        ) {
            Button("Save") {
                Task {
                    await viewModel.save()
                    if viewModel.errorMessage == nil {
                        onSave()
                        dismiss()
                    }
                }
            }
            .disabled(viewModel.isEmpty)
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Toolbar buttons

    private var deleteButton: some View {
        Menu {
            Text(viewModel.canDelete ? "Delete this entry?" : "Discard without saving?")

            Button(role: .destructive) {
                guard viewModel.canDelete else {
                    dismiss()
                    return
                }
                Task {
                    await viewModel.delete()
                    if viewModel.errorMessage == nil {
                        onDelete()
                        dismiss()
                    }
                }
            } label: {
                Label(viewModel.canDelete ? "Delete" : "Discard", systemImage: "trash")
            }

            Button(role: .cancel) {} label: {
                Label("Cancel", systemImage: "xmark")
            }
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
        .menuIndicator(.hidden)
    }

    private var toggleButton: some View {
        Button {
            withAnimation {
                viewModel.toggleKind()
            }
        } label: {
            Image(systemName: toggleIconName)
                .contentTransition(.symbolEffect(.replace))
        }
    }

    private var toggleIconName: String {
        viewModel.currentKind == .quickTap ? "scribble" : "sparkles"
    }

    private var confirmIconName: String {
        viewModel.currentKind == .quickTap ? "checkmark" : "scribble"
    }

    private var confirmButton: some View {
        Button(role: .confirm) {
            Task {
                await viewModel.save()
                if viewModel.errorMessage == nil {
                    onSave()
                    dismiss()
                }
            }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: confirmIconName)
            }
        }
        .disabled(viewModel.isSaving || viewModel.isEmpty)
    }

    // MARK: - Reaction section

    private var reactionSection: some View {
        Section {
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(MoodTag.allCases, id: \.self) { tag in
                    reactionChip(for: tag)
                }
            }
            .padding(12)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func reactionChip(for tag: MoodTag) -> some View {
        MoodTagChip(tag: tag, isSelected: viewModel.selectedReactionTag == tag) {
            viewModel.selectReactionTag(tag)
        }
    }

    // MARK: - Detailed section

    private var detailedSection: some View {
        Section {
            growingField(
                text: $viewModel.title,
                placeholder: "Title",
                onOverflow: { viewModel.titleOverflowTrigger += 1 },
                onReturn: {
                    isTitleFocused = false
                    focusedField = .body
                }
            )
            .modifier(ShakeEffect(shakes: viewModel.titleOverflowTrigger))
            .sensoryFeedback(.error, trigger: viewModel.titleOverflowTrigger)

            TextField("Add a note...", text: $viewModel.body, axis: .vertical)
                .lineLimit(3...)
                .focused($focusedField, equals: .body)
        } header: {
            let remaining = viewModel.titleRemaining
            let isVisible = remaining <= 10
            Text(isVisible ? "\(remaining)" : " ")
                .font(.caption2)
                .opacity(isVisible ? 1 : 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func growingField(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        onOverflow: @escaping () -> Void,
        onReturn: @escaping () -> Void
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color(.placeholderText))
                    .allowsHitTesting(false)
            }

            LimitedTextView(
                text: text,
                characterLimit: EntryEditorViewModel.titleCharacterLimit,
                isFocused: $isTitleFocused,
                submitsOnReturn: true,
                onOverflow: onOverflow,
                onReturn: onReturn,
                onHeightChange: { measured in
                    titleHeight = min(max(measured, Self.titleMinHeight), Self.titleMaxHeight)
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: titleHeight)
        }
    }
}

private struct ShakeEffect: ViewModifier {
    let shakes: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat.zero, trigger: shakes) { view, offset in
            view.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-6, duration: 0.05)
                CubicKeyframe(6, duration: 0.1)
                CubicKeyframe(-4, duration: 0.1)
                CubicKeyframe(0, duration: 0.05)
            }
        }
    }
}

#if DEBUG
#Preview("Create (detailed)") {
    EntryEditorView(
        viewModel: EntryEditorViewModel(
            track: .preview,
            mode: .create(initialProgressMs: 60000),
            diaryRepository: PreviewDiaryRepository()
        ),
        onSave: {}
    )
}

#Preview("Edit reaction") {
    EntryEditorView(
        viewModel: EntryEditorViewModel(
            track: .preview,
            mode: .edit(DiaryEntry.previewEntriesForCurrentTrack[0]),
            diaryRepository: PreviewDiaryRepository()
        ),
        onSave: {}
    )
}

#Preview("Edit detailed entry") {
    EntryEditorView(
        viewModel: EntryEditorViewModel(
            track: .preview,
            mode: .edit(DiaryEntry.previewEntriesForCurrentTrack[1]),
            diaryRepository: PreviewDiaryRepository()
        ),
        onSave: {}
    )
}
#endif
