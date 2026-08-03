//
//  PKCE.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import CryptoKit
import Foundation
import Security

enum PKCE {
    static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed with status \(status)")
        return Data(bytes).base64UrlEncodedString()
    }

    static func generateCodeChallenge(from verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64UrlEncodedString()
    }
}

private extension Data {
    func base64UrlEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
