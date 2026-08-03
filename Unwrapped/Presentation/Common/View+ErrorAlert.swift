//
//  View+ErrorAlert.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import SwiftUI

extension View {
    func errorAlert(_ title: LocalizedStringKey, message: Binding<String?>) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("OK") { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
