//
//  EventLogView.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//


import SwiftUI

struct EventLogView: View {
    let events: [AdEventLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Event Log", systemImage: "list.bullet.rectangle")
                .font(.headline)

            if events.isEmpty {
                Text("No events yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: event.isFailure ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(event.isFailure ? .orange : .green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.message)
                                .font(.subheadline)
                            Text(event.date, format: .dateTime.hour().minute().second())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    EventLogView(events: [
        AdEventLog(message: "Ad loaded: received 3 banner ad(s).", isFailure: false),
        AdEventLog(message: "Impression fired for ad banner-1.", isFailure: false)
    ])
    .padding()
}
