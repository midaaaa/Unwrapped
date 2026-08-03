//
//  SecondsRulerPicker.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 25.07.2026.
//

import SwiftUI

private struct SnapAnimation {
    let startProgressMs: Double
    let targetProgressMs: Double
    let startTime: Date
    let duration: TimeInterval

    func progressMs(at date: Date) -> Double {
        let t = min(max(date.timeIntervalSince(startTime) / duration, 0), 1)
        let eased = 1 - pow(1 - t, 3)
        return startProgressMs + (targetProgressMs - startProgressMs) * eased
    }

    func isFinished(at date: Date) -> Bool {
        date.timeIntervalSince(startTime) >= duration
    }
}

struct SecondsRulerPicker: View {
    @Binding var progressMs: Int
    let durationMs: Int

    @AppStorage(AppSettingsKeys.rulerHapticFeedback) private var isHapticFeedbackEnabled = true

    private let secondWidth: CGFloat = 8
    private let minorTickHeight: CGFloat = 10
    private let mediumTickHeight: CGFloat = 15
    private let majorTickHeight: CGFloat = 20
    private let majorTickEverySeconds = 10

    private let rulerHeight: CGFloat = 140 * 2 / 3
    private let trackInset: CGFloat = 10
    private static let coastFriction: Double = 4
    private static let flingVelocityThreshold: Double = 40
    private static let touchFadeDuration: TimeInterval = 0.6
    private static let hitboxWidthPoints: CGFloat = 1

    @State private var dragStartProgressMs: Int?
    @State private var snapAnimation: SnapAnimation?
    @State private var touchedAt: [Int: Date] = [:]
    @State private var activeTick: Int?

    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { trackGeo in
                ruler(size: trackGeo.size, now: context.date)
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .frame(width: 2, height: majorTickHeight + 12)
                    }
                    .contentShape(Rectangle())
                    .gesture(dragGesture)
            }
            .padding(trackInset)
            .onChange(of: context.date) { _, date in
                advanceSnapAnimation(at: date)
            }
        }
        .frame(height: rulerHeight)
        .glassEffect(.clear)
        .overlay(alignment: .top) {
            currentTimeLabel
                .padding(.top, 14)
        }
        .sensoryFeedback(.selection, trigger: nearestSecond(progressMs)) { _, _ in isHapticFeedbackEnabled }
    }

    private var currentTimeLabel: some View {
        let currentSecond = nearestSecond(progressMs)

        return Text(formatPlaybackTime(ms: currentSecond * 1_000))
            .font(.callout.monospacedDigit().bold())
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.25), value: currentSecond)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .glassEffect(.clear.tint(Color.blue), in: Capsule())
    }

    private func ruler(size: CGSize, now: Date) -> some View {
        let totalSeconds = max(0, durationMs / 1_000)
        let r = size.height / 2

        return Canvas { context, canvasSize in
            let horizontalLen = max(0, canvasSize.width - r * 2)
            let arcLen = (CGFloat.pi / 2) * r
            let totalLength = arcLen * 4 + horizontalLen
            guard totalLength > 0, r > 0 else { return }

            func pointAndTangentAngle(atArcLength s: CGFloat) -> (CGPoint, CGFloat) {
                let leftArcEnd = arcLen * 2
                let lineEnd = leftArcEnd + horizontalLen

                if s < leftArcEnd {
                    let theta = -CGFloat.pi / 2 - s / r
                    let point = CGPoint(x: r + r * cos(theta), y: r + r * sin(theta))
                    return (point, atan2(-cos(theta), sin(theta)))
                } else if s < lineEnd {
                    let point = CGPoint(x: r + (s - leftArcEnd), y: 2 * r)
                    return (point, 0)
                } else {
                    let theta = CGFloat.pi / 2 - (s - lineEnd) / r
                    let center = CGPoint(x: canvasSize.width - r, y: r)
                    let point = CGPoint(x: center.x + r * cos(theta), y: center.y + r * sin(theta))
                    return (point, atan2(-cos(theta), sin(theta)))
                }
            }

            let hookFraction = arcLen / totalLength
            let pathCenterOffset: CGFloat = 0.5
            let scrollOffset = CGFloat(progressMs) / 1_000 * secondWidth

            let visibleSecondsRange = Int(ceil(totalLength / secondWidth))
            let centerSecond = Int(floor(scrollOffset / secondWidth))
            let firstVisible = max(0, centerSecond - visibleSecondsRange)
            let lastVisible = min(totalSeconds, centerSecond + visibleSecondsRange)
            guard firstVisible <= lastVisible else { return }

            for second in firstVisible...lastVisible {
                let deltaPixels = CGFloat(second) * secondWidth - scrollOffset
                let progressOnPath = pathCenterOffset + deltaPixels / totalLength
                guard progressOnPath >= 0.0 && progressOnPath <= 1.0 else { continue }

                let (currentPoint, pathAngle) = pointAndTangentAngle(atArcLength: progressOnPath * totalLength)
                let normalAngle = pathAngle + CGFloat.pi / 2

                let isMajor = second % majorTickEverySeconds == 0
                let isMedium = !isMajor && second % 5 == 0
                let elapsedSinceTouch = touchedAt[second].map { now.timeIntervalSince($0) }
                let highlight = elapsedSinceTouch.map {
                    max(0, 1 - $0 / Self.touchFadeDuration)
                } ?? 0

                let baseHeight: CGFloat = isMajor ? majorTickHeight : (isMedium ? mediumTickHeight : minorTickHeight)
                let height = baseHeight * (1 + highlight * 0.4)
                let baseLineWidth: CGFloat = isMajor ? 1.5 : (isMedium ? 1.2 : 1.0)
                let lineWidth = baseLineWidth + highlight * 1.0
                let baseOpacity: Double = isMajor ? 0.8 : (isMedium ? 0.55 : 0.35)
                var tickColor = Color.secondary.opacity(baseOpacity).mix(with: .accentColor, by: highlight)

                if progressOnPath < hookFraction {
                    tickColor = tickColor.opacity(0.03 + 0.97 * (progressOnPath / hookFraction))
                } else if progressOnPath > 1 - hookFraction {
                    tickColor = tickColor.opacity(0.03 + 0.97 * ((1 - progressOnPath) / hookFraction))
                }

                let endPoint = CGPoint(
                    x: currentPoint.x - cos(normalAngle) * height,
                    y: currentPoint.y - sin(normalAngle) * height
                )
                var tickPath = Path()
                tickPath.move(to: currentPoint)
                tickPath.addLine(to: endPoint)
                context.stroke(
                    tickPath,
                    with: .color(tickColor),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if snapAnimation != nil { snapAnimation = nil }
                if dragStartProgressMs == nil {
                    dragStartProgressMs = progressMs
                }
                let deltaMs = Int(-value.translation.width / secondWidth * 1_000)
                let newValue = min(max((dragStartProgressMs ?? progressMs) + deltaMs, 0), durationMs)
                setProgressMs(newValue)
            }
            .onEnded { value in
                defer { dragStartProgressMs = nil }

                let velocity = -Double(value.velocity.width) / secondWidth * 1_000
                let target: Double
                let duration: TimeInterval

                if abs(velocity) > Self.flingVelocityThreshold {
                    let coastDistance = velocity / Self.coastFriction
                    target = Double(snapToSecond(progressMs, offsetMs: coastDistance))
                    duration = min(1.2, max(0.25, abs(coastDistance) / 20_000))
                } else {
                    target = Double(snapToSecond(progressMs))
                    duration = 0.2
                }

                snapAnimation = SnapAnimation(
                    startProgressMs: Double(progressMs),
                    targetProgressMs: target,
                    startTime: Date(),
                    duration: duration
                )
            }
    }

    private func advanceSnapAnimation(at date: Date) {
        guard let snapAnimation else { return }

        if snapAnimation.isFinished(at: date) {
            setProgressMs(Int(snapAnimation.targetProgressMs))
            self.snapAnimation = nil
        } else {
            setProgressMs(Int(snapAnimation.progressMs(at: date)))
        }
    }

    private func setProgressMs(_ newValue: Int) {
        guard newValue != progressMs else { return }
        markTouchedTicks(from: progressMs, to: newValue)
        progressMs = newValue
    }

    private func markTouchedTicks(from oldMs: Int, to newMs: Int) {
        let hitboxHalfWidthMs = Double(Self.hitboxWidthPoints / 2) / Double(secondWidth) * 1_000

        let lo = Double(min(oldMs, newMs)) - hitboxHalfWidthMs
        let hi = Double(max(oldMs, newMs)) + hitboxHalfWidthMs

        let firstTick = Int(ceil(lo / 1_000))
        let lastTick = Int(floor(hi / 1_000))
        guard firstTick <= lastTick else {
            activeTick = nil
            return
        }

        let newActiveTick = tick(containing: newMs, hitboxHalfWidthMs: hitboxHalfWidthMs)

        if firstTick == lastTick, firstTick == activeTick {
            activeTick = newActiveTick
            return
        }

        let now = Date()
        for second in firstTick...lastTick {
            touchedAt[second] = now
        }
        touchedAt = touchedAt.filter { now.timeIntervalSince($0.value) < Self.touchFadeDuration }
        activeTick = newActiveTick
    }

    private func tick(containing ms: Int, hitboxHalfWidthMs: Double) -> Int? {
        let candidate = nearestSecond(ms)
        let distance = abs(Double(ms) - Double(candidate) * 1_000)
        return distance <= hitboxHalfWidthMs ? candidate : nil
    }

    private func nearestSecond(_ ms: Int) -> Int {
        roundedToNearestSecond(ms: ms, clampedToDurationMs: durationMs) / 1_000
    }

    private func snapToSecond(_ ms: Int, offsetMs: Double = 0) -> Int {
        let raw = Double(ms) + offsetMs
        let seconds = (raw / 1_000).rounded()
        return min(max(Int(seconds * 1_000), 0), durationMs)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var progressMs = 90_000
    return SecondsRulerPicker(progressMs: $progressMs, durationMs: 120_000)
        .padding(.horizontal)
}
#endif
