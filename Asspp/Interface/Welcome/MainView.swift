//
//  MainView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import SwiftUI

struct MainView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some View {
        #if os(macOS)
            MacSidebarMainView()
                .preferredColorScheme(appearanceMode == "system" ? nil : (appearanceMode == "light" ? .light : .dark))
        #else
            if #available(iOS 19.0, *) {
                NewMainView()
                    .preferredColorScheme(appearanceMode == "system" ? nil : (appearanceMode == "light" ? .light : .dark))
            } else {
                CustomGlassTabMainView()
                    .preferredColorScheme(appearanceMode == "system" ? nil : (appearanceMode == "light" ? .light : .dark))
            }
        #endif
    }
}

#if os(macOS)
    private struct MacSidebarMainView: View {
        @State private var selection: SidebarSection? = .home
        @StateObject private var downloads = Downloads.this

        var body: some View {
            NavigationSplitView {
                List(SidebarSection.allCases, selection: $selection) { section in
                    SidebarRow(section: section, downloads: downloads.runningTaskCount)
                        .tag(section)
                }
                .frame(minWidth: 220)
                .listStyle(.sidebar)
            } detail: {
                Group {
                    if let selection {
                        detailView(for: selection)
                    } else {
                        detailView(for: .home)
                    }
                }
                .frame(minWidth: 400, minHeight: 250)
            }
        }

        @ViewBuilder
        private func detailView(for section: SidebarSection) -> some View {
            switch section {
            case .home:
                WelcomeView()
            case .accounts:
                AccountView()
            case .search:
                SearchView()
            case .downloads:
                DownloadView()
            case .settings:
                SettingView()
            }
        }
    }

    private enum SidebarSection: Hashable, CaseIterable, Identifiable {
        case home
        case accounts
        case search
        case downloads
        case settings

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .home:
                "Home"
            case .accounts:
                "Accounts"
            case .search:
                "Search"
            case .downloads:
                "Downloads"
            case .settings:
                "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .home:
                "house"
            case .accounts:
                "person"
            case .search:
                "magnifyingglass"
            case .downloads:
                "arrow.down.circle"
            case .settings:
                "gear"
            }
        }
    }

    private struct SidebarRow: View {
        let section: SidebarSection
        let downloads: Int

        var body: some View {
            HStack {
                Label(section.title, systemImage: section.systemImage)
                if section == .downloads, downloads > 0 {
                    Spacer()
                    Text("\(downloads)")
                        .font(.caption2.bold())
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
#else
    // iOS 15-18 自定义玻璃标签栏视图
    private struct CustomGlassTabMainView: View {
        @StateObject var dvm = Downloads.this
        @State private var selectedTab: Tab = .home
        @State private var dragOffset: CGFloat = 0
        @State private var isDragging = false
        @AppStorage("appearanceMode") private var appearanceMode = "system"

        enum Tab: Int, CaseIterable {
            case home, accounts, search, downloads, settings

            var title: LocalizedStringKey {
                switch self {
                case .home: return "主页"
                case .accounts: return "账户"
                case .search: return "搜索"
                case .downloads: return "下载"
                case .settings: return "设置"
                }
            }

            var systemImage: String {
                switch self {
                case .home: return "house"
                case .accounts: return "person"
                case .search: return "magnifyingglass"
                case .downloads: return "arrow.down.circle"
                case .settings: return "gear"
                }
            }

            // 为每个标签定义独特的颜色
            var color: Color {
                switch self {
                case .home: return .blue
                case .accounts: return .green
                case .search: return .orange
                case .downloads: return .red
                case .settings: return .purple
                }
            }
        }

        var body: some View {
            ZStack(alignment: .bottom) {
                // 内容区域
                Group {
                    switch selectedTab {
                    case .home:
                        WelcomeView()
                    case .accounts:
                        AccountView()
                    case .search:
                        SearchView()
                    case .downloads:
                        DownloadView()
                    case .settings:
                        SettingView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 0)

                // 玻璃效果底部标签栏
                VStack(spacing: 0) {
                    // 整体椭圆形背景
                    RoundedRectangle(cornerRadius: 35)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .frame(height: 70)
                        .overlay(
                            ZStack {
                                HStack(spacing: 0) {
                                    ForEach(Tab.allCases, id: \.self) { tab in
                                        GlassTabButton(
                                            tab: tab,
                                            isSelected: selectedTab == tab,
                                            badgeCount: tab == .downloads ? dvm.runningTaskCount : 0
                                        ) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedTab = tab
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, 10)

                                // 拖动指示器 - 白色背景
                                if isDragging {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.3)) // 白色背景
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.8), lineWidth: 2) // 白色边框
                                        )
                                        .frame(width: 65, height: 45)
                                        .position(
                                            x: calculateDragPosition(),
                                            y: 35
                                        )
                                        .transition(.opacity)
                                }
                            }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                    }
                                    dragOffset = value.location.x
                                }
                                .onEnded { value in
                                    let tabWidth = (UIScreen.main.bounds.width - 32 - 20) / CGFloat(Tab.allCases.count)
                                    let tabIndex = Int((value.location.x / tabWidth).rounded())
                                    let newTab = Tab.allCases[max(0, min(Tab.allCases.count - 1, tabIndex))]

                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTab = newTab
                                        isDragging = false
                                    }
                                }
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .edgesIgnoringSafeArea(.bottom)
            .statusBar(hidden: false)
        }

        private func calculateDragPosition() -> CGFloat {
            let totalWidth = UIScreen.main.bounds.width - 32 - 20
            let tabWidth = totalWidth / CGFloat(Tab.allCases.count)
            let dragIndex = min(max(0, Int(dragOffset / tabWidth)), Tab.allCases.count - 1)
            return (tabWidth * CGFloat(dragIndex)) + (tabWidth / 2) + 18
        }
    }

    // 单个玻璃标签按钮
    private struct GlassTabButton: View {
        let tab: CustomGlassTabMainView.Tab
        let isSelected: Bool
        let badgeCount: Int
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
                    // 白色椭圆形背景 - 选中状态
                    if isSelected {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white.opacity(0.8)) // 白色背景
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2) // 白色边框
                            )
                            .frame(width: 65, height: 45)
                    }

                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: isSelected ? 22 : 20, weight: .medium))
                                // 选中时使用标签特有的颜色，未选中时使用原色但带透明度
                                .foregroundColor(isSelected ? tab.color : .primary)
                                .opacity(isSelected ? 1 : 0.7)

                            // 下载数量徽章
                            if tab == .downloads, badgeCount > 0 {
                                Text("\(badgeCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -10)
                            }
                        }

                        Text(tab.title)
                            .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .semibold : .medium))
                            // 文字颜色与图标颜色保持一致
                            .foregroundColor(isSelected ? tab.color : .primary)
                            .opacity(isSelected ? 1 : 0.7)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(GlassTabButtonStyle())
        }
    }

    // 玻璃按钮样式
    private struct GlassTabButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }

    // iOS 19.0+ 的新视图 - 恢复为原始系统 TabView
    @available(iOS 19.0, *)
    struct NewMainView: View {
        @StateObject var dvm = Downloads.this
        @AppStorage("appearanceMode") private var appearanceMode = "system"

        var body: some View {
            TabView {
                Tab("主页", systemImage: "house") {
                    WelcomeView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                Tab("账户", systemImage: "person") {
                    AccountView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                Tab(role: .search) {
                    SearchView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                Tab("下载", systemImage: "arrow.down.circle") {
                    DownloadView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                .badge(dvm.runningTaskCount)
                Tab("设置", systemImage: "gear") {
                    SettingView()
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
            }
            .neverMinimizeTab()
            .activateSearchWhenSearchTabSelected()
            .sidebarAdaptableTabView()
            .toolbarBackground(.hidden, for: .tabBar)
        }
    }
#endif
