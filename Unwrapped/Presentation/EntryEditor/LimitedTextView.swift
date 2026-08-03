//
//  LimitedTextView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 28.07.2026.
//

import SwiftUI
import UIKit

struct LimitedTextView: UIViewRepresentable {
    @Binding var text: String
    var characterLimit: Int
    @Binding var isFocused: Bool
    var submitsOnReturn = false
    var onOverflow: () -> Void = {}
    var onReturn: () -> Void = {}
    var onHeightChange: (CGFloat) -> Void = { _ in }

    func makeUIView(context: Context) -> AutoSizingTextView {
        let textView = AutoSizingTextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.onHeightChange = onHeightChange
        return textView
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: AutoSizingTextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: height)
    }

    func updateUIView(_ uiView: AutoSizingTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.onHeightChange = onHeightChange
        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: LimitedTextView

        init(_ parent: LimitedTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            if parent.submitsOnReturn, text == "\n" {
                parent.onReturn()
                return false
            }

            let current = (textView.text ?? "") as NSString
            let updated = current.replacingCharacters(in: range, with: text)
            guard updated.count > parent.characterLimit else { return true }
            parent.onOverflow()
            return false
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }
    }
}

final class AutoSizingTextView: UITextView {
    var onHeightChange: (CGFloat) -> Void = { _ in }
    private var lastReportedHeight: CGFloat = -1

    override func layoutSubviews() {
        super.layoutSubviews()
        let fittingSize = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        guard fittingSize.height != lastReportedHeight else { return }
        lastReportedHeight = fittingSize.height
        onHeightChange(fittingSize.height)
    }
}
