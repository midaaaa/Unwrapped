//
//  FlowLayout.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 25.07.2026.
//

import SwiftUI

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrangeRows(subviews: subviews, maxWidth: maxWidth)

        let height = rows.reduce(CGFloat.zero) { partialHeight, row in
            partialHeight + row.height + (partialHeight > 0 ? verticalSpacing : 0)
        }
        let width = rows.map(\.width).max() ?? 0

        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeRows(subviews: subviews, maxWidth: bounds.width)

        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    // MARK: - Раскладка по строкам (общая для sizeThatFits и placeSubviews)

    private struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct Row {
        let items: [RowItem]
        let height: CGFloat
        let width: CGFloat
    }

    private func arrangeRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentItems: [RowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        func flushRow() {
            guard !currentItems.isEmpty else { return }
            rows.append(Row(items: currentItems, height: currentHeight, width: currentWidth))
            currentItems = []
            currentWidth = 0
            currentHeight = 0
        }

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let widthNeeded = currentWidth + (currentItems.isEmpty ? 0 : horizontalSpacing) + size.width

            if widthNeeded > maxWidth, !currentItems.isEmpty {
                flushRow()
            }

            currentWidth += (currentItems.isEmpty ? 0 : horizontalSpacing) + size.width
            currentHeight = max(currentHeight, size.height)
            currentItems.append(RowItem(subview: subview, size: size))
        }
        flushRow()

        return rows
    }
}
