//
//  ContentView.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = OsmosAdsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                Color.osmosBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        Button {
                            Task { await viewModel.loadAds() }
                        } label: {
                            Label(viewModel.isLoading ? "Loading Ad…" : "Load Ad", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.osmosPrimary)
                        .controlSize(.large)
                        .disabled(viewModel.isLoading)

                        Button("Demo: Simulate Error") {
                            viewModel.simulateNetworkFailure()
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .disabled(viewModel.isLoading)

                        content

                        EventLogView(events: viewModel.events)
                    }
                    .padding()
                }
            }
            .navigationTitle("Osmos Banner Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.osmosBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: scenePhase) { _, newPhase in
                viewModel.recordLifecycleChange(newPhase)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Manual banner rendering")
                .font(.title2.bold())
            Text("Loads multiple AU-based display ads, tracks an impression once at 50% visibility, and records banner clicks.")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Fetching banner ads…")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("Ad not available", systemImage: "rectangle.slash")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.ads.isEmpty {
            ContentUnavailableView("Ready to load ads", systemImage: "rectangle.on.rectangle", description: Text("Tap Load Ad to request banner_ads from the Osmos SDK."))
        } else {
            LazyVStack(spacing: 24) {
                ForEach(Array(viewModel.ads.enumerated()), id: \.element.id) { index, ad in
                    BannerAdCard(ad: ad) {
                        viewModel.adBecameAtLeastHalfVisible(ad, position: index)
                    } onTap: {
                        viewModel.adTapped(ad)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
