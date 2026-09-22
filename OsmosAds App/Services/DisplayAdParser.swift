//
//  DisplayAdParser.swift
//  OsmosAds App
//
//  Created by Navin Kumar on 22/09/26.
//

import Foundation

enum DisplayAdParser {
    static func parseBannerAds(from response: [String: Any]) -> [DisplayBannerAd] {
        // The SDK can return either nested dictionaries or JSON strings, depending on its version.
        let sdkPayload = dictionary(response["response"]) ?? response
        let adsContainer = dictionary(sdkPayload["ads"])
            ?? dictionary(sdkPayload["data"])
            ?? sdkPayload
        let rawAds = arrayOfDictionaries(adsContainer[OsmosConfiguration.adUnit])

        return rawAds.enumerated().compactMap { index, rawAd in
            let elements = dictionary(rawAd["elements"]) ?? [:]
            guard let imageURL = url(firstString(elements["value"], rawAd["image_url"], rawAd["imageUrl"])),
                  let destinationURL = url(firstString(elements["destination_url"], rawAd["destination_url"], rawAd["destinationUrl"])) else {
                return nil
            }

            let width = number(elements["width"]) ?? number(rawAd["width"]) ?? 16
            let height = number(elements["height"]) ?? number(rawAd["height"]) ?? 9
            let safeRatio = height > 0 ? max(0.25, min(width / height, 6)) : 16 / 9

            return DisplayBannerAd(
                id: firstString(rawAd["id"], rawAd["uclid"], elements["value"]) ?? "banner-\(index)",
                imageURL: imageURL,
                destinationURL: destinationURL,
                impressionTrackingURL: firstString(rawAd["impression_tracking_url"], rawAd["impressionTrackingUrl"]),
                clickTrackingURL: firstString(rawAd["click_tracking_url"], rawAd["clickTrackingUrl"]),
                uclid: firstString(rawAd["uclid"], rawAd["ucid"], response["uclid"]),
                aspectRatio: safeRatio
            )
        }
    }

    private static func dictionary(_ value: Any?) -> [String: Any]? {
        decodedJSON(value) as? [String: Any]
    }

    private static func arrayOfDictionaries(_ value: Any?) -> [[String: Any]] {
        let decodedValue = decodedJSON(value)
        if let dictionaries = decodedValue as? [[String: Any]] { return dictionaries }
        if let values = decodedValue as? [Any] {
            return values.compactMap { dictionary($0) }
        }
        if let dictionary = decodedValue as? [String: Any] { return [dictionary] }
        return []
    }

    private static func decodedJSON(_ value: Any?) -> Any? {
        if let data = value as? Data {
            return (try? JSONSerialization.jsonObject(with: data)) ?? value
        }

        guard let string = value as? String,
              let data = string.data(using: .utf8) else {
            return value
        }

        return (try? JSONSerialization.jsonObject(with: data)) ?? value
    }

    private static func firstString(_ values: Any?...) -> String? {
        values.compactMap { value in
            if let string = value as? String, !string.isEmpty { return string }
            if let number = value as? NSNumber { return number.stringValue }
            return nil
        }.first
    }

    private static func number(_ value: Any?) -> CGFloat? {
        if let number = value as? NSNumber { return CGFloat(truncating: number) }
        if let string = value as? String, let number = Double(string) { return CGFloat(number) }
        return nil
    }

    private static func url(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme != nil else { return nil }
        return url
    }
}
