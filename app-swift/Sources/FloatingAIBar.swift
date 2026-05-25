import SwiftUI
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif
#if canImport(UIKit) && canImport(SafariServices)
import SafariServices
#endif

// MARK: - Floating AI bar (skeuomorphic, shadow-free)

private let linkedInAvatarURL = URL(string: "https://images.lumacdn.com/cdn-cgi/image/format=auto,fit=cover,dpr=2,anim=false,background=white,quality=75,width=112,height=112/avatars/4t/71ea3b82-7724-4696-b81e-83f994d5d5f3.png")!

struct FloatingAIBar: View {
    var context: AIBarContext?
    var defaultPlaceholder: String = "Ask me anything…"
    @Binding var dimsBackground: Bool
    @Binding var computingOverlayWords: [String]
    @Binding var computingShowsOverlay: Bool
    @Binding var hasAddedComputingRecoveryTasks: Bool
    @Binding var hasBookedComputingConsult: Bool
    var onOpenComputingNotes: (() -> Void)? = nil
    var onStartPracticeTest: (() -> Void)? = nil
    var onAddXPostToResume: (() -> Void)? = nil

    @State private var isExpanded = false
    @State private var barBounceOffset: CGFloat = 0
    @State private var hasPendingPracticeTest = false
    @State private var showsPracticeTestCard = false
    @State private var inputText = ""
    @State private var inputSuggestion = ""
    @State private var showsEventActions = false
    @State private var showsMagicPatternsAnswer = false
    @State private var hasPendingLinkedInRecommendation = false
    @State private var showsLinkedInRecommendation = false
    @State private var hasPendingComputingCatchUp = false
    @State private var showsComputingCatchUp = false
    @State private var hasPendingXPostSuggestion = false
    @State private var showsXPostSuggestion = false
    @State private var showsSecurityPrivacyExplainer = false
    @State private var hasPendingWellBeingAlert = false
    @State private var showsWellBeingAlert = false
    @State private var hasPendingRevisionSuggestion = false
    @State private var showsRevisionSuggestion = false
    @State private var magicPatternsAnswerRun = 0
    @State private var linkedInRecommendationRun = 0
    @State private var linkedInRecommendationStreamRun = 0
    @State private var computingCatchUpStreamRun = 0
    @State private var streamedMagicPatternsWords: [String] = []
    @State private var streamedLinkedInRecommendationWords: [String] = []
    @State private var isComputingCatchUpStreamingComplete = false
    @State private var linkedInAvatarImage: PlatformImage?
    @FocusState private var inputFocused: Bool

    private let magicPatternsAnswer = "Magic Patterns is an AI-native product design workspace that helps teams turn prompts, screenshots, and product ideas into editable interface concepts. Web sources describe it as a fast way for founders, designers, and engineers to explore UI directions before implementation."
    private let linkedInRecommendationText = "Alex Lee works at the edge of AI product design and engineering at Magic Patterns, helping turn prompts and product ideas into editable interface concepts. He is a useful follow if you want to track how AI-native design tools are changing the way teams prototype and build software."
    private let computingCatchUpText = "Computing needs a recovery plan because two missed lessons are keeping you around B4. I split the catch-up into specific revision tasks, added retrieval practice, and included a consult so you can push toward B3 before the next grade update."

    private var shouldDimMainContent: Bool {
        computingShowsOverlay || (isExpanded && (showsMagicPatternsAnswer || showsLinkedInRecommendation || showsComputingCatchUp || showsSecurityPrivacyExplainer || showsWellBeingAlert))
    }

    private var expandedTitle: String {
        if showsComputingCatchUp {
            "Computing catch-up"
        } else if showsXPostSuggestion {
            "Magic Patterns post"
        } else if showsLinkedInRecommendation {
            "LinkedIn recommendation"
        } else if showsEventActions {
            "Event assistant"
        } else if showsSecurityPrivacyExplainer {
            "Security vs Privacy"
        } else if showsWellBeingAlert {
            "Well-being check-in"
        } else if showsRevisionSuggestion {
            "Revision suggestion"
        } else if showsPracticeTestCard {
            "Practice test"
        } else {
            "AI Assistant"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedPanel
            }
            controlRow
        }
        .background(barFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(barBevel)
        .offset(y: barBounceOffset)                       // bevel — no external shadow
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .task {
            await preloadLinkedInAvatar()
        }
        .task(id: context) {
            withAnimation(.snappy) {
                showsEventActions = false
                showsMagicPatternsAnswer = false
                showsLinkedInRecommendation = false
                hasPendingLinkedInRecommendation = false
                showsComputingCatchUp = false
                hasPendingComputingCatchUp = false
                showsXPostSuggestion = false
                hasPendingXPostSuggestion = false
                showsSecurityPrivacyExplainer = false
                showsWellBeingAlert = false
                hasPendingWellBeingAlert = false
                showsRevisionSuggestion = false
                hasPendingRevisionSuggestion = false
                showsPracticeTestCard = false
                hasPendingPracticeTest = false
                streamedMagicPatternsWords = []
                streamedLinkedInRecommendationWords = []
                computingOverlayWords = []
                isComputingCatchUpStreamingComplete = false
                computingShowsOverlay = false
                inputText = ""
                inputSuggestion = ""
            }

            if context == .wellBeingStudyOverload {
                withAnimation(.snappy) {
                    isExpanded = false
                    hasPendingWellBeingAlert = true
                    inputFocused = false
                }
                return
            }

            if context == .computingCatchUpRecommendation {
                guard !hasBookedComputingConsult else { return }
                withAnimation(.snappy) {
                    isExpanded = false
                    hasPendingComputingCatchUp = true
                    inputFocused = false
                }
                return
            }

            if context == .magicPatternsXPostRecommendation {
                withAnimation(.snappy) {
                    isExpanded = false
                    hasPendingXPostSuggestion = true
                    inputFocused = false
                }
                return
            }

            if context == .computingHtmlNote {
                withAnimation(.snappy) {
                    isExpanded = false
                    hasPendingRevisionSuggestion = true
                    inputFocused = false
                }
                return
            }

            if context == .computingSpeedScroll {
                withAnimation(.snappy) {
                    isExpanded = false
                    hasPendingPracticeTest = true
                    inputFocused = false
                }
                triggerBarBounce()
                return
            }

            guard context == .magicPatternsEvent else { return }

            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }

            withAnimation(.snappy) {
                isExpanded = true
                showsEventActions = true
                inputFocused = false
            }
        }
        .task(id: magicPatternsAnswerRun) {
            guard magicPatternsAnswerRun > 0 else { return }
            await streamMagicPatternsAnswer()
        }
        .task(id: linkedInRecommendationRun) {
            guard linkedInRecommendationRun > 0 else { return }
            await showLinkedInRecommendationAfterDelay()
        }
        .task(id: linkedInRecommendationStreamRun) {
            guard linkedInRecommendationStreamRun > 0 else { return }
            await streamLinkedInRecommendation()
        }
        .task(id: computingCatchUpStreamRun) {
            guard computingCatchUpStreamRun > 0 else { return }
            await streamComputingCatchUp()
        }
        .onChange(of: computingShowsOverlay) { _, shows in
            if !shows {
                withAnimation(.snappy) {
                    showsComputingCatchUp = false
                    hasPendingComputingCatchUp = false
                    isComputingCatchUpStreamingComplete = false
                }
            }
        }
        .onChange(of: hasBookedComputingConsult) { _, isBooked in
            guard isBooked else { return }
            withAnimation(.snappy) {
                showsComputingCatchUp = false
                hasPendingComputingCatchUp = false
                isComputingCatchUpStreamingComplete = false
                computingShowsOverlay = false
            }
        }
        .onChange(of: shouldDimMainContent) { _, shouldDim in
            withAnimation(.snappy) {
                dimsBackground = shouldDim
            }
        }
        .onDisappear {
            dimsBackground = false
        }
    }

    // MARK: - Always-visible control row

    private var controlRow: some View {
        HStack(spacing: 10) {
            aiBadge

            if isExpanded {
                Text(expandedTitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if hasPendingWellBeingAlert {
                WellBeingStudyLoadBadge()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if hasPendingComputingCatchUp {
                ComputingCatchUpStatusBadge()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if hasPendingLinkedInRecommendation {
                LinkedInStatusBadge()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if hasPendingXPostSuggestion {
                XPostStatusBadge()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if hasPendingRevisionSuggestion {
                ComputingRevisionSuggestionBadge()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if hasPendingPracticeTest {
                PracticeTestBadge()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                MonitoringStatusLabel()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ChevronToggle(isExpanded: isExpanded) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                    if isExpanded {
                        isExpanded = false
                        inputFocused = false
                    } else if hasPendingWellBeingAlert {
                        isExpanded = true
                        hasPendingWellBeingAlert = false
                        showsWellBeingAlert = true
                        inputFocused = false
                    } else if hasPendingComputingCatchUp {
                        showRevisionPlanner()
                    } else if hasPendingLinkedInRecommendation {
                        showPendingLinkedInRecommendation()
                    } else if hasPendingXPostSuggestion {
                        showPendingXPostSuggestion()
                    } else if hasPendingRevisionSuggestion {
                        showPendingRevisionSuggestion()
                    } else if hasPendingPracticeTest {
                        showPendingPracticeTest()
                    } else {
                        isExpanded = true
                        inputFocused = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Expanded input panel

    private var expandedPanel: some View {
        Group {
            if showsComputingCatchUp {
                computingCatchUpPanel
            } else if showsXPostSuggestion {
                xPostSuggestionPanel
            } else if showsLinkedInRecommendation {
                linkedInRecommendationPanel
            } else if showsSecurityPrivacyExplainer {
                securityPrivacyExplainerPanel
            } else if showsRevisionSuggestion {
                revisionSuggestionPanel
            } else if showsPracticeTestCard {
                practiceTestPanel
            } else if showsWellBeingAlert {
                wellBeingAlertPanel
            } else if showsEventActions, context == .magicPatternsEvent {
                eventActionsPanel
            } else {
                inputPanel
            }
        }
    }

    private var wellBeingAlertPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 20)

            WellBeingStudyOverloadCard {
                withAnimation(.snappy) {
                    showsWellBeingAlert = false
                    isExpanded = false
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:   .move(edge: .bottom).combined(with: .opacity)
        ))
    }

    private var inputPanel: some View {
        VStack(spacing: 0) {
            // Hairline separator — inset slightly to look engraved
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                TextField(inputSuggestion.isEmpty ? defaultPlaceholder : inputSuggestion, text: $inputText, axis: .vertical)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                    .focused($inputFocused)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(recessedFill)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(recessedBevel)

                SendButton(hasText: !inputText.isEmpty || !inputSuggestion.isEmpty) {
                    handleInputSubmit()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private var eventActionsPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                if showsMagicPatternsAnswer {
                    MagicPatternsAIWebAnswer(words: streamedMagicPatternsWords) {
                        dismissMagicPatternsAnswer()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    HStack(spacing: 8) {
                        EventAIActionButton(
                            title: "What is Magic Patterns",
                            symbolName: "sparkles",
                            action: beginMagicPatternsAnswer
                        )

                        Link(destination: URL(string: "http://maps.apple.com/?q=Dough%2030%20Victoria%20St%20Singapore")!) {
                            EventAIActionButtonLabel(title: "Directions to the location", symbolName: "location.fill")
                        }
                        .buttonStyle(.plain)

                        Link(destination: URL(string: "https://lu.ma/7die021j")!) {
                            EventAIActionButtonLabel(title: "Register now", symbolName: "ticket.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private var linkedInRecommendationPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            LinkedInRecommendationCard(
                avatarImage: linkedInAvatarImage,
                words: streamedLinkedInRecommendationWords
            ) {
                withAnimation(.snappy) {
                    showsLinkedInRecommendation = false
                    streamedLinkedInRecommendationWords = []
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private var computingCatchUpPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            ComputingCatchUpCard(
                words: computingOverlayWords,
                isStreamingComplete: isComputingCatchUpStreamingComplete,
                onCompleteRecoveryForm: {
                    hasBookedComputingConsult = true
                    hasAddedComputingRecoveryTasks = true
                },
                onConfirmRevisionPlan: {
                    withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
                        computingShowsOverlay = true
                        isExpanded = false
                    }
                },
                onDismiss: {
                    withAnimation(.snappy) {
                        showsComputingCatchUp = false
                        computingOverlayWords = []
                        isComputingCatchUpStreamingComplete = false
                        computingShowsOverlay = false
                    }
                }
            )
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private var xPostSuggestionPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            XPostSuggestionCard(avatarImage: linkedInAvatarImage, onAddToResume: onAddXPostToResume) {
                withAnimation(.snappy) {
                    showsXPostSuggestion = false
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private func beginMagicPatternsAnswer() {
        withAnimation(.snappy) {
            showsMagicPatternsAnswer = true
            hasPendingLinkedInRecommendation = false
            showsLinkedInRecommendation = false
            hasPendingComputingCatchUp = false
            showsComputingCatchUp = false
            hasPendingXPostSuggestion = false
            showsXPostSuggestion = false
            streamedMagicPatternsWords = []
            streamedLinkedInRecommendationWords = []
            computingOverlayWords = []
            isComputingCatchUpStreamingComplete = false
            computingShowsOverlay = false
            magicPatternsAnswerRun += 1
            linkedInRecommendationRun += 1
        }
    }

    private func dismissMagicPatternsAnswer() {
        withAnimation(.snappy) {
            showsMagicPatternsAnswer = false
            hasPendingLinkedInRecommendation = false
            showsLinkedInRecommendation = false
            hasPendingComputingCatchUp = false
            showsComputingCatchUp = false
            hasPendingXPostSuggestion = false
            showsXPostSuggestion = false
            streamedLinkedInRecommendationWords = []
            computingOverlayWords = []
            isComputingCatchUpStreamingComplete = false
            computingShowsOverlay = false
            linkedInRecommendationRun += 1
        }
    }

    private func showLinkedInRecommendationAfterDelay() async {
        try? await Task.sleep(for: .seconds(5))
        guard !Task.isCancelled, context == .magicPatternsEvent, !showsMagicPatternsAnswer else { return }

        withAnimation(.snappy) {
            isExpanded = false
            showsEventActions = true
            hasPendingLinkedInRecommendation = true
            showsLinkedInRecommendation = false
            streamedLinkedInRecommendationWords = []
            inputFocused = false
        }
    }

    private func showPendingLinkedInRecommendation() {
        isExpanded = true
        showsEventActions = true
        hasPendingLinkedInRecommendation = false
        showsLinkedInRecommendation = true
        hasPendingComputingCatchUp = false
        showsComputingCatchUp = false
        hasPendingXPostSuggestion = false
        showsXPostSuggestion = false
        streamedLinkedInRecommendationWords = []
        inputFocused = false
        linkedInRecommendationStreamRun += 1
    }

    private func showRevisionPlanner() {
        isExpanded = true
        showsEventActions = false
        hasPendingComputingCatchUp = false
        showsComputingCatchUp = true
        hasPendingLinkedInRecommendation = false
        showsLinkedInRecommendation = false
        hasPendingXPostSuggestion = false
        showsXPostSuggestion = false
        computingOverlayWords = []
        isComputingCatchUpStreamingComplete = false
        computingShowsOverlay = false
        inputFocused = false
        computingCatchUpStreamRun += 1
    }

    private func showPendingXPostSuggestion() {
        isExpanded = true
        showsEventActions = false
        hasPendingXPostSuggestion = false
        showsXPostSuggestion = true
        hasPendingComputingCatchUp = false
        showsComputingCatchUp = false
        hasPendingLinkedInRecommendation = false
        showsLinkedInRecommendation = false
        inputFocused = false
    }

    private func showPendingPracticeTest() {
        isExpanded = true
        hasPendingPracticeTest = false
        showsPracticeTestCard = true
        showsEventActions = false
        hasPendingComputingCatchUp = false
        showsComputingCatchUp = false
        hasPendingLinkedInRecommendation = false
        showsLinkedInRecommendation = false
        hasPendingXPostSuggestion = false
        showsXPostSuggestion = false
        hasPendingRevisionSuggestion = false
        showsRevisionSuggestion = false
        inputFocused = false
    }

    private var practiceTestPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 20)

            PracticeTestCard(
                onStart: {
                    withAnimation(.snappy) { showsPracticeTestCard = false; isExpanded = false }
                    onStartPracticeTest?()
                },
                onDismiss: {
                    withAnimation(.snappy) { showsPracticeTestCard = false; isExpanded = false }
                }
            )
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:   .move(edge: .bottom).combined(with: .opacity)
        ))
    }

    private func showPendingRevisionSuggestion() {
        isExpanded = true
        hasPendingRevisionSuggestion = false
        showsRevisionSuggestion = true
        showsEventActions = false
        hasPendingComputingCatchUp = false
        showsComputingCatchUp = false
        hasPendingLinkedInRecommendation = false
        showsLinkedInRecommendation = false
        hasPendingXPostSuggestion = false
        showsXPostSuggestion = false
        inputFocused = false
    }

    private func handleInputSubmit() {
        let submittedText = inputText.isEmpty ? inputSuggestion : inputText
        if shouldShowSecurityPrivacyExplainer(for: submittedText) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                inputText = ""
                inputSuggestion = ""
                inputFocused = false
                showsSecurityPrivacyExplainer = true
                isExpanded = true
                showsEventActions = false
                showsMagicPatternsAnswer = false
                showsLinkedInRecommendation = false
                showsComputingCatchUp = false
                showsXPostSuggestion = false
            }
        } else {
            inputText = ""
            inputSuggestion = ""
            inputFocused = false
        }
    }

    private func shouldShowSecurityPrivacyExplainer(for text: String) -> Bool {
        let normalizedText = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalizedText == "explain the difference" || normalizedText.hasPrefix("explain the difference ")
    }

    private var revisionSuggestionPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            ComputingRevisionSuggestionCard(
                onOpenNotes: {
                    withAnimation(.snappy) { showsRevisionSuggestion = false; isExpanded = false }
                    onOpenComputingNotes?()
                },
                onDismiss: {
                    withAnimation(.snappy) { showsRevisionSuggestion = false; isExpanded = false }
                }
            )
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private func triggerBarBounce() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.36)) {
            barBounceOffset = -20
        }
        Task {
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.spring(response: 0.50, dampingFraction: 0.68)) {
                barBounceOffset = 0
            }
        }
    }

    private var securityPrivacyExplainerPanel: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            SecurityPrivacyExplainerCard {
                withAnimation(.snappy) {
                    showsSecurityPrivacyExplainer = false
                    isExpanded = false
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal:   .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }

    private func preloadLinkedInAvatar() async {
        guard linkedInAvatarImage == nil else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: linkedInAvatarURL)
            guard !Task.isCancelled, let image = PlatformImage(data: data) else { return }
            linkedInAvatarImage = image
        } catch {
            // Keep the initials fallback if the remote image is unavailable.
        }
    }

    private func streamMagicPatternsAnswer() async {
        let words = magicPatternsAnswer.split(separator: " ").map(String.init)

        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }

        for word in words {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(85))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.22)) {
                streamedMagicPatternsWords.append(word)
            }
        }
    }

    private func streamLinkedInRecommendation() async {
        let words = linkedInRecommendationText.split(separator: " ").map(String.init)

        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        for word in words {
            guard !Task.isCancelled, showsLinkedInRecommendation else { return }
            try? await Task.sleep(for: .milliseconds(70))
            guard !Task.isCancelled, showsLinkedInRecommendation else { return }

            withAnimation(.easeOut(duration: 0.20)) {
                streamedLinkedInRecommendationWords.append(word)
            }
        }
    }

    private func streamComputingCatchUp() async {
        let words = computingCatchUpText.split(separator: " ").map(String.init)

        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        for word in words {
            guard !Task.isCancelled, showsComputingCatchUp else { return }
            try? await Task.sleep(for: .milliseconds(70))
            guard !Task.isCancelled, showsComputingCatchUp else { return }

            withAnimation(.easeOut(duration: 0.20)) {
                computingOverlayWords.append(word)
            }
        }

        guard !Task.isCancelled, showsComputingCatchUp else { return }
        withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
            isComputingCatchUpStreamingComplete = true
        }
    }

    // MARK: - Skeuomorphic surfaces (no shadow)

    // Bar body: same layered-gradient technique as SkeuTabBar
    private var barFill: some View {
        ZStack(alignment: .top) {
            Color.white
            LinearGradient(
                colors: [.white.opacity(0.26), .black.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
            // Specular line at the very top edge
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.70))
                    .frame(height: 1)
                Spacer()
            }
        }
    }

    // Uniform border on all sides.
    private var barBevel: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
                Color.black.opacity(0.12),
                lineWidth: 1
            )
    }

    // Recessed input field fill.
    private var recessedFill: some View {
        ZStack {
            Color.bgPrimary
            LinearGradient(
                colors: [.black.opacity(0.05), .white.opacity(0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var recessedBevel: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                Color.black.opacity(0.12),
                lineWidth: 1
            )
    }

    // MARK: - AI icon badge

    private var aiBadge: some View {
        ZStack {
            // Purple raised fill — same gradient technique as SkeuButton
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.52, green: 0.28, blue: 0.92),
                             Color(red: 0.36, green: 0.16, blue: 0.72)],
                    startPoint: .top, endPoint: .bottom
                )
                LinearGradient(
                    colors: [.white.opacity(0.24), .clear],
                    startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.52)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.48), .black.opacity(0.20)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            )
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 34, height: 34)
    }
}

// MARK: - Event context actions

private let aiEventAccent = Color(red: 0.45, green: 0.28, blue: 0.92)

private struct EventAIActionButton: View {
    let title: String
    let symbolName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            EventAIActionButtonLabel(title: title, symbolName: symbolName)
        }
        .buttonStyle(.plain)
    }
}

private struct EventAIActionButtonLabel: View {
    let title: String
    let symbolName: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .frame(height: 17)

            Text(title)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
        }
        .foregroundStyle(aiEventAccent)
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.horizontal, 5)
        .background(aiEventAccent.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(aiEventAccent.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct MagicPatternsAIWebAnswer: View {
    let words: [String]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .semibold))
                Text("Web-sourced answer")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer(minLength: 8)
            }
            .foregroundStyle(aiEventAccent)

            FlowLayout(spacing: 4, rowSpacing: 5) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(.system(size: 14.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.76))
                        .transition(.opacity)
                }
            }

            HStack {
                Spacer()
                SkeuButton(tint: aiEventAccent, size: .compact, action: onDismiss) {
                    Text("Dismiss")
                }
            }
        }
        .padding(12)
        .background(aiEventAccent.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(aiEventAccent.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct LinkedInRecommendationCard: View {
    let avatarImage: PlatformImage?
    let words: [String]
    let onDismiss: () -> Void

    private let linkedInURL = URL(string: "https://www.linkedin.com/search/results/people/?keywords=Alex%20Lee%20Magic%20Patterns")!

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
                Text("LinkedIn recommendation")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer(minLength: 8)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss LinkedIn recommendation")
            }
            .foregroundStyle(aiEventAccent)

            HStack(alignment: .center, spacing: 12) {
                LinkedInAvatar(image: avatarImage)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Alex Lee")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                    Text("Magic Patterns host from Luma")
                        .font(.system(size: 13.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.58))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)
            }

            Link(destination: linkedInURL) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("View on LinkedIn")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(aiEventAccent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .black.opacity(0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )
            }
            .buttonStyle(SkeuPressStyle())

            FlowLayout(spacing: 4, rowSpacing: 5) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(.system(size: 13.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.72))
                        .transition(.opacity)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(aiEventAccent.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(12)
        .background(aiEventAccent.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(aiEventAccent.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct LinkedInAvatar: View {
    let image: PlatformImage?

    var body: some View {
        Group {
            if let image {
                platformImage(image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text("AL")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(aiEventAccent.gradient)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
    }

    private func platformImage(_ image: PlatformImage) -> Image {
        #if canImport(UIKit)
        Image(uiImage: image)
        #elseif canImport(AppKit)
        Image(nsImage: image)
        #endif
    }
}

private struct XPostSuggestionCard: View {
    let avatarImage: PlatformImage?
    var onAddToResume: (() -> Void)? = nil
    let onDismiss: () -> Void

    @State private var selectedSource: XPostSuggestionSource = .post
    @State private var showsBrowser = false
    @State private var addedToResume = false

    private let xPostURL = URL(string: "https://x.com/magicpatterns/status/2056401441795735868")!

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Magic Patterns post")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer(minLength: 8)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss X post suggestion")
            }
            .foregroundStyle(aiEventAccent)

            XPostSuggestionChipBar(selection: $selectedSource)

            switch selectedSource {
            case .post:
                xPostBody
            case .hidden:
                hiddenRecommendationBody
            }
        }
        .padding(14)
        .background(aiEventAccent.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(aiEventAccent.opacity(0.16), lineWidth: 1)
        )
    }

    private var xPostBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("New post to review")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text("@magicpatterns shared an update that matches this timeline.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showsBrowser = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("View X post")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(aiEventAccent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .black.opacity(0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )
            }
            .buttonStyle(SkeuPressStyle())
            #if canImport(UIKit) && canImport(SafariServices)
            .sheet(isPresented: $showsBrowser) {
                InAppBrowserView(url: xPostURL)
                    .ignoresSafeArea()
            }
            #endif

            SkeuButton(
                tint: addedToResume ? Color(red: 0.18, green: 0.62, blue: 0.32) : .orange,
                size: .compact,
                action: {
                    guard !addedToResume else { return }
                    withAnimation(.snappy) { addedToResume = true }
                    onAddToResume?()
                }
            ) {
                HStack(spacing: 6) {
                    Image(systemName: addedToResume ? "checkmark.circle.fill" : "doc.text.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Text(addedToResume ? "Added to Resume" : "Add to Resume")
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
            }
            .animation(.snappy, value: addedToResume)
        }
    }

    private var hiddenRecommendationBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                LinkedInAvatar(image: avatarImage)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect with Alex")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                    Text("Alex Lee is associated with Magic Patterns and this event.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {} label: {
                HStack(spacing: 7) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Connect")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SkeuButtonStyle(tint: .gray, size: .regular))
            .disabled(true)
            .accessibilityLabel("Connect with Alex unavailable")
        }
    }
}

private enum XPostSuggestionSource: CaseIterable {
    case post
    case hidden

    var title: String {
        switch self {
        case .post: "Recommended"
        case .hidden: "Hidden"
        }
    }
}

private struct XPostSuggestionChipBar: View {
    @Binding var selection: XPostSuggestionSource

    var body: some View {
        HStack(spacing: 8) {
            ForEach(XPostSuggestionSource.allCases, id: \.self) { source in
                Button {
                    withAnimation(.snappy) {
                        selection = source
                    }
                } label: {
                    Text(source.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(selection == source ? .white : aiEventAccent)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            selection == source ? aiEventAccent : aiEventAccent.opacity(0.08),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(aiEventAccent.opacity(selection == source ? 0 : 0.16), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#if canImport(UIKit) && canImport(SafariServices)
private struct InAppBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

let computingAccent = Color(red: 0.94, green: 0.46, blue: 0.12)
let revisionWarmAccent = Color(red: 0.94, green: 0.62, blue: 0.16)
let consultBlue = Color(red: 0.22, green: 0.40, blue: 0.94)

struct ComputingCatchUpCard: View {
    let words: [String]
    let isStreamingComplete: Bool
    let onCompleteRecoveryForm: (() -> Void)?
    let onConfirmRevisionPlan: (() -> Void)?
    let onDismiss: () -> Void
    @State private var hasArrangedConsult = false
    @State private var hasConfirmed: Bool
    @State private var visibleTaskCount = 0
    @State private var showsGradeGoal = false
    @State private var showsConsultButton = false
    @State private var showsConsultBooking = false
    @State private var selectedConsultOption: ConsultBookingOption?

    private let tasks: [RevisionPlanTask] = [
        RevisionPlanTask(time: "10m", title: "Annotate missed notes", detail: "Highlight three unknown terms from each missed Computing lesson."),
        RevisionPlanTask(time: "15m", title: "Rebuild worked examples", detail: "Trace a stack example and an algorithm walkthrough without looking."),
        RevisionPlanTask(time: "12m", title: "Mark a retrieval quiz", detail: "Answer 12 weak-topic questions, then retry every missed step."),
    ]

    init(
        words: [String],
        isStreamingComplete: Bool,
        startsConfirmed: Bool = false,
        onCompleteRecoveryForm: (() -> Void)? = nil,
        onConfirmRevisionPlan: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.words = words
        self.isStreamingComplete = isStreamingComplete
        self.onCompleteRecoveryForm = onCompleteRecoveryForm
        self.onConfirmRevisionPlan = onConfirmRevisionPlan
        self.onDismiss = onDismiss
        _hasConfirmed = State(initialValue: startsConfirmed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            cardHeader
            if !words.isEmpty {
                aiSummary
            }
            if isStreamingComplete && !hasConfirmed {
                confirmButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if hasConfirmed && visibleTaskCount > 0 {
                VStack(spacing: 10) {
                    ForEach(Array(tasks.prefix(visibleTaskCount)), id: \.id) { task in
                        RevisionPlanTaskRow(task: task)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
            }
            if hasConfirmed && showsGradeGoal {
                gradeGoalRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                if showsConsultButton {
                    consultButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .padding(14)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(cardBevel)
        .sheet(isPresented: $showsConsultBooking) {
            ConsultBookingSheet(selectedOption: $selectedConsultOption)
        }
        .onChange(of: selectedConsultOption) { _, option in
            guard option != nil else { return }
            withAnimation(.snappy) {
                hasArrangedConsult = true
            }
            onCompleteRecoveryForm?()
        }
        .task(id: hasConfirmed) {
            guard hasConfirmed, visibleTaskCount == 0 else { return }
            await revealTasksSequentially()
        }
    }

    private func revealTasksSequentially() async {
        showsGradeGoal = false
        showsConsultButton = false
        for i in 0..<tasks.count {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
                visibleTaskCount = i + 1
            }
        }

        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
            showsGradeGoal = true
        }

        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
            showsConsultButton = true
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
            Text("Computing recovery plan")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss Computing catch-up")
        }
        .foregroundStyle(computingAccent)
    }

    private var confirmButton: some View {
        SkeuButton(tint: Color(red: 0.52, green: 0.28, blue: 0.92)) {
            if let onConfirmRevisionPlan {
                onConfirmRevisionPlan()
            } else {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
                    hasConfirmed = true
                }
            }
        } label: {
            Label("View my revision plan", systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity)
        }
    }

    private var gradeGoalRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CURRENT GRADE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(computingAccent.opacity(0.72))
                    .tracking(0.5)
                Text("B4")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(computingAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.inkDeep.opacity(0.28))
                .padding(.horizontal, 10)

            VStack(alignment: .trailing, spacing: 3) {
                Text("GRADE GOAL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(revisionWarmAccent.opacity(0.80))
                    .tracking(0.5)
                Text("B3")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(revisionWarmAccent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [computingAccent.opacity(0.08), revisionWarmAccent.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [computingAccent.opacity(0.18), revisionWarmAccent.opacity(0.18)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var aiSummary: some View {
        FlowLayout(spacing: 4, rowSpacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                Text(word)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                    .transition(.opacity)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(summaryFill)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.black.opacity(0.09), lineWidth: 1)
        )
    }

    private var consultButton: some View {
        SkeuButton(
            tint: hasArrangedConsult ? computingAccent : consultBlue
        ) {
            showsConsultBooking = true
        } label: {
            Label(
                hasArrangedConsult ? "Consult arranged" : "Arrange a consult",
                systemImage: hasArrangedConsult ? "checkmark.circle.fill" : "person.2.wave.2.fill"
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var cardFill: some View {
        LinearGradient(
            colors: [computingAccent.opacity(0.06), revisionWarmAccent.opacity(0.06)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var cardBevel: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [computingAccent.opacity(0.20), revisionWarmAccent.opacity(0.20)],
                    startPoint: .leading, endPoint: .trailing
                ),
                lineWidth: 1
            )
    }

    private var summaryFill: some View {
        ZStack {
            Color.black.opacity(0.04)
            LinearGradient(
                colors: [.black.opacity(0.03), .white.opacity(0.05)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

struct ConsultBookingOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let symbolName: String

    static let options = [
        ConsultBookingOption(title: "Today, 4:30 PM", detail: "30 min with Ms Tan", symbolName: "clock.fill"),
        ConsultBookingOption(title: "Tomorrow, 8:15 AM", detail: "Before morning lessons", symbolName: "sunrise.fill"),
        ConsultBookingOption(title: "Friday, 3:45 PM", detail: "After Computing lab", symbolName: "calendar.badge.clock"),
    ]
}

struct ConsultBookingSheet: View {
    @Binding var selectedOption: ConsultBookingOption?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Book consult")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text("Computing catch-up")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.55))
            }

            VStack(spacing: 10) {
                ForEach(ConsultBookingOption.options) { option in
                    Button {
                        selectedOption = option
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.symbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(consultBlue, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkDeep)
                                Text(option.detail)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.inkDeep.opacity(0.55))
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.inkDeep.opacity(0.28))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(SkeuPressStyle())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgPrimary)
        .presentationDetents([.height(330), .medium])
        .presentationDragIndicator(.visible)
    }
}


struct RevisionPlanTask: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    let detail: String
}

struct RevisionPlanTaskRow: View {
    let task: RevisionPlanTask

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text(task.time)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(computingAccent.opacity(0.72))
            }
            Text(task.detail)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color.inkDeep.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(rowFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(rowBevel)
    }

    private var rowFill: some View {
        Color.white.opacity(0.62)
    }

    private var rowBevel: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(computingAccent.opacity(0.18), lineWidth: 1)
    }
}

// MARK: - Security vs Privacy explainer card

private let securityAccent = Color(red: 0.18, green: 0.44, blue: 0.94)
private let privacyAccent  = Color(red: 0.55, green: 0.22, blue: 0.90)

private struct SecurityPrivacyExplainerCard: View {
    let onDismiss: () -> Void

    @State private var showsHeaderTitle = false
    @State private var securityWords: [String] = []
    @State private var showsSecurityForeground = false
    @State private var showsPrivacyTile = false
    @State private var showsPrivacyForeground = false
    @State private var privacyWords: [String] = []

    private let securityText = "Keeping bad things out. Stops attackers from breaking in — like a lock on the front door. Without security, anyone can walk straight in."
    private let privacyText = "Controlling who sees your information. Even if someone is already inside, privacy decides what they are allowed to look at. It is about your right to choose."

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            securityTile
            if showsPrivacyTile { privacyTile }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [securityAccent.opacity(0.06), privacyAccent.opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [securityAccent.opacity(0.20), privacyAccent.opacity(0.20)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .task { await streamContent() }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
            if showsHeaderTitle {
                Text("Simple explanation")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .transition(.opacity)
            }
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss explanation")
        }
        .foregroundStyle(securityAccent)
    }

    private var securityTile: some View {
        explainerTile(
            symbolName: "lock.shield.fill",
            accent: securityAccent,
            label: "Security",
            words: securityWords,
            showsForeground: showsSecurityForeground
        )
    }

    private var privacyTile: some View {
        explainerTile(
            symbolName: "eye.slash.fill",
            accent: privacyAccent,
            label: "Privacy",
            words: privacyWords,
            showsForeground: showsPrivacyForeground
        )
    }

    private func explainerTile(
        symbolName: String,
        accent: Color,
        label: String,
        words: [String],
        showsForeground: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(accent.opacity(0.13))
                Image(systemName: symbolName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 56, height: 56)
            .opacity(showsForeground ? 1 : 0)

            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                FlowLayout(spacing: 4, rowSpacing: 4) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                        Text(word)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.inkDeep.opacity(0.80))
                            .transition(.opacity)
                    }
                }
            }
            .opacity(showsForeground ? 1 : 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(0.18), lineWidth: 1)
        )
    }

    private func streamContent() async {
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            showsHeaderTitle = true
            showsSecurityForeground = true
        }

        for word in securityText.split(separator: " ").map(String.init) {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(75))
            withAnimation(.easeOut(duration: 0.18)) { securityWords.append(word) }
        }

        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        showsPrivacyTile = true

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.18)) { showsPrivacyForeground = true }

        for word in privacyText.split(separator: " ").map(String.init) {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(75))
            withAnimation(.easeOut(duration: 0.18)) { privacyWords.append(word) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(in: proposal.width ?? 0, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = layout(in: bounds.width, subviews: subviews)

        for item in rows.items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + item.frame.minX, y: bounds.minY + item.frame.minY),
                proposal: ProposedViewSize(item.frame.size)
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (items: [(index: Int, frame: CGRect)], size: CGSize) {
        var items: [(index: Int, frame: CGRect)] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        let availableWidth = max(width, 1)

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)

            if x > 0, x + size.width > availableWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            items.append((index, CGRect(origin: CGPoint(x: x, y: y), size: size)))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxWidth = max(maxWidth, min(x, availableWidth))
        }

        return (items, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

// MARK: - Monitoring status

private struct MonitoringStatusLabel: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(isPulsing ? 0 : 0.35), lineWidth: 1)
                    .frame(width: 19, height: 19)
                    .scaleEffect(isPulsing ? 1.25 : 0.70)

                Circle()
                    .fill(Color.green)
                    .frame(width: 9, height: 9)
            }
            .frame(width: 19, height: 19)
            .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: isPulsing)
            .onAppear {
                isPulsing = true
            }

            Text("Monitoring")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkDeep.opacity(0.68))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monitoring")
    }
}

private struct LinkedInStatusBadge: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(aiEventAccent.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("LinkedIn match")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                Text("Alex Lee")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LinkedIn recommendation for Alex Lee")
    }
}

private struct XPostStatusBadge: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(aiEventAccent.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("X post ready")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                Text("@magicpatterns")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Magic Patterns X post suggestion")
    }
}

private struct WellBeingStudyLoadBadge: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(Color.green.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("Session recommended")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                Text("Study load is very high")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session recommended — study load is very high")
    }
}

private struct WellBeingStudyOverloadCard: View {
    let onDismiss: () -> Void
    @State private var showsBooking = false
    @State private var messageWords: [String] = []
    @State private var isMessageComplete = false

    private let message = "Your study load is very high this week. Talking it through with Dr. Sarah Lin can help you prioritise and avoid running low before exams."

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text("Well-being check-in")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer(minLength: 8)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss well-being suggestion")
            }
            .foregroundStyle(.green)

            FlowLayout(spacing: 4, rowSpacing: 4) {
                ForEach(Array(messageWords.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.78))
                        .transition(.opacity)
                }
            }

            if isMessageComplete {
                SkeuButton(tint: .green) {
                    showsBooking = true
                } label: {
                    Label("Book a Session", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.green.opacity(0.16), lineWidth: 1)
        )
        .sheet(isPresented: $showsBooking) {
            WellBeingBookingSheet()
        }
        .task { await streamMessage() }
    }

    private func streamMessage() async {
        messageWords = []
        isMessageComplete = false
        try? await Task.sleep(for: .seconds(2))

        for word in message.split(separator: " ").map(String.init) {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(65))
            withAnimation(.easeOut(duration: 0.18)) {
                messageWords.append(word)
            }
        }

        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            isMessageComplete = true
        }
    }
}

private struct WellBeingTimeSlot: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbolName: String

    static let all = [
        WellBeingTimeSlot(title: "Tomorrow, 10:00 AM", detail: "30 min with Dr. Sarah Lin", symbolName: "sunrise.fill"),
        WellBeingTimeSlot(title: "Thursday, 2:30 PM",  detail: "Before afternoon break",    symbolName: "clock.fill"),
        WellBeingTimeSlot(title: "Friday, 9:00 AM",    detail: "Morning availability",       symbolName: "calendar.badge.clock"),
    ]
}

private struct WellBeingBookingSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Book a Session")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text("Dr. Sarah Lin · Well-being counsellor")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.55))
            }

            VStack(spacing: 10) {
                ForEach(WellBeingTimeSlot.all) { slot in
                    Button { dismiss() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: slot.symbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(slot.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkDeep)
                                Text(slot.detail)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.inkDeep.opacity(0.55))
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.inkDeep.opacity(0.28))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(SkeuPressStyle())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgPrimary)
        .presentationDetents([.height(330), .medium])
        .presentationDragIndicator(.visible)
    }
}

private let revisionSuggestionAccent = Color(red: 0.94, green: 0.46, blue: 0.12)

private struct ComputingRevisionSuggestionBadge: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(revisionSuggestionAccent.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("Revision suggestion")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                Text("Privacy & security")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Revision suggestion: Privacy and security")
    }
}

private struct ComputingRevisionSuggestionCard: View {
    let onOpenNotes: () -> Void
    let onDismiss: () -> Void

    private let titleText   = "Revise computing privacy & security"
    private let reason1Text = "You're weaker on privacy & security than other Computing topics"
    private let reason2Text = "Your Computing test on Mon 25 May covers it"

    @State private var titleWords:   [String] = []
    @State private var titleComplete = false
    @State private var showIcon1     = false
    @State private var reason1Words: [String] = []
    @State private var showIcon2     = false
    @State private var reason2Words: [String] = []
    @State private var showButtons   = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader

            FlowLayout(spacing: 5, rowSpacing: 5) {
                ForEach(Array(titleWords.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                        .transition(.opacity)
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            if titleComplete {
                VStack(alignment: .leading, spacing: 12) {
                    reasonRow(symbol: "chart.bar.fill",                showsIcon: showIcon1, words: reason1Words)
                    reasonRow(symbol: "exclamationmark.triangle.fill", showsIcon: showIcon2, words: reason2Words)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(revisionSuggestionAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(revisionSuggestionAccent.opacity(0.15), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showButtons {
                VStack(spacing: 10) {
                    SkeuButton(tint: revisionSuggestionAccent, action: onOpenNotes) {
                        Label("Open notes", systemImage: "book.closed.fill")
                            .frame(maxWidth: .infinity)
                    }
                    ghostButton(label: "Dismiss", action: onDismiss)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(revisionSuggestionAccent.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(revisionSuggestionAccent.opacity(0.18), lineWidth: 1)
        )
        .task { await streamContent() }
    }

    private var cardHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
            Text("Revision suggestion")
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss suggestion")
        }
        .foregroundStyle(revisionSuggestionAccent)
    }

    private func reasonRow(symbol: String, showsIcon: Bool, words: [String]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(revisionSuggestionAccent)
                .frame(width: 22, height: 22)
                .padding(.top, 2)
                .opacity(showsIcon ? 1 : 0)
                .animation(.easeOut(duration: 0.20), value: showsIcon)

            FlowLayout(spacing: 4, rowSpacing: 4) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.78))
                        .transition(.opacity)
                }
            }
        }
    }

    private func ghostButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(revisionSuggestionAccent.opacity(0.75))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(revisionSuggestionAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(revisionSuggestionAccent.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(SkeuPressStyle())
    }

    // MARK: - Streaming

    private func streamContent() async {
        try? await Task.sleep(for: .seconds(1.2))
        guard !Task.isCancelled else { return }

        for word in titleText.split(separator: " ").map(String.init) {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(70))
            withAnimation(.easeOut(duration: 0.18)) { titleWords.append(word) }
        }

        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.22)) { titleComplete = true }

        try? await Task.sleep(for: .milliseconds(280))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.18)) { showIcon1 = true }
        for word in reason1Text.split(separator: " ").map(String.init) {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeOut(duration: 0.18)) { reason1Words.append(word) }
        }

        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.18)) { showIcon2 = true }
        for word in reason2Text.split(separator: " ").map(String.init) {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeOut(duration: 0.18)) { reason2Words.append(word) }
        }

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) { showButtons = true }
    }
}

private struct PracticeTestBadge: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(revisionSuggestionAccent.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("Practice test ready")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                Text("Computing · privacy & security")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Practice test suggestion for Computing")
    }
}

private struct PracticeTestCard: View {
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text("Practice test")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer(minLength: 8)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .foregroundStyle(revisionSuggestionAccent)

            Text("You scrolled through quickly — want to test yourself?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)
                .fixedSize(horizontal: false, vertical: true)

            Text("A short quiz can help make sure the content actually stuck.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.inkDeep.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                SkeuButton(tint: revisionSuggestionAccent, action: onStart) {
                    Label("Start practice test", systemImage: "pencil.and.list.clipboard")
                        .frame(maxWidth: .infinity)
                }
                Button(action: onDismiss) {
                    Text("Not now")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(revisionSuggestionAccent.opacity(0.75))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(revisionSuggestionAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(revisionSuggestionAccent.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(SkeuPressStyle())
            }
        }
        .padding(14)
        .background(revisionSuggestionAccent.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(revisionSuggestionAccent.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ComputingCatchUpStatusBadge: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                ZStack {
                    LinearGradient(
                        colors: [revisionWarmAccent.opacity(0.85), revisionWarmAccent],
                        startPoint: .top, endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [.white.opacity(0.28), .clear],
                        startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.54)
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.52), revisionWarmAccent.opacity(0.35)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text("Revision plan ready")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                Text("Computing B4 · 3 tasks")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing catch-up recommendation")
    }
}

// MARK: - Chevron toggle button

private struct ChevronToggle: View {
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.up")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.inkDeep.opacity(0.50))
                // Rotate to ↓ when expanded — spring-driven by isExpanded change
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.spring(response: 0.42, dampingFraction: 0.75), value: isExpanded)
                .frame(width: 34, height: 34)
                .background(toggleFill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(toggleBevel)
        }
        .buttonStyle(SkeuPressStyle())   // ← same spring bounce as SkeuButton / tab items
    }

    private var toggleFill: some View {
        ZStack {
            Color.bgTabBar
            LinearGradient(
                colors: [.white.opacity(0.34), .black.opacity(0.06)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var toggleBevel: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.58), .black.opacity(0.14)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 0.75
            )
    }
}

// MARK: - Send button

private struct SendButton: View {
    let hasText: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(sendFill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(sendBevel)
                .opacity(hasText ? 1.0 : 0.40)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: hasText)
        }
        .buttonStyle(SkeuPressStyle())
        .disabled(!hasText)
    }

    // Purple raised fill matching the AI badge
    private var sendFill: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.52, green: 0.28, blue: 0.92),
                         Color(red: 0.36, green: 0.16, blue: 0.72)],
                startPoint: .top, endPoint: .bottom
            )
            LinearGradient(
                colors: [.white.opacity(0.24), .clear],
                startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.52)
            )
        }
    }

    private var sendBevel: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.52), .black.opacity(0.20)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 0.75
            )
    }
}
