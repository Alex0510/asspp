//
//  AppStore.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Combine
import Foundation

class AppStore: ObservableObject {
    var cancellables: Set<AnyCancellable> = .init()

    @MainActor
    @PublishedPersist(
        key: "Accounts",
        defaultValue: [],
        keychain: "wiki.qaq.Asspp.Accounts"
    )
    var accounts: [UserAccount]

    @MainActor
    @PublishedPersist(key: "DemoMode", defaultValue: false)
    var demoMode: Bool

    static let this = AppStore()
    private init() {}

    @MainActor
    @discardableResult
    func save(email: String, account: ApplePackage.Account) -> UserAccount {
        let account = UserAccount(account: account)
        accounts = (accounts.filter { $0.account.email != email } + [account])
            .sorted { $0.account.email < $1.account.email }
        return account
    }

    @MainActor
    func delete(id: UserAccount.ID) {
        accounts = accounts.filter { $0.id != id }
    }

    @MainActor
    var possibleRegions: Set<String> {
        Set(accounts.compactMap { ApplePackage.Configuration.countryCode(for: $0.account.store) })
    }

    @MainActor
    func eligibleAccounts(for region: String) -> [UserAccount] {
        accounts.filter { ApplePackage.Configuration.countryCode(for: $0.account.store) == region }
    }
}
