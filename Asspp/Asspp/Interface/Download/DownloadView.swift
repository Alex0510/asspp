//
//  DownloadView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import SwiftUI

struct DownloadView: View {
    @StateObject var vm = Downloads.this

    var body: some View {
        #if os(iOS)
            NavigationView {
                content
                    .navigationTitle("Downloads")
            }
            .navigationViewStyle(.stack)
            // 设置导航栏背景为透明
            .modifier(NavigationBarTransparentModifier())
            // iOS 15及以下版本的导航栏透明设置
            .onAppear {
                setupNavigationBarAppearance()
            }
        #else
            NavigationStack {
                content
                    .navigationTitle("Downloads")
            }
        #endif
    }

    var content: some View {
        let listContent = FormOnTahoeList {
            if vm.manifests.isEmpty {
                Text("No downloads yet.")
            } else {
                packageList
            }

            // 添加底部填充，为椭圆形标签栏留出空间
            Section {} footer: {
                Color.clear
                    .frame(height: 60)
            }
        }
        
        #if os(iOS)
        return listContent
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddDownloadView()) {
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
        #else
        return listContent
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: AddDownloadView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        #endif
    }

    var packageList: some View {
        ForEach(vm.manifests, id: \.id) { req in
            NavigationLink(destination: PackageView(pkg: req)) {
                VStack(spacing: 8) {
                    ArchivePreviewView(archive: req.package)
                    SimpleProgress(progress: req.state.percent)
                        .animation(.interactiveSpring, value: req.state.percent)
                    HStack {
                        Text(req.hint)
                        Spacer()
                        Text(req.creation.formatted())
                    }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                let actions = vm.getAvailableActions(for: req)
                ForEach(actions, id: \.self) { action in
                    let label = vm.getActionLabel(for: action)
                    Button(role: label.isDestructive ? .destructive : .none) {
                        Task { vm.performDownloadAction(for: req, action: action) }
                    } label: {
                        Label(label.title, systemImage: label.systemImage)
                    }
                }
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
}

extension PackageManifest {
    var hint: String {
        if let error = state.error {
            return error
        }
        return switch state.status {
        case .pending:
            String(localized: "Pending...")
        case .downloading:
            [
                String(Int(state.percent * 100)) + "%",
                state.speed.isEmpty ? "" : state.speed + "/s",
            ]
            .compactMap(\.self)
            .joined(separator: " ")
        case .paused:
            String(localized: "Paused")
        case .completed:
            String(localized: "Completed")
        case .failed:
            String(localized: "Failed")
        }
    }
}