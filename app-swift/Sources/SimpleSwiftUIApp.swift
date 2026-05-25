import SwiftUI
import WebKit

@main
struct SimpleSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 460, minHeight: 580)
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}

// MARK: - App tabs

enum AppTab: Hashable, CaseIterable {
    case home
    case study
    case wellBeing
    case resume

    var title: String {
        switch self {
        case .home:     "Home"
        case .study:    "Study"
        case .wellBeing:"Well being"
        case .resume:   "Resume"
        }
    }

    var symbolName: String {
        switch self {
        case .home:     "house.fill"
        case .study:    "book.closed.fill"
        case .wellBeing:"heart.fill"
        case .resume:   "doc.text.fill"
        }
    }

    var tint: Color {
        switch self {
        case .home:     .blue
        case .study:    .indigo
        case .wellBeing:.green
        case .resume:   .orange
        }
    }
}

enum AIBarContext: Equatable {
    case magicPatternsEvent
    case computingCatchUpRecommendation
    case magicPatternsXPostRecommendation
    case computingHtmlNote
    case computingSpeedScroll
    case wellBeingStudyOverload
}

private let computingStudyTint = Color(red: 0.94, green: 0.46, blue: 0.12)
private let computingStudyWarmTint = Color(red: 0.94, green: 0.62, blue: 0.16)

// MARK: - Root

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var aiBarContext: AIBarContext?
    @State private var dimsAIBackdrop = false
    @State private var computingOverlayWords: [String] = []
    @State private var computingShowsOverlay = false
    @State private var hasBookedComputingConsult = false
    @State private var hasRunXPostSuggestion = false
    @State private var dateResetSuggestionRun = 0
    @State private var hasAddedComputingRecoveryTasks = false
    @State private var hasOpenedProfilePolish = false
    @State private var resumeHasXPost = false
    @State private var completedStudyTaskIDs: Set<UUID> = []
    @State private var isShowingDeveloperMenu = false
    @State private var developerReferenceDate = Date()
    @State private var isNoteDetailOpen = false
    @State private var showsNoteQuiz = false
    @State private var shouldOpenComputingNote = false
    @State private var noteQuizQuestions = Array(computingMCQs.prefix(3))

    var body: some View {
        ZStack {
            Color.bgPrimary
                .ignoresSafeArea()

            tabScene(.home) {
                HomeTabView(
                    hasAddedComputingRecoveryTasks: hasAddedComputingRecoveryTasks,
                    completedStudyTaskIDs: $completedStudyTaskIDs
                )
            }

            tabScene(.study) {
                StudyTabView(isNoteDetailOpen: $isNoteDetailOpen, aiBarContext: $aiBarContext, shouldOpenComputingNote: $shouldOpenComputingNote, onScrolledToEnd: {
                    noteQuizQuestions = Array(computingMCQs.prefix(3))
                    withAnimation(.snappy) { aiBarContext = .computingSpeedScroll }
                })
            }

            tabScene(.wellBeing) {
                WellBeingTabView(aiBarContext: $aiBarContext)
            }

            tabScene(.resume) {
                ResumeTabView(
                    aiBarContext: $aiBarContext,
                    hasOpenedProfilePolish: $hasOpenedProfilePolish,
                    resumeHasXPost: resumeHasXPost
                )
            }

            ZStack {
                if dimsAIBackdrop {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.68)
                        .transition(.opacity)
                }

                Color.black.opacity(dimsAIBackdrop ? 0.17 : 0)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.snappy, value: dimsAIBackdrop)

        }
        #if os(iOS)
        .overlay(alignment: .top) {
            StatusBarBlur()
        }
        #endif
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if showsNoteQuiz {
                    MCQPanel(tint: computingStudyTint, questions: noteQuizQuestions) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showsNoteQuiz = false }
                        if aiBarContext == .computingSpeedScroll { aiBarContext = nil }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    FloatingAIBar(
                        context: aiBarContext,
                        defaultPlaceholder: selectedTab == .study ? "Explain the difference…" : "Ask me anything…",
                        dimsBackground: $dimsAIBackdrop,
                        computingOverlayWords: $computingOverlayWords,
                        computingShowsOverlay: $computingShowsOverlay,
                        hasAddedComputingRecoveryTasks: $hasAddedComputingRecoveryTasks,
                        hasBookedComputingConsult: $hasBookedComputingConsult,
                        onOpenComputingNotes: {
                            selectedTab = .study
                            shouldOpenComputingNote = true
                        },
                        onStartPracticeTest: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                showsNoteQuiz = true
                            }
                        },
                        onAddXPostToResume: {
                            withAnimation(.snappy) { resumeHasXPost = true }
                        }
                    )
                    .offset(y: isNoteDetailOpen ? 76 : 0)
                }
                SkeuTabBar(selection: $selectedTab)
                    .offset(y: isNoteDetailOpen ? 200 : 0)
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.80), value: isNoteDetailOpen)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showsNoteQuiz)
        }
        .overlay {
            if computingShowsOverlay {
                Color.bgPrimary
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ComputingCatchUpCard(
                                words: computingOverlayWords,
                                isStreamingComplete: true,
                                startsConfirmed: true,
                                onCompleteRecoveryForm: {
                                    hasBookedComputingConsult = true
                                    hasAddedComputingRecoveryTasks = true
                                },
                                onDismiss: {
                                    withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                                        computingShowsOverlay = false
                                        computingOverlayWords = []
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            Spacer()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.50, dampingFraction: 0.82), value: computingShowsOverlay)
        #if os(iOS)
        .background {
            ShakeDetector {
                withAnimation(.snappy) {
                    isShowingDeveloperMenu = true
                }
            }
        }
        #endif
        .sheet(isPresented: $isShowingDeveloperMenu) {
            DeveloperMenuView(
                selectedTab: selectedTab,
                aiBarContext: aiBarContext,
                referenceDate: developerReferenceDate,
                resetDate: resetDate,
                resetAppState: resetAppState
            )
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == .study { isNoteDetailOpen = false; showsNoteQuiz = false }
            switch newValue {
            case .resume:
                aiBarContext = nil
                break
            case .home:
                showHomeRevisionSuggestionIfNeeded()
            case .study:
                aiBarContext = .computingHtmlNote
            case .wellBeing:
                aiBarContext = nil
            }
        }
        .task {
            showHomeRevisionSuggestionIfNeeded()
        }
        .task(id: dateResetSuggestionRun) {
            guard dateResetSuggestionRun > 0, !hasRunXPostSuggestion else { return }

            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, !hasRunXPostSuggestion else { return }

            withAnimation(.snappy) {
                hasRunXPostSuggestion = true
                aiBarContext = .magicPatternsXPostRecommendation
            }
        }
    }

    private func resetAppState() {
        selectedTab = .home
        aiBarContext = nil
        hasBookedComputingConsult = false
        hasRunXPostSuggestion = false
        hasAddedComputingRecoveryTasks = false
        hasOpenedProfilePolish = false
        resumeHasXPost = false
        completedStudyTaskIDs = []
        computingShowsOverlay = false
        computingOverlayWords = []
        showHomeRevisionSuggestionIfNeeded()
    }

    private func showHomeRevisionSuggestionIfNeeded() {
        guard selectedTab == .home,
              !hasBookedComputingConsult,
              !hasAddedComputingRecoveryTasks
        else { return }

        withAnimation(.snappy) {
            aiBarContext = .computingCatchUpRecommendation
        }
    }

    private func resetDate() {
        developerReferenceDate = Date()
        guard !hasRunXPostSuggestion else { return }
        dateResetSuggestionRun += 1
    }

    @ViewBuilder
    private func tabScene<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary)
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .transaction(value: selectedTab) { transaction in
                transaction.disablesAnimations = true
            }
    }
}

private struct StatusBarBlur: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(height: 72)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black.opacity(0.92), location: 0.55),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }
}

// MARK: - Tab screens

private struct HomeTabView: View {
    let hasAddedComputingRecoveryTasks: Bool
    @Binding var completedStudyTaskIDs: Set<UUID>
    @State private var homeTab: HomeViewTab = .calendar

    enum HomeViewTab: String, CaseIterable {
        case calendar = "Calendar"
        case tasks    = "Tasks"
    }

    var body: some View {
        AppTabScreen(
            title: "Home",
            subtitle: Date().formatted(.dateTime.weekday(.wide).month(.wide).day()),
            symbolName: "sparkles",
            tint: .blue,
            showsHeader: false
        ) {
            VStack(spacing: 22) {
                HomeStreakCard()

                Picker("View", selection: $homeTab) {
                    ForEach(HomeViewTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if homeTab == .calendar {
                    TodayStudyPlanWidget()
                } else {
                    TaskTrackingSection(
                        hasAddedComputingRecoveryTasks: hasAddedComputingRecoveryTasks,
                        completedStudyTaskIDs: $completedStudyTaskIDs
                    )
                }
            }
        }
    }
}

private struct SubjectNote: Identifiable {
    let id = UUID()
    let subject: String
    let symbolName: String
    let tint: Color
    let lines: [String]
}

private let studyNotes: [SubjectNote] = [
    SubjectNote(
        subject: "Physics",
        symbolName: "atom",
        tint: .blue,
        lines: [
            "Newton's 2nd law: F = ma",
            "Work done: W = Fd cosθ",
            "Conservation of energy",
            "Wave speed: v = fλ",
            "Ohm's law: V = IR",
        ]
    ),
    SubjectNote(
        subject: "Chemistry",
        symbolName: "flask.fill",
        tint: .green,
        lines: [
            "Moles: n = m / Mr",
            "Ideal gas: pV = nRT",
            "Oxidation state rules",
            "Le Chatelier's principle",
            "Enthalpy: ΔH = mcΔT",
        ]
    ),
    SubjectNote(
        subject: "Computing",
        symbolName: "cpu.fill",
        tint: computingStudyTint,
        lines: [
            "Binary search: O(log n)",
            "Bubble sort: O(n²)",
            "Stack vs queue LIFO/FIFO",
            "Recursion base cases",
            "Boolean logic gates",
        ]
    ),
]

private struct NoteCard: View {
    let note: SubjectNote
    let namespace: Namespace.ID
    @Binding var selectedNote: SubjectNote?

    private var isSelected: Bool { selectedNote?.id == note.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: note.symbolName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(note.tint.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Text(note.subject)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text("\(note.lines.count) revision notes")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.52))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }

            SkeuButton(tint: note.tint, action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.50, dampingFraction: 0.78)) {
                        selectedNote = note
                    }
                }
            }) {
                Text("Open")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 152, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(note.tint.opacity(0.18), lineWidth: 1)
        )
        .matchedGeometryEffect(id: note.id, in: namespace)
        .opacity(isSelected ? 0 : 1)
    }
}

private struct SubjectNoteGridCard: View {
    let note: SubjectNote
    let namespace: Namespace.ID
    @Binding var selectedNote: SubjectNote?

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                selectedNote = note
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: note.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(note.tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(note.subject)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(note.tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct QuickReferenceRow: View {
    let note: SubjectNote
    let namespace: Namespace.ID
    @Binding var selectedNote: SubjectNote?

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                selectedNote = note
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: note.symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(note.tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(note.subject)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                    Text(note.lines.prefix(2).joined(separator: "  ·  "))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.40))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkDeep.opacity(0.20))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#if os(iOS)
private struct HTMLWebView: UIViewRepresentable {
    let html: String
    var onQuickScrollToEnd: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(onQuickScrollToEnd: onQuickScrollToEnd) }

    func makeUIView(context: Context) -> WKWebView {
        let ctrl = WKUserContentController()
        ctrl.add(context.coordinator, name: "quickScrollReached")
        let cfg = WKWebViewConfiguration()
        cfg.userContentController = ctrl
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.scrollView.backgroundColor = .clear
        wv.isOpaque = false
        wv.navigationDelegate = context.coordinator
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        uiView.loadHTMLString(html, baseURL: nil)
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onQuickScrollToEnd: (() -> Void)?
        var loadedHTML: String?
        init(onQuickScrollToEnd: (() -> Void)?) { self.onQuickScrollToEnd = onQuickScrollToEnd }

        func userContentController(_ ctrl: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "quickScrollReached" else { return }
            DispatchQueue.main.async { self.onQuickScrollToEnd?() }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function(){
                var fired = false;
                window.addEventListener('scroll', function(){
                    if (fired) return;
                    var bot = window.scrollY + window.innerHeight;
                    var h   = document.documentElement.scrollHeight;
                    if (h <= window.innerHeight) return;
                    if (bot / h >= 0.92) {
                        fired = true;
                        window.webkit.messageHandlers.quickScrollReached.postMessage('end');
                    }
                }, { passive: true });
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
#endif

private struct NoteDetailView: View {
    let note: SubjectNote
    let namespace: Namespace.ID
    let onScrolledToEnd: () -> Void
    let dismiss: () -> Void

    @ViewBuilder private var noteContent: some View {
        #if os(iOS)
        if note.subject == "Computing" {
            HTMLWebView(html: computingSecurityNotesHTML, onQuickScrollToEnd: onScrolledToEnd)
                .ignoresSafeArea(edges: .bottom)
                .padding(.top, 100)
        } else {
            defaultScrollContent
        }
        #else
        defaultScrollContent
        #endif
    }

    private var defaultScrollContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: note.symbolName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 90, height: 90)
                    .background(note.tint.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(note.subject)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)

                SectionPanel(title: "Notes") {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(note.lines.enumerated()), id: \.offset) { index, line in
                            if index > 0 { RowDivider() }
                            Text(line)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.inkDeep)
                                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 80)
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity)
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.bgPrimary.ignoresSafeArea()

            noteContent

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.inkDeep.opacity(0.55))
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.07), in: Circle())
            }
            .padding(.top, 56)
            .padding(.trailing, 20)

        }
        .matchedGeometryEffect(id: note.id, in: namespace)
        .ignoresSafeArea()
    }
}

private struct StudyTabView: View {
    @Binding var isNoteDetailOpen: Bool
    @Binding var aiBarContext: AIBarContext?
    @Binding var shouldOpenComputingNote: Bool
    let onScrolledToEnd: () -> Void
    @State private var selectedNote: SubjectNote?
    @State private var searchText = ""
    @Namespace private var heroNamespace

    private var filteredNotes: [SubjectNote] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return studyNotes.filter {
            $0.subject.lowercased().contains(q) ||
            $0.lines.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.bgPrimary.ignoresSafeArea()

                if searchText.isEmpty {
                    defaultStudyView
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            studyHeader.padding(.bottom, 4)
                            searchBar

                            if filteredNotes.isEmpty {
                                Text("No notes match \"\(searchText)\"")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.inkDeep.opacity(0.38))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 24)
                            } else {
                                ForEach(filteredNotes) { note in
                                    NoteCard(note: note, namespace: heroNamespace, selectedNote: $selectedNote)
                                }
                            }
                        }
                        .frame(maxWidth: 620, alignment: .leading)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 180)
                    }
                    .scrollContentBackground(.hidden)
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .overlay {
            if let note = selectedNote {
                NoteDetailView(note: note, namespace: heroNamespace, onScrolledToEnd: onScrolledToEnd) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        selectedNote = nil
                    }
                }
            }
        }
        .onChange(of: selectedNote?.id) { _, id in
            withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                isNoteDetailOpen = id != nil
            }
            if id != nil, selectedNote?.subject == "Computing" {
                aiBarContext = .computingHtmlNote
            } else if id == nil, aiBarContext == .computingHtmlNote {
                aiBarContext = nil
            }
        }
        .onChange(of: shouldOpenComputingNote) { _, open in
            guard open else { return }
            shouldOpenComputingNote = false
            if let note = studyNotes.first(where: { $0.subject == "Computing" }) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    selectedNote = note
                }
            }
        }
    }

    private var defaultStudyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                studyHeader.padding(.bottom, 2)
                searchBar

                VStack(alignment: .leading, spacing: 12) {
                    Label("Subjects", systemImage: "books.vertical.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.45))
                        .textCase(.uppercase)
                        .tracking(0.4)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(studyNotes) { note in
                            SubjectNoteGridCard(note: note, namespace: heroNamespace, selectedNote: $selectedNote)
                        }
                    }
                }

            }
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 180)
        }
        .scrollContentBackground(.hidden)
        .transition(.opacity)
    }

    private var studyHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(computingStudyTint.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text("Study")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.inkDeep.opacity(0.38))
            TextField("Search notes…", text: $searchText)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color.inkDeep)
            if !searchText.isEmpty {
                Button {
                    withAnimation(.snappy) { searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkDeep.opacity(0.30))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.09), lineWidth: 1)
        )
    }
}

// MARK: - Well-being data models

private struct WellBeingSession: Identifiable {
    let id = UUID()
    let counsellor: String
    let date: Date
    let duration: Int
    let summary: String
    let actions: [(String, String, String)]
}

private let mockWellBeingSessions: [WellBeingSession] = [
    WellBeingSession(
        counsellor: "Dr. Sarah Lin",
        date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        duration: 45,
        summary: "Discussed exam-period stress and revision strategies. Agreed on a structured break schedule and wind-down routine before sleep.",
        actions: [
            ("Wind-down routine", "30 min before sleep", "moon.stars.fill"),
            ("Structured breaks",  "Every 90 min of study", "timer"),
        ]
    ),
]

private enum MoodOption: Int, CaseIterable {
    case burnt, low, okay, good, great

    var label: String {
        switch self {
        case .burnt: return "Burnt"
        case .low:   return "Low"
        case .okay:  return "Okay"
        case .good:  return "Good"
        case .great: return "Great"
        }
    }

    var symbolName: String {
        switch self {
        case .burnt: return "flame.fill"
        case .low:   return "battery.25"
        case .okay:  return "minus.circle.fill"
        case .good:  return "sun.max.fill"
        case .great: return "star.fill"
        }
    }

    var tint: Color {
        switch self {
        case .burnt: return Color(red: 0.90, green: 0.18, blue: 0.18)
        case .low:   return Color(red: 0.94, green: 0.46, blue: 0.10)
        case .okay:  return Color(red: 0.88, green: 0.68, blue: 0.08)
        case .good:  return Color(red: 0.22, green: 0.72, blue: 0.36)
        case .great: return Color(red: 0.10, green: 0.56, blue: 0.26)
        }
    }

    var emoji: String {
        switch self {
        case .burnt: return "😩"
        case .low:   return "😕"
        case .okay:  return "😐"
        case .good:  return "🙂"
        case .great: return "😄"
        }
    }

    var feedbackMessage: String {
        switch self {
        case .burnt: return "It sounds really tough right now. Consider reaching out to Dr. Sarah Lin for support."
        case .low:   return "Take it one step at a time. A short walk or break can make a real difference."
        case .okay:  return "Steady is solid. Keep your routines in place and rest when you can."
        case .good:  return "That's great to hear — keep up the momentum and don't skip rest."
        case .great: return "Excellent! You're in a strong place. Carry that energy into your week."
        }
    }
}

private enum StudyLoadOption: Int, CaseIterable {
    case light, manageable, heavy, overwhelming

    var label: String {
        switch self {
        case .light:        return "Light"
        case .manageable:   return "Okay"
        case .heavy:        return "Heavy"
        case .overwhelming: return "A lot"
        }
    }

    var symbolName: String {
        switch self {
        case .light:        return "leaf.fill"
        case .manageable:   return "checkmark.circle.fill"
        case .heavy:        return "books.vertical.fill"
        case .overwhelming: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .light:        return Color(red: 0.10, green: 0.56, blue: 0.26)
        case .manageable:   return Color(red: 0.22, green: 0.72, blue: 0.36)
        case .heavy:        return Color(red: 0.94, green: 0.46, blue: 0.10)
        case .overwhelming: return Color(red: 0.90, green: 0.18, blue: 0.18)
        }
    }

    var riskOffset: Double {
        switch self {
        case .light:        return -0.08
        case .manageable:   return  0.00
        case .heavy:        return  0.12
        case .overwhelming: return  0.22
        }
    }
}

// MARK: - Well-being tab

private struct WellBeingTabView: View {
    @Binding var aiBarContext: AIBarContext?
    @State private var selectedMood: MoodOption?
    @State private var selectedStudyLoad: StudyLoadOption?
    @State private var showNewSession = false
    @State private var sessionDetail: WellBeingSession?

    var body: some View {
        AppTabScreen(title: "Well-being", symbolName: "heart.fill", tint: .green) {
            VStack(spacing: 22) {
                CounsellorSessionsPanel(showNew: $showNewSession, sessionDetail: $sessionDetail)
                WeeklyCheckUpPanel(selectedMood: $selectedMood, selectedStudyLoad: $selectedStudyLoad)
                BurnoutRiskPanel(mood: selectedMood, studyLoad: selectedStudyLoad)
            }
        }
        .sheet(isPresented: $showNewSession) { NewSessionSheet() }
        .sheet(item: $sessionDetail) { SessionDetailSheet(session: $0) }
        .onChange(of: selectedStudyLoad) { _, load in
            withAnimation(.snappy) {
                if load == .overwhelming {
                    aiBarContext = .wellBeingStudyOverload
                } else if aiBarContext == .wellBeingStudyOverload {
                    aiBarContext = nil
                }
            }
        }
    }
}

// MARK: - Section 1: Counsellor Sessions

private struct CounsellorSessionsPanel: View {
    @Binding var showNew: Bool
    @Binding var sessionDetail: WellBeingSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Sessions")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(mockWellBeingSessions.enumerated()), id: \.element.id) { index, session in
                    if index > 0 { RowDivider() }
                    Button { sessionDetail = session } label: {
                        WellBeingSessionRow(session: session)
                    }
                    .buttonStyle(SkeuPressStyle())
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
            )

            SkeuButton(tint: .green, action: { showNew = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Book New Session")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WellBeingSessionRow: View {
    let session: WellBeingSession

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 42, height: 42)
                .background(Color.green.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.counsellor)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text(session.summary)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(session.date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
                Text("\(session.duration) min")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.36))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .padding(.vertical, 8)
    }
}

// MARK: - Section 2: Weekly Check-up

private struct WeeklyCheckUpPanel: View {
    @Binding var selectedMood: MoodOption?
    @Binding var selectedStudyLoad: StudyLoadOption?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Weekly Check-Up")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 22) {
                // Mood
                VStack(alignment: .leading, spacing: 14) {
                    Text("How are you feeling this week?")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)

                    EmojiMoodPicker(selection: $selectedMood)

                    if let mood = selectedMood {
                        MoodFeedbackBanner(mood: mood)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedMood)

                Rectangle()
                    .fill(Color.black.opacity(0.07))
                    .frame(height: 1)

                // Study load
                VStack(alignment: .leading, spacing: 14) {
                    Text("How's your study load?")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)

                    HStack(spacing: 8) {
                        ForEach(StudyLoadOption.allCases, id: \.rawValue) { option in
                            MoodOptionButton(
                                symbolName: option.symbolName,
                                label: option.label,
                                tint: option.tint,
                                isSelected: selectedStudyLoad == option,
                                number: option.rawValue + 1,
                                onSelect: {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
                                        selectedStudyLoad = selectedStudyLoad == option ? nil : option
                                    }
                                }
                            )
                        }
                    }

                }
                .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedStudyLoad)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoodOptionButton: View {
    let symbolName: String
    let label: String
    let tint: Color
    let isSelected: Bool
    var number: Int? = nil
    let onSelect: () -> Void

    init(mood: MoodOption, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.symbolName = mood.symbolName
        self.label = mood.label
        self.tint = mood.tint
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    init(symbolName: String, label: String, tint: Color, isSelected: Bool, number: Int? = nil, onSelect: @escaping () -> Void) {
        self.symbolName = symbolName
        self.label = label
        self.tint = tint
        self.isSelected = isSelected
        self.number = number
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                ZStack {
                    tint.opacity(isSelected ? 1.0 : 0.10)
                    if isSelected {
                        LinearGradient(
                            colors: [Color.white.opacity(0.26), Color.black.opacity(0.08)],
                            startPoint: .top, endPoint: .bottom
                        )
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.30), .clear],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.48)
                            ))
                    }
                    if let n = number {
                        Text("\(n)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? .white : tint)
                    } else {
                        Image(systemName: symbolName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : tint)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? LinearGradient(colors: [.white.opacity(0.52), .black.opacity(0.22)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.black.opacity(0.10), .black.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? tint.opacity(0.32) : .black.opacity(0.06),
                    radius: isSelected ? 6 : 1,
                    x: 0, y: isSelected ? 3 : 1
                )

                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? tint : Color.inkDeep.opacity(0.48))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SkeuPressStyle())
    }
}

private struct EmojiMoodPicker: View {
    @Binding var selection: MoodOption?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MoodOption.allCases, id: \.rawValue) { mood in
                let isSelected = selection == mood
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
                        selection = isSelected ? nil : mood
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(mood.emoji)
                            .font(.system(size: isSelected ? 36 : 28))
                            .animation(.spring(response: 0.28, dampingFraction: 0.60), value: selection)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(SkeuPressStyle())
            }
        }
    }
}

private struct MoodFeedbackBanner: View {
    let mood: MoodOption

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(mood.tint)
            Text(mood.feedbackMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkDeep.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(mood.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(mood.tint.opacity(0.24), lineWidth: 1)
        )
    }
}

// MARK: - Section 3: Burnout Risk

private struct BurnoutRiskPanel: View {
    let mood: MoodOption?
    let studyLoad: StudyLoadOption?

    private var riskScore: Double {
        let moodOffset: Double = switch mood {
        case .burnt: 0.22
        case .low:   0.10
        case .okay:  0.00
        case .good:  -0.06
        case .great: -0.10
        case nil:    0.00
        }
        let loadOffset = studyLoad?.riskOffset ?? 0.0
        return min(1.0, max(0.0, 0.22 + moodOffset + loadOffset))
    }

    private var riskLabel: String {
        switch riskScore {
        case ..<0.34: return "Low"
        case ..<0.67: return "Moderate"
        default:      return "High"
        }
    }

    private var riskColor: Color {
        switch riskScore {
        case ..<0.34: return .green
        case ..<0.67: return .orange
        default:      return Color(red: 0.90, green: 0.18, blue: 0.18)
        }
    }

    private let factors: [(String, String, String, Color)] = [
        ("Study load", "High intensity week", "book.fill",         Color(red: 0.94, green: 0.46, blue: 0.12)),
        ("Breaks",     "On track",            "pause.circle.fill", Color(red: 0.10, green: 0.56, blue: 0.26)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Burnout Risk")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Spacer()
                // Skeu badge
                Text(riskLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        ZStack {
                            riskColor
                            LinearGradient(
                                colors: [.white.opacity(0.24), .black.opacity(0.10)],
                                startPoint: .top, endPoint: .bottom
                            )
                        }
                    }
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.46), .black.opacity(0.20)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    )
                    .shadow(color: riskColor.opacity(0.34), radius: 4, x: 0, y: 2)
                    .animation(.spring(response: 0.50, dampingFraction: 0.80), value: riskScore)
            }

            VStack(alignment: .leading, spacing: 18) {
                BurnoutGauge(score: riskScore, color: riskColor)

                Rectangle()
                    .fill(Color.black.opacity(0.07))
                    .frame(height: 1)

                VStack(spacing: 0) {
                    ForEach(Array(factors.enumerated()), id: \.offset) { index, factor in
                        if index > 0 { RowDivider() }
                        BurnoutFactorRow(title: factor.0, detail: factor.1, symbolName: factor.2, tint: factor.3)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BurnoutGauge: View {
    let score: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let thumbSize: CGFloat = 22
                let trackHeight: CGFloat = 14
                let usableWidth = geo.size.width - thumbSize

                ZStack(alignment: .leading) {
                    // Gradient track
                    RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.green, Color(red: 0.96, green: 0.78, blue: 0.10), .orange, Color(red: 0.90, green: 0.18, blue: 0.18)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [.white.opacity(0.30), .clear],
                                    startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.60)
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(colors: [.white.opacity(0.40), .black.opacity(0.16)], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                        )
                        .frame(height: trackHeight)
                        .offset(y: (thumbSize - trackHeight) / 2)

                    // Thumb
                    ZStack {
                        Circle().fill(Color.white)
                            .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
                        Circle().fill(color).padding(5)
                        Circle().strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.70), .black.opacity(0.20)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5
                        )
                    }
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: usableWidth * score)
                    .animation(.spring(response: 0.62, dampingFraction: 0.72), value: score)
                }
                .frame(height: thumbSize)
            }
            .frame(height: 22)

            HStack {
                Text("Low risk")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.36))
                Spacer()
                Text("High risk")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.36))
            }
        }
    }
}

private struct BurnoutFactorRow: View {
    let title: String
    let detail: String
    let symbolName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkDeep)

            Spacer(minLength: 8)

            Text(detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkDeep.opacity(0.52))
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// MARK: - New Session Sheet

private struct NewSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedType = 0
    private let sessionTypes = ["In-person", "Video call", "Phone call"]
    private let sessionSymbols = ["person.2.fill", "video.fill", "phone.fill"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Skeu icon header
                    HStack(spacing: 16) {
                        ZStack {
                            Color.green
                            LinearGradient(
                                colors: [.white.opacity(0.26), .black.opacity(0.08)],
                                startPoint: .top, endPoint: .bottom
                            )
                            Image(systemName: "person.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(colors: [.white.opacity(0.52), .black.opacity(0.22)], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.green.opacity(0.28), radius: 8, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Book a Session")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.inkDeep)
                            Text("Dr. Sarah Lin · Counsellor")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.inkDeep.opacity(0.52))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    SectionPanel(title: "Preferred date & time") {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    }

                    SectionPanel(title: "Session type") {
                        ForEach(sessionTypes.indices, id: \.self) { i in
                            if i > 0 { RowDivider() }
                            Button {
                                withAnimation(.snappy) { selectedType = i }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: sessionSymbols[i])
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.green)
                                        .frame(width: 36, height: 36)
                                        .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    Text(sessionTypes[i])
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.inkDeep)
                                    Spacer()
                                    if selectedType == i {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.green)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SkeuButton(tint: .green, action: { dismiss() }) {
                        Text("Request Session").frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.inkDeep.opacity(0.44))
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.07), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Session Detail Sheet

private struct SessionDetailSheet: View {
    let session: WellBeingSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 16) {
                        ZStack {
                            Color.green
                            LinearGradient(
                                colors: [.white.opacity(0.26), .black.opacity(0.08)],
                                startPoint: .top, endPoint: .bottom
                            )
                            Image(systemName: "person.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(colors: [.white.opacity(0.52), .black.opacity(0.22)], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.green.opacity(0.28), radius: 8, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(session.counsellor)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.inkDeep)
                            Text(session.date.formatted(.dateTime.weekday(.wide).month(.wide).day()) + " · \(session.duration) min")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.inkDeep.opacity(0.52))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    SectionPanel(title: "Session notes") {
                        Text(session.summary)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.inkDeep.opacity(0.80))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16)
                    }

                    SectionPanel(title: "Follow-up actions") {
                        ForEach(Array(session.actions.enumerated()), id: \.offset) { index, action in
                            if index > 0 { RowDivider() }
                            TaskRow(title: action.0, detail: action.1, symbolName: action.2)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 60)
            }
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.inkDeep.opacity(0.44))
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.07), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct ResumeTabView: View {
    @Binding var aiBarContext: AIBarContext?
    @Binding var hasOpenedProfilePolish: Bool
    let resumeHasXPost: Bool
    @State private var showPolishSheet = false
    @State private var showResumeSheet = false
    @State private var appliedSuggestions: Set<UUID> = []

    var body: some View {
        AppTabScreen(title: "Resume", symbolName: "doc.text.fill", tint: .orange) {
            VStack(spacing: 22) {
                Button {
                    hasOpenedProfilePolish = true
                    showPolishSheet = true
                } label: {
                    HeroPanel(
                        title: "Polish the profile",
                        subtitle: "Review your latest experience bullets and tailor the summary for the next role.",
                        tint: .orange,
                        symbolName: "briefcase.fill",
                        size: .compact
                    )
                }
                .buttonStyle(SkeuPressStyle())

                SectionPanel(title: "Events", description: "Events related to your education path.") {
                    NavigationLink {
                        MagicPatternsEventView(aiBarContext: $aiBarContext)
                    } label: {
                        TaskRow(title: "Magic Patterns", detail: "AI-related event", symbolName: "sparkles")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        FutureHackEventView()
                    } label: {
                        TaskRow(title: "AWS Accelerator Competition", detail: "Competition attended", symbolName: "trophy.fill")
                    }
                    .buttonStyle(.plain)
                }

                CertificationSuggestionsSection(suggestions: CertificationSuggestion.resumeSuggestions)

                SkeuButton(tint: .orange, action: { showResumeSheet = true }) {
                    Text("View Resume")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showPolishSheet) {
            PolishProfileSheet(appliedSuggestions: $appliedSuggestions)
        }
        .sheet(isPresented: $showResumeSheet) {
            ResumeDocumentSheet(
                hasXPostEntry: resumeHasXPost,
                appliedSuggestions: appliedSuggestions
            )
        }
    }
}

// MARK: - Resume Document

private struct ResumeDocumentSheet: View {
    let hasXPostEntry: Bool
    let appliedSuggestions: Set<UUID>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ResumeDocumentView(hasXPostEntry: hasXPostEntry, appliedSuggestions: appliedSuggestions)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .navigationTitle("Resume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct ResumeDocumentView: View {
    let hasXPostEntry: Bool
    let appliedSuggestions: Set<UUID>

    private var skillsText: String {
        appliedSuggestions.isEmpty
            ? "Python · SwiftUI · AI · teamwork"
            : "Python for data-processing scripts · SwiftUI for iOS study tools · AI prompt design · teamwork from shipping projects with classmates"
    }

    private var experienceBullets: [String] {
        var bullets: [String] = [
            "Competed in AWS Accelerator Competition, developing an AI prototype under time pressure and presenting a generative-AI workflow solution.",
        ]
        if hasXPostEntry {
            bullets.insert(
                "Engaged with @magicpatterns on X — reviewed their AI-native design tooling and connected their methodology to practical UI prototyping workflows.",
                at: 0
            )
        }
        if !appliedSuggestions.isEmpty {
            bullets[bullets.count - 1] = "Competed in an AI innovation competition, developing a prototype concept under time pressure and presenting how generative AI could solve a real student workflow problem."
        }
        return bullets
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Resume")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Spacer()
                if hasXPostEntry || !appliedSuggestions.isEmpty {
                    Label("Updated", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.62, blue: 0.32))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.snappy, value: hasXPostEntry)
            .animation(.snappy, value: appliedSuggestions.isEmpty)
            .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 18) {
                // Header block
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kyran Smith")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                    Text("A-level student · Computing, Physics, Chemistry")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.55))
                }

                ResumeDivider()

                // Profile
                ResumeSection(title: "Profile") {
                    Text("Computing student with hands-on experience building iOS apps in SwiftUI, competing in AI innovation challenges, and engaging with the AI-design community. Focused on building practical, real-world software and staying current with emerging tooling.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.80))
                        .fixedSize(horizontal: false, vertical: true)
                }

                ResumeDivider()

                // Skills
                ResumeSection(title: "Skills") {
                    Text(skillsText)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.80))
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.snappy, value: skillsText)
                }

                ResumeDivider()

                // Experience
                ResumeSection(title: "Experience") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(experienceBullets.enumerated()), id: \.offset) { _, bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 5)
                                Text(bullet)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.inkDeep.opacity(0.80))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: experienceBullets.count)
                }
            }
            .padding(18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.18), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ResumeSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.orange)
                .tracking(1.2)
            content()
        }
    }
}

private struct ResumeDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.07))
            .frame(height: 1)
    }
}

// MARK: - Polish Profile Sheet

private struct ResumeSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let reason: String
    let extract: String
    let highlightedWord: String
    let fix: String
    var applied: Bool = false
}

private struct CertificationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let provider: String
    let detail: String
    let tint: Color
    let symbolName: String
}

private extension CertificationSuggestion {
    static let resumeSuggestions: [CertificationSuggestion] = [
        CertificationSuggestion(
            title: "AI Fundamentals Certificate",
            provider: "Microsoft Learn",
            detail: "Add an intro AI credential covering responsible AI, machine learning basics, and everyday AI tools.",
            tint: .blue,
            symbolName: "sparkles"
        ),
        CertificationSuggestion(
            title: "Generative AI Essentials",
            provider: "Coursera",
            detail: "Build resume-ready proof in prompt design, evaluation, and safe use of generative AI.",
            tint: computingStudyWarmTint,
            symbolName: "brain.head.profile"
        ),
    ]
}

private extension ResumeSuggestion {
    static let all: [ResumeSuggestion] = [
        ResumeSuggestion(
            title: "Turn skills into proof",
            reason: "A plain skills list is easy to ignore. Tie each skill to a project, tool, or outcome so the reader can see how you actually used it.",
            extract: "Skills: Python, SwiftUI, AI, teamwork.",
            highlightedWord: "Skills:",
            fix: "Technical skills: Python for data-processing scripts, SwiftUI for building iOS study tools, AI prompt design for prototype workflows, and teamwork from shipping projects with classmates."
        ),
        ResumeSuggestion(
            title: "Frame competitions as achievement",
            reason: "Attending a competition is a start, but the resume should explain the challenge, what you contributed, and what it shows about your ability to learn fast.",
            extract: "Attended an AI competition.",
            highlightedWord: "Attended",
            fix: "Competed in an AI innovation competition, developing a prototype concept under time pressure and presenting how generative AI could solve a real student workflow problem."
        ),
        ResumeSuggestion(
            title: "Show iteration after launch",
            reason: "A stronger resume does more than say an app exists. Mention feedback, fixes, and measurable improvements to show you kept improving the product after the first version.",
            extract: "Created a revision planner app for students.",
            highlightedWord: "Created",
            fix: "Created and iterated a SwiftUI revision planner app with task tracking, study sessions, and progress summaries; used peer feedback to simplify navigation and cut plan setup time from 5 minutes to under 1 minute."
        ),
    ]
}

private struct PolishProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var appliedSuggestions: Set<UUID>
    @State private var suggestions = ResumeSuggestion.all

    private var allApplied: Bool { suggestions.allSatisfy(\.applied) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(suggestions.indices, id: \.self) { index in
                            SuggestionCard(suggestion: $suggestions[index])
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .scrollContentBackground(.hidden)
                .background(Color.bgPrimary)

                // Sticky Apply All bar
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.bgPrimary.opacity(0), Color.bgPrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 28)

                    VStack {
                        SkeuButton(tint: allApplied ? Color(red: 0.18, green: 0.62, blue: 0.32) : .orange) {
                            withAnimation(.snappy) {
                                for i in suggestions.indices { suggestions[i].applied = true }
                                appliedSuggestions = Set(suggestions.map(\.id))
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: allApplied ? "checkmark.circle.fill" : "wand.and.sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                                    .contentTransition(.symbolEffect(.replace))
                                Text(allApplied ? "All changes applied" : "Apply all suggestions")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .disabled(allApplied)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                    .background(Color.bgPrimary)
                }
            }
            .navigationTitle("Polish the Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: suggestions) { _, updated in
            let ids = Set(updated.filter(\.applied).map(\.id))
            if ids != appliedSuggestions {
                appliedSuggestions = ids
            }
        }
    }
}

private struct SuggestionCard: View {
    @Binding var suggestion: ResumeSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: suggestion.applied ? "checkmark.circle.fill" : "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(suggestion.applied ? Color(red: 0.18, green: 0.62, blue: 0.32) : .orange)
                    .contentTransition(.symbolEffect(.replace))
                Text(suggestion.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Spacer()
            }

            // Reason
            Text(suggestion.reason)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Doc-style extract
            DocExtractView(
                extract: suggestion.extract,
                highlightedWord: suggestion.highlightedWord,
                fix: suggestion.fix,
                applied: suggestion.applied
            )

            // Action button
            if !suggestion.applied {
                HStack {
                    Spacer()
                    SkeuButton(tint: .orange) {
                        withAnimation(.snappy) { suggestion.applied = true }
                    } label: {
                        Label("Apply change", systemImage: "pencil.and.sparkles")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    suggestion.applied
                        ? Color(red: 0.18, green: 0.62, blue: 0.32).opacity(0.35)
                        : Color.orange.opacity(0.18),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// Google-Docs-style document viewer showing tracked changes
private struct DocExtractView: View {
    let extract: String
    let highlightedWord: String
    let fix: String
    let applied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Page rule at top
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 14) {
                // Original line with highlight
                if applied {
                    Text(extract)
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(Color.inkDeep.opacity(0.32))
                        .strikethrough(true, color: Color(red: 0.80, green: 0.18, blue: 0.18).opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(5)
                } else {
                    DocHighlightedText(full: extract, highlighted: highlightedWord)
                }

                // Suggested insertion (always visible — track-changes preview)
                HStack(alignment: .top, spacing: 0) {
                    Rectangle()
                        .fill(applied
                              ? Color(red: 0.18, green: 0.62, blue: 0.32)
                              : Color(red: 0.18, green: 0.62, blue: 0.32).opacity(0.70))
                        .frame(width: 3)
                    Text(fix)
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(
                            applied
                                ? Color.inkDeep
                                : Color(red: 0.04, green: 0.44, blue: 0.14)
                        )
                        .underline(!applied, color: Color(red: 0.18, green: 0.62, blue: 0.32).opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(5)
                        .padding(.leading, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 0)
    }
}

private struct DocHighlightedText: View {
    let full: String
    let highlighted: String

    var body: some View {
        if let range = full.range(of: highlighted) {
            let before = String(full[full.startIndex ..< range.lowerBound])
            let after  = String(full[range.upperBound ..< full.endIndex])
            highlightedView(before: before, mid: highlighted, after: after)
        } else {
            Text(full)
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(Color.inkDeep)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(5)
        }
    }

    private func highlightedView(before: String, mid: String, after: String) -> some View {
        // Build attributed string with yellow inline highlight
        var attr = AttributedString(before)
        var midAttr = AttributedString(mid)
        midAttr.backgroundColor = Color(red: 1.0, green: 0.93, blue: 0.18).opacity(0.60)
        var afterAttr = AttributedString(after)
        attr.font = .system(size: 17, design: .serif)
        midAttr.font = .system(size: 17, design: .serif)
        afterAttr.font = .system(size: 17, design: .serif)
        let combined = attr + midAttr + afterAttr
        return Text(combined)
            .foregroundStyle(Color.inkDeep)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(5)
    }
}

// MARK: - Event: Magic Patterns Meetup Singapore

private let mpAccent = Color(red: 0.45, green: 0.28, blue: 0.92)

private struct MagicPatternsEventView: View {
    @Binding var aiBarContext: AIBarContext?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EventCoverImage()
                EventHeaderSection()
                EventAIOverviewPanel()
                EventDetailsPanel()
                EventHostsPanel()
                EventAboutPanel()
            }
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 180)
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Magic Patterns Meetup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            aiBarContext = .magicPatternsEvent
        }
        .onDisappear {
            if aiBarContext == .magicPatternsEvent {
                aiBarContext = nil
            }
        }
    }
}

private struct EventCoverImage: View {
    private static let imageURL = URL(string: "https://images.lumacdn.com/cdn-cgi/image/format=auto,fit=cover,dpr=2,background=white,quality=75,width=400,height=400/event-covers/66/4dc8d8c7-a2ec-44b2-ba55-62762a2c0470.png")!

    var body: some View {
        AsyncImage(url: Self.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            default:
                Rectangle()
                    .fill(mpAccent.opacity(0.15))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(mpAccent.opacity(0.45))
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct EventHeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                EventChip(text: "AI", symbolName: "cpu.fill")
                EventChip(text: "Near you", symbolName: "location.fill")
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Magic Patterns Meetup")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)

                Text("Singapore · AI Engineer Conference")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(mpAccent)
            }
        }
    }
}

private struct EventAIOverviewPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(mpAccent)
                Text("Why this is for you")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            Text("You're focused on AI engineering and building your career in tech. Magic Patterns is a leading AI-powered design tool — this meetup puts you directly in front of its founders and engineers at Singapore's AI Engineer Conference, the exact intersection of AI and product craft you're targeting.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
        }
    }
}

private struct EventDetailsPanel: View {
    var body: some View {
        SectionPanel(title: "Event details") {
            BookingInfoRow(title: "Date",  detail: "September 15, 2025",            symbolName: "calendar")
            RowDivider()
            BookingInfoRow(title: "Time",  detail: "10:00 AM – 12:00 PM SGT",       symbolName: "clock.fill")
            RowDivider()
            BookingInfoRow(title: "Venue", detail: "Dough, 30 Victoria St #01-30",  symbolName: "mappin.and.ellipse")
            RowDivider()
            BookingInfoRow(title: "City",  detail: "Singapore 187996",              symbolName: "globe.asia.australia.fill")
        }
    }
}

private struct EventHostsPanel: View {
    private let hosts: [(String, String)] = [
        ("Alex Danilowicz", "Co-founder, Magic Patterns"),
        ("Sherry Jiang",    "Magic Patterns"),
        ("Alex Lee",        "Engineer, Magic Patterns"),
    ]

    var body: some View {
        SectionPanel(title: "Hosted by") {
            ForEach(Array(hosts.enumerated()), id: \.offset) { index, host in
                if index > 0 { RowDivider() }
                HostRow(name: host.0, role: host.1)
            }
        }
    }
}

private struct HostRow: View {
    let name: String
    let role: String

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(initials)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(mpAccent.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text(role)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.52))
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.vertical, 6)
    }
}

private struct EventAboutPanel: View {
    var body: some View {
        SectionPanel(title: "About") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Magic Patterns will be at the AI Engineer conference in Singapore! Come meet the conference speaker and our engineer, Alex Lee, for coffee after the conference.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                Text("Learn more about AI and design tooling, and come say hi. We'll have swag, stickers, and coffee!")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
        }
    }
}

private struct FutureHackEventView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                FutureHackHeaderSection()
                FutureHackOverviewPanel()
                FutureHackDetailsPanel()
                FutureHackReflectionPanel()
            }
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 180)
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("AWS Accelerator Competition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct FutureHackHeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                EventChip(text: "AI", symbolName: "cpu.fill")
                EventChip(text: "Competition", symbolName: "trophy.fill")
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("AWS Accelerator Competition")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)

                Text("Singapore · Student innovation sprint")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(mpAccent)
            }
        }
    }
}

private struct FutureHackOverviewPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(mpAccent)
                Text("Resume angle")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            Text("A dummy AI competition entry focused on turning a broad idea into a clear prototype pitch. Useful for showing curiosity, fast learning, product thinking, and confidence presenting AI use cases.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
        }
    }
}

private struct FutureHackDetailsPanel: View {
    var body: some View {
        SectionPanel(title: "Event details") {
            BookingInfoRow(title: "Date", detail: "March 12, 2026", symbolName: "calendar")
            RowDivider()
            BookingInfoRow(title: "Format", detail: "1-day prototype challenge", symbolName: "timer")
            RowDivider()
            BookingInfoRow(title: "Focus", detail: "AI tools for student productivity", symbolName: "sparkles")
            RowDivider()
            BookingInfoRow(title: "Role", detail: "Participant and presenter", symbolName: "person.fill.checkmark")
        }
    }
}

private struct FutureHackReflectionPanel: View {
    var body: some View {
        SectionPanel(title: "Resume note") {
            Text("Competed in a student AI challenge, shaped a prototype concept for improving study workflows, and presented the solution under time pressure to practice product storytelling.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(Color.inkDeep.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 16)
        }
    }
}

private struct EventChip: View {
    let text: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(mpAccent)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(mpAccent.opacity(0.10), in: Capsule())
        .overlay(Capsule().strokeBorder(mpAccent.opacity(0.22), lineWidth: 1))
    }
}

private struct BookingInfoRow: View {
    let title: String
    let detail: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(mpAccent)
                .frame(width: 44, height: 44)
                .background(mpAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.48))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(detail)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(.vertical, 8)
    }
}

// MARK: - Home hero card

@available(iOS 18, *)
private struct AnimatedMeshGradient: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate)
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5],
                [0.25 + 0.5 * sin(t * 0.6), 0.25 + 0.5 * cos(t * 0.4)],
                [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [
                Color(red: 0.18, green: 0.48, blue: 1.00),
                Color(red: 0.42, green: 0.18, blue: 0.94),
                Color(red: 0.18, green: 0.48, blue: 1.00),
                Color(red: 0.28, green: 0.58, blue: 1.00),
                Color(red: 0.62, green: 0.16, blue: 0.98),
                Color(red: 0.18, green: 0.36, blue: 0.92),
                Color(red: 0.14, green: 0.32, blue: 0.90),
                Color(red: 0.40, green: 0.16, blue: 0.90),
                Color(red: 0.22, green: 0.52, blue: 1.00),
            ])
        }
    }
}

private struct HomeStreakCard: View {
    // Days: Mon-Sun going back from today. true = studied that day.
    private let streakDays: [(letter: String, studied: Bool)] = [
        ("M", true), ("T", true), ("W", true), ("T", true), ("F", false), ("S", false), ("S", false)
    ]
    private let streakCount = 4

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text("Kyran")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 22))
                    Text("\(streakCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("day streak")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                        .padding(.bottom, 2)
                }
            }

            HStack(spacing: 0) {
                ForEach(Array(streakDays.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 5) {
                        Text(day.letter)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(day.studied ? .white : .white.opacity(0.35))
                        Circle()
                            .fill(day.studied ? .white.opacity(0.25) : .white.opacity(0.10))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if day.studied {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background {
            if #available(iOS 18, *) {
                AnimatedMeshGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                LinearGradient(
                    colors: [Color(red: 0.20, green: 0.40, blue: 0.95), Color(red: 0.38, green: 0.22, blue: 0.88)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

// MARK: - Study planning data

private struct StudyPlanItem: Identifiable {
    enum Kind { case lesson, breakPeriod, testReminder }
    let id = UUID()
    let time: String
    let subject: String
    let task: String
    let tint: Color
    let symbolName: String
    var kind: Kind = .lesson
}

private struct StudyTaskProgress: Identifiable {
    let id = UUID()
    let title: String
    let tint: Color
    let symbolName: String
}

private enum StudyDashboardData {
    static let todayPlan: [StudyPlanItem] = [
        StudyPlanItem(
            time: "Mon 25 May",
            subject: "Computing Test",
            task: "Network security & data structures",
            tint: .orange,
            symbolName: "exclamationmark.triangle.fill",
            kind: .testReminder
        ),
        StudyPlanItem(time: "8:50 AM",  subject: "English",   task: "Period 1", tint: .purple,              symbolName: "text.book.closed.fill"),
        StudyPlanItem(time: "9:50 AM",  subject: "Maths",     task: "Period 2", tint: .blue,                symbolName: "function"),
        StudyPlanItem(time: "10:50 AM", subject: "Break",     task: "20 min",   tint: .gray,                symbolName: "cup.and.saucer.fill",         kind: .breakPeriod),
        StudyPlanItem(time: "11:10 AM", subject: "Computing", task: "Period 3", tint: computingStudyWarmTint, symbolName: "cpu.fill"),
        StudyPlanItem(time: "12:10 PM", subject: "History",   task: "Period 4", tint: Color(red: 0.55, green: 0.35, blue: 0.15), symbolName: "book.pages.fill"),
        StudyPlanItem(time: "1:10 PM",  subject: "Lunch",     task: "50 min",   tint: .gray,                symbolName: "fork.knife",                  kind: .breakPeriod),
        StudyPlanItem(time: "2:00 PM",  subject: "Science",   task: "Period 5", tint: .green,               symbolName: "atom"),
    ]

    static let computingRecoveryTasks: [StudyTaskProgress] = [
        StudyTaskProgress(title: "Annotate missed notes", tint: computingStudyTint, symbolName: "doc.text.magnifyingglass"),
        StudyTaskProgress(title: "Rebuild worked examples", tint: computingStudyWarmTint, symbolName: "point.3.connected.trianglepath.dotted"),
        StudyTaskProgress(title: "Mark retrieval quiz", tint: computingStudyTint, symbolName: "checklist.checked"),
    ]

}

// MARK: - Study widgets

private struct TodayStudyPlanWidget: View {
    private let allItems   = StudyDashboardData.todayPlan
    private var timetable: [StudyPlanItem] { allItems.filter { $0.kind != .testReminder } }
    private var testReminder: StudyPlanItem? { allItems.first { $0.kind == .testReminder } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's plan")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)

            if let test = testReminder {
                ComputingTestBanner(item: test)
            }

            TimetableCard(items: timetable)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ComputingTestBanner: View {
    let item: StudyPlanItem

    var body: some View {
        HStack(spacing: 10) {
            TestReminderPill(
                title: "Computing exam in 4 days",
                symbolName: "cpu.fill",
                tint: item.tint
            )

            TestReminderPill(
                title: "1 subject needs attention",
                symbolName: "exclamationmark.circle.fill",
                tint: item.tint
            )
        }
    }
}

private struct TestReminderPill: View {
    let title: String
    let symbolName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.88)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 14)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct TimetableCard: View {
    let items: [StudyPlanItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TimetableRow(item: item, isLast: index == items.count - 1)
            }
        }
        .padding(.vertical, 6)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.09), lineWidth: 1)
        )
    }
}

private struct TimetableRow: View {
    let item: StudyPlanItem
    let isLast: Bool

    private let accentColor = Color.blue
    private var isBreak: Bool { item.kind == .breakPeriod }
    private var dotSize: CGFloat { isBreak ? 6 : 10 }
    private var dotColor: Color  { isBreak ? Color.gray.opacity(0.30) : accentColor }
    private var rowMinHeight: CGFloat { isBreak ? 36 : 64 }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(item.time)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(isBreak ? Color.secondary.opacity(0.35) : Color.secondary.opacity(0.65))
                .frame(width: 58, alignment: .trailing)
                .padding(.leading, 18)

            ZStack {
                if !isLast {
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
            }
            .frame(width: 30)

            rowContent
                .padding(.vertical, isBreak ? 4 : 8)
                .padding(.leading, 8)
                .padding(.trailing, 18)
        }
        .frame(maxWidth: .infinity, minHeight: rowMinHeight, alignment: .center)
    }

    @ViewBuilder
    private var rowContent: some View {
        switch item.kind {
        case .lesson:
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 3, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.subject)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkDeep)
                    Text(item.task)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.70))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .breakPeriod:
            HStack(spacing: 4) {
                Text(item.subject)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.40))
                Text("·")
                    .foregroundStyle(Color.secondary.opacity(0.25))
                Text(item.task)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.32))
                Spacer(minLength: 0)
            }

        case .testReminder:
            EmptyView()
        }
    }
}

private struct CertificationSuggestionsSection: View {
    let suggestions: [CertificationSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Certification suggestions")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)

            VStack(spacing: 10) {
                ForEach(suggestions) { suggestion in
                    CertificationSuggestionRow(suggestion: suggestion)
                }
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.09), lineWidth: 1)
            )
        }
    }
}

private struct CertificationSuggestionRow: View {
    let suggestion: CertificationSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: suggestion.symbolName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(suggestion.tint)
                .frame(width: 32, height: 32)
                .background(suggestion.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)

                Text(suggestion.provider)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(suggestion.tint)

                Text(suggestion.detail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(suggestion.tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TaskTrackingSection: View {
    let hasAddedComputingRecoveryTasks: Bool
    @Binding var completedStudyTaskIDs: Set<UUID>

    private var tasks: [StudyTaskProgress] {
        hasAddedComputingRecoveryTasks
        ? Array(StudyDashboardData.computingRecoveryTasks.prefix(3))
        : []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tasks")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)

            VStack(spacing: 10) {
                ForEach(tasks) { task in
                    TaskTrackingWidget(
                        task: task,
                        isComplete: completedStudyTaskIDs.contains(task.id),
                        onToggle: {
                            if completedStudyTaskIDs.contains(task.id) {
                                completedStudyTaskIDs.remove(task.id)
                            } else {
                                completedStudyTaskIDs.insert(task.id)
                            }
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TaskTrackingWidget: View {
    let task: StudyTaskProgress
    let isComplete: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            withAnimation(.snappy) {
                onToggle()
            }
        } label: {
            HStack(spacing: 12) {
                Text(task.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                    .strikethrough(isComplete, color: Color.inkDeep.opacity(0.42))

                Spacer(minLength: 10)
                checkbox
            }
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
        )
        .accessibilityLabel(task.title)
        .accessibilityValue(isComplete ? "Complete" : "Incomplete")
    }

    private var checkbox: some View {
        Image(systemName: isComplete ? "checkmark.square.fill" : "square")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(isComplete ? task.tint : Color.inkDeep.opacity(0.34))
            .contentTransition(.opacity)
    }
}

// MARK: - Shared layout shell

private struct AppTabScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let symbolName: String
    let tint: Color
    var showsHeader = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    if showsHeader {
                        header
                    }
                    content()
                }
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, showsHeader ? 24 : 8)
                .padding(.bottom, 180)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.55))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Reusable components

private struct HeroPanel: View {
    enum Size {
        case regular
        case compact
    }

    let title: String
    let subtitle: String
    let tint: Color
    let symbolName: String
    var size: Size = .regular

    var body: some View {
        HStack(alignment: .top, spacing: size.contentSpacing) {
            VStack(alignment: .leading, spacing: size.textSpacing) {
                Text(title)
                    .font(.system(size: size.titleFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text(subtitle)
                    .font(.system(size: size.subtitleFontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: size.spacerMinLength)

            Image(systemName: symbolName)
                .font(.system(size: size.iconFontSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size.iconSize, height: size.iconSize)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: size.iconCornerRadius, style: .continuous))
        }
        .padding(size.padding)
        .background(
            tint.opacity(0.10),
            in: RoundedRectangle(cornerRadius: size.panelCornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: size.panelCornerRadius, style: .continuous)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private extension HeroPanel.Size {
    var contentSpacing: CGFloat {
        switch self {
        case .regular: 22
        case .compact: 16
        }
    }

    var textSpacing: CGFloat {
        switch self {
        case .regular: 14
        case .compact: 9
        }
    }

    var titleFontSize: CGFloat {
        switch self {
        case .regular: 24
        case .compact: 20
        }
    }

    var subtitleFontSize: CGFloat {
        switch self {
        case .regular: 18
        case .compact: 15
        }
    }

    var spacerMinLength: CGFloat {
        switch self {
        case .regular: 18
        case .compact: 12
        }
    }

    var iconFontSize: CGFloat {
        switch self {
        case .regular: 34
        case .compact: 25
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .regular: 66
        case .compact: 50
        }
    }

    var iconCornerRadius: CGFloat {
        switch self {
        case .regular: 18
        case .compact: 14
        }
    }

    var padding: CGFloat {
        switch self {
        case .regular: 28
        case .compact: 18
        }
    }

    var panelCornerRadius: CGFloat {
        switch self {
        case .regular: 20
        case .compact: 16
        }
    }
}

private struct SectionPanel<Content: View>: View {
    let title: String
    var description: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)

                if let description {
                    Text(description)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkDeep.opacity(0.52))
                }
            }

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 62)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let caption: String
    let tint: Color
    let symbolName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text(caption)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.50))
            }

            Spacer(minLength: 16)

            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.vertical, 12)
    }
}

private struct TaskRow: View {
    let title: String
    let detail: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color.inkMid)
                .frame(width: 46, height: 46)
                .background(Color.inkMid.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Text(detail)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkDeep.opacity(0.50))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.inkDeep.opacity(0.25))
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.vertical, 12)
    }
}

// MARK: - Computing MCQ

private struct MCQQuestion {
    let question: String
    let options: [String]
    let correctIndex: Int
}

private let computingMCQs: [MCQQuestion] = [
    MCQQuestion(
        question: "What does the 'I' in the CIA Triad stand for?",
        options: ["Identity", "Integrity", "Intelligence", "Infrastructure"],
        correctIndex: 1
    ),
    MCQQuestion(
        question: "Which attack floods a server to block legitimate requests?",
        options: ["Phishing", "SQL Injection", "Denial-of-Service (DoS)", "Malware"],
        correctIndex: 2
    ),
    MCQQuestion(
        question: "Which CIA principle ensures data can be accessed when needed?",
        options: ["Confidentiality", "Integrity", "Authentication", "Availability"],
        correctIndex: 3
    ),
    MCQQuestion(
        question: "A confidentiality breach could lead to which of the following?",
        options: ["Server downtime", "Identity theft or fraud", "Data becoming unavailable", "Slower network speeds"],
        correctIndex: 1
    ),
]

private enum MCQOptionState { case normal, selected, correct, incorrect }

private struct SkeuRadio: View {
    let isSelected: Bool
    let tint: Color

    var body: some View {
        ZStack {
            Circle().fill(Color(white: 0.91))
            Circle().fill(tint).opacity(isSelected ? 1 : 0)
            Circle()
                .fill(LinearGradient(
                    colors: [.white.opacity(isSelected ? 0.28 : 0.55), .black.opacity(0.08)],
                    startPoint: .top, endPoint: .bottom
                ))
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 24, height: 24)
        .overlay(
            Circle().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.55), .black.opacity(0.20)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
        .shadow(color: .black.opacity(isSelected ? 0.14 : 0.06), radius: isSelected ? 3 : 1, x: 0, y: 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
    }
}

private struct MCQOptionRow: View {
    let text: String
    let tint: Color
    let state: MCQOptionState
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                SkeuRadio(isSelected: state != .normal, tint: radioTint)
                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                switch state {
                case .correct:   Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                case .incorrect: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                default: EmptyView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(rowBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(borderColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: state)
    }

    private var radioTint: Color {
        switch state {
        case .normal:    return Color(white: 0.6)
        case .selected:  return tint
        case .correct:   return .green
        case .incorrect: return .red
        }
    }
    private var rowBg: Color {
        switch state {
        case .normal:    return .clear
        case .selected:  return tint.opacity(0.07)
        case .correct:   return Color.green.opacity(0.08)
        case .incorrect: return Color.red.opacity(0.08)
        }
    }
    private var borderColor: Color {
        switch state {
        case .normal:    return Color.black.opacity(0.09)
        case .selected:  return tint.opacity(0.35)
        case .correct:   return Color.green.opacity(0.40)
        case .incorrect: return Color.red.opacity(0.40)
        }
    }
}

private struct MCQPanel: View {
    let tint: Color
    let questions: [MCQQuestion]
    let onDismiss: () -> Void

    @State private var currentQuestionIndex = 0
    @State private var selectedIndex: Int? = nil
    @State private var isSubmitted = false

    private var question: MCQQuestion {
        questions[currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                Text("You scrolled fast — review first?")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkDeep)
                Spacer()
                Text("\(currentQuestionIndex + 1)/\(questions.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.10), in: Capsule())
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.inkDeep.opacity(0.40))
                        .frame(width: 26, height: 26)
                        .background(Color.black.opacity(0.07), in: Circle())
                }
            }

            Text(question.question)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkDeep)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(question.options.indices, id: \.self) { i in
                    MCQOptionRow(
                        text: question.options[i],
                        tint: tint,
                        state: optionState(for: i),
                        onSelect: { if !isSubmitted { withAnimation(.snappy) { selectedIndex = i } } }
                    )
                }
            }

            if isSubmitted, let sel = selectedIndex {
                let correct = sel == question.correctIndex
                let feedback = correct
                    ? "Correct! Well done."
                    : "Not quite — the answer is \"\(question.options[question.correctIndex])\"."
                Text(feedback)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(correct ? Color.green : Color.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            SkeuButton(tint: tint, action: submitOrDismiss) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .disabled(selectedIndex == nil && !isSubmitted)
        }
        .padding(22)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(tint.opacity(0.20), lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: -6)
        .padding(.horizontal, 14)
        .padding(.bottom, 20)
    }

    private func optionState(for i: Int) -> MCQOptionState {
        guard isSubmitted else { return selectedIndex == i ? .selected : .normal }
        if i == question.correctIndex { return .correct }
        return selectedIndex == i ? .incorrect : .normal
    }

    private func submitOrDismiss() {
        if isSubmitted {
            guard !isLastQuestion else {
                onDismiss()
                return
            }

            withAnimation(.snappy) {
                currentQuestionIndex += 1
                selectedIndex = nil
                isSubmitted = false
            }
            return
        }

        withAnimation(.snappy) { isSubmitted = true }
    }

    private var buttonTitle: String {
        guard isSubmitted else { return "Submit" }
        return isLastQuestion ? "Done" : "Next question"
    }
}

#Preview {
    ContentView()
}
