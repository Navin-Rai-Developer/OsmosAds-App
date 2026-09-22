
//
//  HalfVisibilityTracker.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//



import SwiftUI

/// Reusable scroll-visibility helper. It calls `onVisible` once when at least 50% is visible.
private struct HalfVisibilityTracker: ViewModifier {
    let onVisible: () -> Void
    @State private var hasFired = false

    func body(content: Content) -> some View {
        content
            .onScrollVisibilityChange(threshold: 0.5) { isVisible in
                guard isVisible, !hasFired else { return }
                hasFired = true
                onVisible()
            }
    }
}

extension View {
    func trackWhenAtLeastHalfVisible(onVisible: @escaping () -> Void) -> some View {
        modifier(HalfVisibilityTracker(onVisible: onVisible))
    }
}
