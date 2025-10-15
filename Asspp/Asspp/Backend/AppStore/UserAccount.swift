//
//  UserAccount.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Foundation

extension AppStore {
    struct UserAccount: Codable, Identifiable, Hashable, Equatable, Sendable {
        var id: String { account.email }
        var account: ApplePackage.Account

        init(account: ApplePackage.Account) {
            self.account = account
        }

        static func == (lhs: UserAccount, rhs: UserAccount) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
