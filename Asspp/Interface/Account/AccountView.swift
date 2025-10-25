//
//  AccountView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Combine
import SwiftUI

struct AccountView: View {
    @StateObject private var vm = AppStore.this
    @State private var addAccount = false
    @State private var selectedID: AppStore.UserAccount.ID?
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some View {
        #if os(macOS)
            macOSBody
        #else
            iOSBody
        #endif
    }

    #if os(macOS)
        private var macOSBody: some View {
            NavigationStack {
                accountsTable
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .navigationTitle("Accounts")
                    .toolbar { macToolbar }
            }
            .sheet(isPresented: $addAccount) {
                AddAccountView()
                    .frame(idealHeight: 200)
            }
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }

        private var accountsTable: some View {
            Table(vm.accounts, selection: $selectedID) {
                TableColumn("Email") { account in
                    NavigationLink(value: account.id) {
                        Text(account.account.email)
                            .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                            .foregroundColor(.primary)
                    }
                }

                TableColumn("Region") { account in
                    Text(account.account.store)
                        .foregroundColor(.primary)
                }

                TableColumn("Storefront") { account in
                    Text(ApplePackage.Configuration.countryCode(for: account.account.store) ?? "-")
                        .foregroundColor(.primary)
                }
            }
            .navigationDestination(for: AppStore.UserAccount.ID.self) { id in
                AccountDetailView(accountId: id)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if vm.accounts.isEmpty {
                    ContentUnavailableView(
                        label: {
                            Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
                        },
                        description: {
                            Text("Add an Apple ID to start downloading IPA packages.")
                        },
                        actions: {
                            Button("Add Account") { addAccount.toggle() }
                        }
                    )
                    .padding()
                }
            }
        }

        private var footer: some View {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.title3)
                    .foregroundColor(.primary)
                Text("Accounts are stored securely in your Keychain and can be removed at any time from the detail view.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        @ToolbarContentBuilder
        private var macToolbar: some ToolbarContent {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addAccount.toggle()
                } label: {
                    Label("Add Account", systemImage: "plus")
                        .foregroundColor(.primary)
                }
            }
        }
    #endif

    #if !os(macOS)
        private var iOSBody: some View {
            NavigationView {
                List {
                    Section {
                        ForEach(vm.accounts) { account in
                            NavigationLink(destination: AccountDetailView(accountId: account.id)) {
                                Text(account.account.email)
                                    .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                                    .foregroundColor(.primary)
                            }
                        }
                        if vm.accounts.isEmpty {
                            Text("No accounts yet.")
                                .foregroundColor(.primary)
                        }
                    } header: {
                        Text("Apple IDs")
                    } footer: {
                        Text("Your accounts are saved in your Keychain and will be synced across devices with the same iCloud account signed in.")
                    }

                    // 添加底部填充，为椭圆形标签栏留出空间
                    Section {} footer: {
                        Color.clear
                            .frame(height: 100)
                    }
                }
                .navigationTitle("Accounts")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            addAccount.toggle()
                        } label: {
                            ZStack {
                                // 圆形透明背景
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            // 设置导航栏背景为透明
            .modifier(NavigationBarTransparentModifier())
            // iOS 15及以下版本的导航栏透明设置
            .onAppear {
                setupNavigationBarAppearance()
            }
            .sheet(isPresented: $addAccount) {
                NavigationView {
                    AddAccountView()
                }
                // 设置添加账户视图的导航栏也为透明
                .modifier(NavigationBarTransparentModifier())
                .onAppear {
                    setupNavigationBarAppearance()
                }
            }
        }

        // 设置导航栏外观（iOS 15及以下版本）
        private func setupNavigationBarAppearance() {
            #if os(iOS)
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.backgroundEffect = nil
                appearance.shadowColor = .clear

                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            #endif
        }
    #endif
}
