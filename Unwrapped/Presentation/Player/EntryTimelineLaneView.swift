//
//  EntryTimelineLaneView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import SwiftUI

struct EntryTimelineLaneView: View {
    let entries: [DiaryEntry]
    let activeCardWindowSeconds: Int
    let isLive: Bool
    let progressAnchor: PlaybackProgressAnchor?
    let outerHorizontalPadding: CGFloat
    let screenWidth: CGFloat
    let onTapEntry: (DiaryEntry) -> Void

    @State private var laneScrollPosition: DiaryEntry.ID?
    @State private var isLaneUserControlled = false
    @State private var laneResumeTask: Task<Void, Never>?
    @State private var computedActiveEntryID: DiaryEntry.ID?

    private static let activeEntryTickInterval: TimeInterval = 0.2
    private static let entryCardSpacing: CGFloat = 8
    private static let entryCardContentMinHeight: CGFloat = 72
    private static let entryCardShape = RoundedRectangle(cornerRadius: 14, style: .continuous)
    private static let laneSnapAnimation: Animation = .easeOut(duration: 0.5)
    private static let laneSnapMinimumRemainingMs = 500
    private static let laneAutoScrollResumeDelay: TimeInterval = 1
    private static let entryCardMaxWidthFraction: CGFloat = 0.9

    private var entryCardMaxWidth: CGFloat {
        (screenWidth - outerHorizontalPadding * 2) * Self.entryCardMaxWidthFraction
    }

    var body: some View {
        lane(activeEntryID: isLive ? computedActiveEntryID : nil)
            .background { activeEntryUpdater }
            .fixedSize(horizontal: false, vertical: true)
            .stableFullWidth()
            .padding(.horizontal, -outerHorizontalPadding)
    }

    @ViewBuilder
    private var activeEntryUpdater: some View {
        if isLive, let progressAnchor {
            TimelineView(.periodic(from: .now, by: Self.activeEntryTickInterval)) { context in
                Color.clear
                    .onChange(of: context.date, initial: true) { _, date in
                        let progressMs = progressAnchor.progressMs(at: date)
                        let newActiveID = TimelineActiveEntryResolver.activeEntryID(
                            in: entries,
                            atProgressMs: progressMs,
                            windowMs: activeCardWindowSeconds * 1_000
                        )
                        if computedActiveEntryID != newActiveID {
                            computedActiveEntryID = newActiveID
                        }
                    }
            }
        }
    }

    private func lane(activeEntryID: DiaryEntry.ID?) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Self.entryCardSpacing) {
                ForEach(entries) { entry in
                    entryCard(entry, isActive: entry.id == activeEntryID)
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .contentMargins(.horizontal, outerHorizontalPadding, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .scrollPosition(id: $laneScrollPosition, anchor: .leading)
        .onScrollPhaseChange { oldPhase, newPhase in
            handleScrollPhaseChange(from: oldPhase, to: newPhase)
        }
        .onChange(of: activeEntryID, initial: true) { _, newActiveID in
            guard !isLaneUserControlled, let newActiveID else { return }
            snapLane(to: newActiveID)
        }
    }

    private func snapLane(to id: DiaryEntry.ID) {
        laneScrollPosition = nil
        Task { @MainActor in
            guard !isLaneUserControlled else { return }
            withAnimation(Self.laneSnapAnimation) {
                laneScrollPosition = id
            }
        }
    }

    private func handleScrollPhaseChange(from oldPhase: ScrollPhase, to newPhase: ScrollPhase) {
        switch newPhase {
        case .tracking, .interacting:
            isLaneUserControlled = true
            laneResumeTask?.cancel()
        default:
            guard oldPhase == .tracking || oldPhase == .interacting else { return }
            scheduleAutoScrollResume()
        }
    }

    private func scheduleAutoScrollResume() {
        laneResumeTask?.cancel()
        laneResumeTask = Task {
            try? await Task.sleep(for: .seconds(Self.laneAutoScrollResumeDelay))
            guard !Task.isCancelled else { return }
            isLaneUserControlled = false

            guard let progressAnchor else { return }
            let progressMs = progressAnchor.progressMs(at: Date())
            guard let active = TimelineActiveEntryResolver.activeEntry(
                in: entries,
                atProgressMs: progressMs,
                windowMs: activeCardWindowSeconds * 1_000
            ) else { return }
            guard active.remainingMs >= Self.laneSnapMinimumRemainingMs else { return }

            snapLane(to: active.id)
        }
    }

    private func entryCard(_ entry: DiaryEntry, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(formatPlaybackTime(ms: roundedToNearestSecond(ms: entry.progressMs ?? 0)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Image(systemName: entry.engagementLevel == .detailed ? "text.bubble.fill" : "sparkles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.engagementLevel == .detailed {
                let hasTags = !entry.tags.isEmpty
                let text = entry.titleOrNoteHeading ?? ""
                let hasText = !text.isEmpty
                let isSingleField = hasTags != hasText

                VStack(alignment: .leading, spacing: 6) {
                    if hasTags {
                        HStack(spacing: 4) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag.emoji)
                                    .font(isSingleField ? .largeTitle : .title2)
                            }
                        }
                    }

                    if hasText {
                        Text(text)
                            .font(isSingleField ? .headline : .callout)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: Self.entryCardContentMinHeight,
                    alignment: isSingleField ? .center : .topLeading
                )
            } else if let reactionEmoji = entry.tags.first?.emoji {
                Text(reactionEmoji)
                    .font(.system(size: 50))
                    .frame(maxWidth: .infinity, minHeight: Self.entryCardContentMinHeight)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minWidth: 96, maxWidth: entryCardMaxWidth)
        .background(.secondary.opacity(isActive ? 0.22 : 0.1), in: Self.entryCardShape)
        .overlay {
            Self.entryCardShape.strokeBorder(.tint, lineWidth: isActive ? 2 : 0)
        }
        .animation(.easeInOut(duration: 0.25), value: isActive)
        .onTapGesture {
            onTapEntry(entry)
        }
    }
}
