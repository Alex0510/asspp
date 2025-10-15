//
//  AppPackageArchive.swift
//  Asspp
//
//  Created by luca on 15.09.2025.
//

import ApplePackage
import Foundation
import OrderedCollections

@MainActor
class AppPackageArchive: ObservableObject {
    let accountIdentifier: String?
    let region: String

    @Published
    var package: AppStore.AppPackage

    typealias VersionIdentifier = String
    @PublishedPersist
    var versionIdentifiers: [VersionIdentifier]
    @PublishedPersist
    var versionItems: OrderedDictionary<VersionIdentifier, VersionMetadata>

    var isVersionItemsFullyLoaded: Bool {
        assert(versionItems.count <= versionIdentifiers.count)
        return versionItems.count == versionIdentifiers.count
    }

    @Published var error: String?
    @Published var loading = false
    @Published var shouldDismiss = false

    init(accountID: String?, region: String, package: AppStore.AppPackage) {
        accountIdentifier = accountID
        self.region = region
        _package = .init(initialValue: package)

        let packageIdentifier = [package.id, package.software.bundleID.lowercased(), region]
            .joined()
            .lowercased()
        _versionItems = .init(key: "\(packageIdentifier).versions", defaultValue: [:])
        _versionIdentifiers = .init(key: "\(packageIdentifier).versionNumbers", defaultValue: [])
    }

    func package(for externalVersion: String) -> AppStore.AppPackage? {
        if let metadata = versionItems[externalVersion] {
            var pkg = package
            pkg.software.version = metadata.displayVersion
            pkg.externalVersionID = externalVersion
            return pkg
        } else {
            return nil
        }
    }

    func clearVersionItems() {
        assert(!loading)
        error = nil
        versionIdentifiers = []
        versionItems.removeAll()
    }

    func populateVersionIdentifiers(_ completion: (() async -> Void)? = nil) {
        guard let accountIdentifier, !loading else { return }
        let bundleID = package.software.bundleID
        loading = true
        error = nil

        Task.detached {
            do {
                let versions = try await AppStore.this.withAccount(id: accountIdentifier) { userAccount in
                    try await VersionFinder.list(account: &userAccount.account, bundleIdentifier: bundleID)
                }
                await MainActor.run { self.versionIdentifiers = versions.reversed() }
            } catch {
                await MainActor.run {
                    if case .licenseRequired = error as? ApplePackageError {
                        self.shouldDismiss = true
                    }
                    self.error = error.localizedDescription
                }
            }
            await MainActor.run { self.loading = false }
            await completion?()
        }
    }

    func populateNextVersionItems(count: Int = 3) {
        guard let accountIdentifier, !loading, !isVersionItemsFullyLoaded else { return }
        loading = true
        error = nil

        Task.detached {
            do {
                for _ in 0 ..< count where await !self.isVersionItemsFullyLoaded {
                    let nextIdx = await self.versionItems.count
                    let version = await self.versionIdentifiers[nextIdx]
                    let app = await self.package.software

                    let metadata = try await AppStore.this.withAccount(id: accountIdentifier) { userAccount in
                        try await VersionLookup.getVersionMetadata(account: &userAccount.account, app: app, versionID: version)
                    }
                    await MainActor.run { self.versionItems[version] = metadata }
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
            await MainActor.run { self.loading = false }
        }
    }

    func populateVersionItem(for versionID: String) {
        guard let accountIdentifier, !loading, versionIdentifiers.contains(versionID), versionItems[versionID] == nil else { return }
        loading = true
        error = nil

        Task.detached {
            do {
                let app = await self.package.software
                let metadata = try await AppStore.this.withAccount(id: accountIdentifier) { userAccount in
                    try await VersionLookup.getVersionMetadata(account: &userAccount.account, app: app, versionID: versionID)
                }
                await MainActor.run { self.versionItems[versionID] = metadata }
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
            await MainActor.run { self.loading = false }
        }
    }
}

@MainActor
extension AppPackageArchive {
    var version: String { package.software.version }

    var releaseDate: Date? { package.releaseDate }

    var releaseNotes: String? { package.software.releaseNotes }

    var formattedPrice: String { package.software.formattedPrice }

    var price: Double? { package.software.price }

    var downloadOutput: DownloadOutput? {
        get { package.downloadOutput }
        set { package.downloadOutput = newValue }
    }
}
