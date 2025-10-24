//
//  AuthenticateTests.swift
//  ApplePackage
//
//  Created by qaq on 9/14/25.
//

import AppKit
@testable import ApplePackage
import XCTest

private var account: String = ""
private var password: String = ""
private var code: String = ""
private(set) var testAccountEmail: String = ""

private func updateTestAccountInfo() {
    account = try! String(contentsOfFile: "/tmp/applepackage/account.txt").trimmingCharacters(in: .whitespacesAndNewlines)
    password = try! String(contentsOfFile: "/tmp/applepackage/password.txt").trimmingCharacters(in: .whitespacesAndNewlines)
    code = try! String(contentsOfFile: "/tmp/applepackage/code.txt").trimmingCharacters(in: .whitespacesAndNewlines)
    print("testing with account: \(account)")
}

final class ApplePackageAuthenticateTests: XCTestCase {
    override class func setUp() {
        updateTestAccountInfo()
        testAccountEmail = account
    }

    @MainActor func testLogin() async throws {
        // we dont do this test fequently to avoid triggering too many 2FA requests
        // thus if file at /tmp/applepackage/login_account.txt exists, we skip this test
        let fileManager = FileManager.default
        let loginAccountPath = "/tmp/applepackage/login_account.txt"
        if fileManager.fileExists(atPath: loginAccountPath) {
            print("login account file exists at \(loginAccountPath), skipping login test")
            try await withAccount(email: testAccountEmail) { account in
                try await Authenticator.rotatePasswordToken(for: &account)
            }
            return
        }

        do {
            let result = try await Authenticator.authenticate(email: account, password: password, code: code)
            print(result)
            saveLoginAccount(result, for: account)
        } catch {
            print("[?] first attempt failed: \(error)")
            let alert = NSAlert()
            alert.messageText = "Apple Package Auth Failed"
            alert.informativeText = "Please fill out the verification code you received on your device."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            updateTestAccountInfo()
            XCTAssert(!code.isEmpty)
            print("retrying with code: \(code)")
            do {
                let result = try await Authenticator.authenticate(email: account, password: password, code: code)
                print(result)
                saveLoginAccount(result, for: account)
            } catch {
                XCTFail("second attempt failed: \(error)")
            }
        }
    }
}
