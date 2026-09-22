//
//  DisplayBannerAd.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//


import Foundation

struct DisplayBannerAd: Identifiable, Equatable {
    let id: String
    let imageURL: URL
    let destinationURL: URL
    let impressionTrackingURL: String?
    let clickTrackingURL: String?
    let uclid: String?
    let aspectRatio: CGFloat
}
