//
//  RecapCardView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI

struct RecapCardView: View {
    let card: RecapCard
    var style: Style = .compact

    enum Style {
        case compact
        case wide
    }

    var body: some View {
        switch card {
        case .moodOfPeriod(let tag, let count, let isSameAsPrior):
            container(tint: .orange, kicker: "Top Mood", title: tag.label, subtitle: moodSubtitle(count: count, isSameAsPrior: isSameAsPrior)) {
                Text(tag.emoji).font(.title2)
            }
        case .loggingTrend(let count, let deltaPercent):
            container(tint: .blue, kicker: "Logging Activity", title: String(localized: "\(count) entries"), subtitle: trendSubtitle(deltaPercent)) {
                Image(systemName: "chart.bar.fill").font(.title3)
            }
        case .climbing(_, let name, let fromRank, let toRank):
            container(tint: .green, kicker: "Climbing Fast", title: name, subtitle: "#\(fromRank) → #\(toRank)") {
                Image(systemName: "arrow.up.forward").font(.title3)
            }
        case .newFavorite(_, let name, let rank):
            container(tint: .purple, kicker: "New Favorite", title: name, subtitle: String(localized: "#\(rank) this period")) {
                Image(systemName: "laurel.leading.laurel.trailing").font(.title3)
            }
        case .topTrackHighlight(let trackName, let artistName, let count):
            container(tint: .pink, kicker: "Most Logged", title: trackName, subtitle: topTrackSubtitle(artistName: artistName, count: count)) {
                Image(systemName: "music.note").font(.title3)
            }
        case .streak(let days):
            container(tint: .red, kicker: "Streak", title: String(localized: "\(days) days"), subtitle: String(localized: "Keep it going")) {
                Image(systemName: "flame.fill").font(.title3)
            }
        case .activeDay(let weekday, let count):
            container(tint: .teal, kicker: "Active Day", title: weekday, subtitle: String(localized: "\(count) entries")) {
                Image(systemName: "calendar").font(.title3)
            }
        case .engagementMix(let detailedPercent):
            container(tint: .indigo, kicker: "Engagement", title: "\(detailedPercent)%", subtitle: String(localized: "Detailed Entries")) {
                Image(systemName: "square.text.square").font(.title3)
            }
        }
    }

    @ViewBuilder
    private func container(
        tint: Color,
        kicker: LocalizedStringResource,
        title: String,
        subtitle: String,
        @ViewBuilder leading: () -> some View
    ) -> some View {
        Group {
            switch style {
            case .compact:
                VStack(alignment: .leading, spacing: 6) {
                    leading()
                        .foregroundStyle(tint)

                    Spacer(minLength: 0)

                    Text(kicker)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(verbatim: title)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(verbatim: subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
            case .wide:
                HStack(spacing: 14) {
                    leading()
                        .foregroundStyle(tint)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(kicker)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(verbatim: title)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(verbatim: subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
            }
        }
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func moodSubtitle(count: Int, isSameAsPrior: Bool) -> String {
        isSameAsPrior ? String(localized: "Still your top mood") : String(localized: "\(count) entries")
    }

    private func topTrackSubtitle(artistName: String, count: Int) -> String {
        "\(artistName) · \(count)"
    }

    private func trendSubtitle(_ delta: Int?) -> String {
        guard let delta else { return String(localized: "First recap for this period") }
        guard delta != 0 else { return String(localized: "Same as last period") }
        let sign = delta > 0 ? "+" : ""
        let percentText = "\(sign)\(delta)%"
        return String(localized: "\(percentText) vs last period")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        RecapCardView(card: .climbing(kind: .track, name: "Nightcall", fromRank: 8, toRank: 2), style: .wide)
        HStack(spacing: 12) {
            RecapCardView(card: .moodOfPeriod(tag: .happy, count: 6, isSameAsPrior: false))
            RecapCardView(card: .loggingTrend(count: 12, deltaPercent: 25))
        }
        RecapCardView(card: .newFavorite(kind: .artist, name: "Fred Again..", rank: 3), style: .wide)
        HStack(spacing: 12) {
            RecapCardView(card: .streak(days: 5))
            RecapCardView(card: .activeDay(weekday: "Friday", count: 4))
        }
        RecapCardView(card: .engagementMix(detailedPercent: 60))
    }
    .padding()
}
#endif
