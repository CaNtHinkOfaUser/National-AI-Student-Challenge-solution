import SwiftUI

// MARK: - Custom skeuomorphic tab bar

struct SkeuTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                SkeuTabItem(tab: tab, isSelected: selection == tab) {
                    selection = tab
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(barBackground)
        .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: -4)
    }

    private var barBackground: some View {
        ZStack(alignment: .top) {
            Color.bgTabBar
            LinearGradient(
                colors: [.white.opacity(0.20), .black.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.60))
                    .frame(height: 1)
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Individual tab item

private struct SkeuTabItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 23, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? .white : Color.inkDeep.opacity(0.38))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(raisedFill.opacity(isSelected ? 1 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(raisedOverlay.opacity(isSelected ? 1 : 0))
            .shadow(
                color: tab.tint.opacity(isSelected ? 0.35 : 0),
                radius: 6, x: 0, y: 3
            )
            .animation(.spring(response: 0.30, dampingFraction: 0.70), value: isSelected)
        }
        .buttonStyle(SkeuPressStyle())
    }

    // Tab's semantic color as the base, with the same light-to-dark gradient as SkeuButton
    private var raisedFill: some View {
        ZStack {
            tab.tint
            LinearGradient(
                colors: [.white.opacity(0.24), .black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // Specular sheen on upper half + bright-top / dark-bottom bevel border — identical to SkeuButton
    private var raisedOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.28), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.50)
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.52), .black.opacity(0.20)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
    }
}
