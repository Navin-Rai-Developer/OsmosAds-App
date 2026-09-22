//
//  AdEventLog.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//

import Foundation
import Combine

struct AdEventLog: Identifiable, Equatable {
    let id = UUID()
    let date = Date()
    let message: String
    let isFailure: Bool
}

@MainActor
final class AdAnalyticsLogger: ObservableObject {
    @Published private(set) var events: [AdEventLog] = []

    func log(_ message: String, isFailure: Bool = false) {
        events.insert(AdEventLog(message: message, isFailure: isFailure), at: 0)
        print("[Osmos Ads] \(message)")
    }
}
