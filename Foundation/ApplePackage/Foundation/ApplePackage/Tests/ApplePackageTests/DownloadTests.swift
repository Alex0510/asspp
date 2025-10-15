//
//  DownloadTests.swift
//  ApplePackage
//
//  Created by qaq on 9/15/25.
//

import AppKit
@testable import ApplePackage
import XCTest

final class ApplePackageDownloadTests: XCTestCase {
    @MainActor func testDownloadWithVersion() async throws {
        let testBundleID = "as.wiki.qaq.kimis"
        let testVersionID = "856026291"
        do {
            try await withAccount(email: testAccountEmail) { account in
                try await Authenticator.rotatePasswordToken(for: &account)
                let app = try await Lookup.lookup(bundleID: testBundleID, countryCode: "US")
                let output = try await Download.download(account: &account, app: app, externalVersionID: testVersionID)
                print("download with version test passed: \(output.downloadURL)")
                print("    Bundle Short Version: \(output.bundleShortVersionString)")
                print("    Bundle Version: \(output.bundleVersion)")
                print("    SINFs count: \(output.sinfs.count)")

                XCTAssertFalse(output.downloadURL.isEmpty, "Download URL should not be empty")
                XCTAssertNotNil(output.bundleShortVersionString, "Bundle short version should not be nil")
                XCTAssertGreaterThan(output.sinfs.count, 0, "Should have at least one SINF")
            }
        } catch {
            XCTFail("download with version test failed: \(error)")
        }
    }
}
