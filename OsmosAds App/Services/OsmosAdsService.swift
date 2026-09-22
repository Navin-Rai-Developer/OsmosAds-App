//
//  OsmosAdsService.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//


import Foundation
import osmos

@MainActor
final class OsmosAdsService {
    enum ServiceError: LocalizedError {
        case unavailable(String)
        case noAds

        var errorDescription: String? {
            switch self {
            case .unavailable(let message): return message
            case .noAds: return "The request completed, but no valid banner ads were returned."
            }
        }
    }

    private let sdk: OSMOS

    init() throws {
        sdk = try OSMOS.Builder()
            .clientId(OsmosConfiguration.clientId)
            .productAdsHost(OsmosConfiguration.productAdsHost)
            .displayAdsHost(OsmosConfiguration.displayAdsHost)
            .debug(true)
            .enableBatchProcessing(true)
            .maxRetryCount(3)
            .build()
    }

    func fetchBannerAds() async throws -> [DisplayBannerAd] {
        guard let adFetcher = sdk.adFetcher() else {
            throw ServiceError.unavailable("The Osmos ad fetcher is unavailable. Verify SDK initialization.")
        }

        let response = await adFetcher.fetchDisplayAdsWithAu(
            cliUbid: OsmosConfiguration.cliUbid,
            pageType: OsmosConfiguration.pageType,
            productCount: 5,
            adUnits: [OsmosConfiguration.adUnit],
            targetingParams: nil,
            onError: { error in
                print("Osmos fetch error: \(error.localizedDescription)")
            }
        )

        guard let response else {
            throw ServiceError.unavailable("The banner request did not return a response.")
        }

        print("Osmos raw banner response keys: \(response.keys.sorted())")

        let sdkAds = DisplayAdParser.parseBannerAds(from: response)
        if !sdkAds.isEmpty {
            return sdkAds
        }

        // SDK 3.0.1 can wrap the successful payload in an opaque `response` value.
        // Use the same AU endpoint as a fallback so the assignment can still manually render its image ads.
        print("Osmos SDK payload was not manually parseable; using AU API fallback for manual rendering.")
        let fallbackResponse = try await fetchRawAUResponse()
        let fallbackAds = DisplayAdParser.parseBannerAds(from: fallbackResponse)

        guard !fallbackAds.isEmpty else { throw ServiceError.noAds }
        return fallbackAds
    }

    func registerImpression(for ad: DisplayBannerAd, position: Int) async -> Bool {
        guard let registerEvent = sdk.registerEvent(),
              let uclid = ad.uclid,
              !uclid.isEmpty else {
            return false
        }

        let trackingParams = TrackingParams()
            .uclid(uclid)
            .position(position)

        let response = await registerEvent.registerAdImpressionEvent(
            cliUbid: OsmosConfiguration.cliUbid,
            uclid: uclid,
            position: position,
            trackingParams: trackingParams,
            onError: { error in
                print("Osmos impression error: \(error.localizedDescription)")
            }
        )

        return response != nil
    }

    func registerClick(for ad: DisplayBannerAd) async -> Bool {
        guard let registerEvent = sdk.registerEvent(),
              let clickTrackingURL = ad.clickTrackingURL,
              !clickTrackingURL.isEmpty else {
            return false
        }

        let response = await registerEvent.registerAClickEvent(
            cliUbid: OsmosConfiguration.cliUbid,
            url: clickTrackingURL,
            onError: { error in
                print("Osmos click error: \(error.localizedDescription)")
            }
        )

        return response != nil
    }

    private func fetchRawAUResponse() async throws -> [String: Any] {
        var components = URLComponents(string: "https://\(OsmosConfiguration.displayAdsHost)/v2/bsda")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: OsmosConfiguration.clientId),
            URLQueryItem(name: "cli_ubid", value: OsmosConfiguration.cliUbid),
            URLQueryItem(name: "pt", value: OsmosConfiguration.pageType),
            URLQueryItem(name: "pcnt_au", value: "5"),
            URLQueryItem(name: "au[]", value: OsmosConfiguration.adUnit)
        ]

        guard let url = components.url else {
            throw ServiceError.unavailable("Could not create the fallback ad request URL.")
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.unavailable("The fallback AU request failed.")
        }

        return json
    }
}
