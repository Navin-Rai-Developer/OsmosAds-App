//
//  OsmosAdsViewModel.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OsmosAdsViewModel: ObservableObject {
    @Published private(set) var ads: [DisplayBannerAd] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var events: [AdEventLog] = []

    private let service: OsmosAdsService?
    private let logger = AdAnalyticsLogger()
    private var impressedAdIDs = Set<String>()

    init() {
        do {
            service = try OsmosAdsService()
            logger.log("SDK initialized with demo hosts.")
        } catch {
            service = nil
            logger.log("SDK initialization failed: \(error.localizedDescription)", isFailure: true)
            errorMessage = "Ad not available. SDK initialization failed."
        }
        events = logger.events
    }

    func loadAds() async {
        guard !isLoading else { return }
        guard let service else {
            errorMessage = "Ad not available. The SDK is not ready."
            logger.log("Ad failed: SDK is not ready.", isFailure: true)
            refreshEvents()
            return
        }

        isLoading = true
        errorMessage = nil
        logger.log("Loading banner ads for AU: \(OsmosConfiguration.adUnit).")
        refreshEvents()

        // Keeps the loading state visible long enough to demonstrate in the submission recording.
        try? await Task.sleep(for: .milliseconds(1200))

        do {
            ads = try await service.fetchBannerAds()
            logger.log("Ad loaded: received \(ads.count) banner ad(s).")
        } catch {
            ads = []
            errorMessage = "Ad not available. \(error.localizedDescription)"
            logger.log("Ad failed: \(error.localizedDescription)", isFailure: true)
        }

        isLoading = false
        refreshEvents()
    }

    func retry() async {
        logger.log("Retry requested.")
        refreshEvents()
        await loadAds()
    }

    func simulateNetworkFailure() {
        guard !isLoading else { return }

        ads = []
        errorMessage = "Ad not available. Simulated network failure for the demo."
        logger.log("Ad failed: simulated network failure.", isFailure: true)
        refreshEvents()
    }

    func adBecameAtLeastHalfVisible(_ ad: DisplayBannerAd, position: Int) {
        guard impressedAdIDs.insert(ad.id).inserted else { return }
        logger.log("Ad is at least 50% visible. Impression requested for position \(position).")
        refreshEvents()

        Task {
            guard let service else { return }
            let didFire = await service.registerImpression(for: ad, position: position)
            logger.log(didFire ? "Impression fired for ad \(ad.id)." : "Impression could not be fired because the SDK response lacks a usable uclid.", isFailure: !didFire)
            refreshEvents()
        }
    }

    func adTapped(_ ad: DisplayBannerAd) {
        logger.log("Ad clicked. Opening destination URL.")
        refreshEvents()

        Task {
            guard let service else { return }
            let didFire = await service.registerClick(for: ad)
            logger.log(didFire ? "Click fired for ad \(ad.id)." : "Click could not be fired because the SDK response lacks a click tracking URL.", isFailure: !didFire)
            refreshEvents()
        }
    }

    func recordLifecycleChange(_ phase: ScenePhase) {
        logger.log("App lifecycle changed to: \(phase.label). Existing ads and fired impressions are preserved.")
        refreshEvents()
    }

    private func refreshEvents() {
        events = logger.events
    }
}

private extension ScenePhase {
    var label: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}
