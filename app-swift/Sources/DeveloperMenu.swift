import SwiftUI

#if os(iOS)
import UIKit
#endif

struct DeveloperMenuView: View {
    let selectedTab: AppTab
    let aiBarContext: AIBarContext?
    let referenceDate: Date
    let resetDate: () -> Void
    let resetAppState: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var aiContextLabel: String {
        switch aiBarContext {
        case .magicPatternsEvent:
            "Magic Patterns event"
        case .computingCatchUpRecommendation:
            "Computing catch-up"
        case .magicPatternsXPostRecommendation:
            "Magic Patterns X post"
        case .computingHtmlNote:
            "Computing HTML note"
        case .computingSpeedScroll:
            "Computing speed scroll"
        case .wellBeingStudyOverload:
            "Well-being study overload"
        case nil:
            "None"
        }
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Debug"
    }

    private var formattedReferenceDate: String {
        referenceDate.formatted(date: .abbreviated, time: .standard)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        resetDate()
                    } label: {
                        Label("Reset date", systemImage: "calendar.badge.clock")
                    }
                }

                Section("Session") {
                    DeveloperInfoRow(title: "Selected tab", value: selectedTab.title, symbolName: selectedTab.symbolName)
                    DeveloperInfoRow(title: "AI bar context", value: aiContextLabel, symbolName: "sparkles")
                    DeveloperInfoRow(title: "Reference date", value: formattedReferenceDate, symbolName: "calendar")
                }

                Section("Build") {
                    DeveloperInfoRow(title: "Version", value: appVersion, symbolName: "hammer.fill")
                    DeveloperInfoRow(title: "Bundle", value: bundleIdentifier, symbolName: "shippingbox.fill")
                    DeveloperInfoRow(title: "Environment", value: "Simulator", symbolName: "iphone")
                }

                Section {
                    Button(role: .destructive) {
                        resetAppState()
                        dismiss()
                    } label: {
                        Label("Reset app state", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Developer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct DeveloperInfoRow: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(title)

            Spacer(minLength: 12)

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#if os(iOS)
struct ShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetectorViewController {
        ShakeDetectorViewController(onShake: onShake)
    }

    func updateUIViewController(_ uiViewController: ShakeDetectorViewController, context: Context) {
        uiViewController.onShake = onShake
        DispatchQueue.main.async {
            uiViewController.becomeFirstResponder()
        }
    }
}

final class ShakeDetectorViewController: UIViewController {
    var onShake: () -> Void

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        onShake()
    }
}
#endif
