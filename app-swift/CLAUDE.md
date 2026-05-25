# Claude Instructions

## Build and Verification

- Build, install, and launch the app with `./scripts/check-and-run.sh simulator`.
- When finishing code changes, run `./scripts/check-and-run.sh simulator` and confirm the simulator build/install/launch succeeds.
- Treat a successful simulator run as the required final verification unless the user asks for a different target.

## SwiftUI Architecture

- Prefer `@Observable` for shared mutable state on iOS 17+ instead of `ObservableObject`.
- For rapid prototyping, start with plain SwiftUI views using `@State`, `@Environment`, and local state.
- Only extract a view model when a view becomes complex enough to need it.
- Keep each screen self-contained under `Features/` so screens can be iterated on independently.
- Keep `matchedGeometryEffect` namespaces at the feature level, not globally.

## Animation Patterns

- Centralize animation presets in one extension, such as `Animation+Custom.swift`, so motion feels cohesive.
- Centralize custom transitions in one extension, such as `View+Transitions.swift`.
- Use `withAnimation(.snappy)` for state changes that should animate.
- Use `PhaseAnimator` on iOS 17+ for multi-step sequences without manual state tracking.
- Use `KeyframeAnimator` when an animation needs precise timeline control.
- Use `.contentTransition(.numericText())` for animated number changes.
- Use custom `NavigationStack` transitions with `.navigationTransition` on iOS 18+ when screen transitions need extra polish.
