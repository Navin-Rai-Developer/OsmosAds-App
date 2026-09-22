//
//  BannerAdCard.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//


import SwiftUI

struct BannerAdCard: View {
    let ad: DisplayBannerAd
    let onAtLeastHalfVisible: () -> Void
    let onTap: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(ad.destinationURL)
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: ad.imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            ContentUnavailableView("Ad image unavailable", systemImage: "photo.badge.exclamationmark")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    Text("ADVERTISEMENT")
                        .font(.caption2.bold())
                        .padding(6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(8)
                }
                .aspectRatio(ad.aspectRatio, contentMode: .fit)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.8), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
        .accessibilityLabel("Banner advertisement. Opens its landing page.")
        .trackWhenAtLeastHalfVisible(onVisible: onAtLeastHalfVisible)
    }
}

#Preview {
    BannerAdCard(
        ad: DisplayBannerAd(
            id: "preview-ad",
            imageURL: URL(string: "https://picsum.photos/800/450")!,
            destinationURL: URL(string: "https://example.com")!,
            impressionTrackingURL: nil,
            clickTrackingURL: nil,
            uclid: nil,
            aspectRatio: 16 / 9
        ),
        onAtLeastHalfVisible: {},
        onTap: {}
    )
    .padding()
}
