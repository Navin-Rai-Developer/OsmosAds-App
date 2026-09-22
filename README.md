# Osmos Ads Demo

A native iOS app built with SwiftUI for the Osmos Ads assignment. It fetches display banner ads, renders them manually, and uses the Osmos SDK to register impressions and clicks.

The demo includes a scrollable list of banners, a Load Ad button, loading and error states, retry, and an on-screen event log.

## Setup

You will need Xcode with an iOS SDK that supports the project's deployment target, an iOS 26.2 or later simulator or device, and an internet connection. The current deployment target is **iOS 26.2**.

1. Clone or download this repository.
2. Open `OsmosAds App.xcodeproj` in Xcode.
3. Let Swift Package Manager resolve the dependencies. The project already includes the Osmos SDK, with version `3.0.1` recorded in `Package.resolved`.
4. Select the `OsmosAds App` scheme and an available simulator. For a physical device, select your development team under Signing & Capabilities and adjust the bundle identifier if needed.
5. Run the app, then tap **Load Ad**.

The assignment's demo configuration is in `Configuration/OsmosConfiguration.swift`:

```swift
clientId = "10088010"
productAdsHost = "demo.o-s.io"
displayAdsHost = "demo-ba.o-s.io"
cliUbid = "Any"
pageType = "demo_page"
adUnit = "banner_ads"
```

## Folder structure and architecture

```text
OsmosAds App/
├── OsmosAds App.xcodeproj/
├── README.md
└── OsmosAds App/
    ├── OsmosAds_AppApp.swift
    ├── ContentView.swift
    ├── Assets.xcassets/
    ├── Configuration/
    │   └── OsmosConfiguration.swift
    ├── Model/
    │   └── DisplayBannerAd.swift
    ├── Services/
    │   ├── OsmosAdsService.swift
    │   ├── DisplayAdParser.swift
    │   └── AdAnalyticsLogger.swift
    ├── ViewModel/
    │   └── OsmosAdsViewModel.swift
    └── View/
        ├── BannerAdCard.swift
        ├── VisibilityTracking.swift
        ├── EventLogView.swift
        └── Color+Osmos.swift
```

The app follows a small MVVM structure. `ContentView` displays the screen and forwards user actions to `OsmosAdsViewModel`. The view model manages loaded ads, loading and error states, event logs, and impression deduplication.

`OsmosAdsService` owns the SDK instance and handles fetching and tracking. `DisplayAdParser` converts the response into `DisplayBannerAd` values, so the views do not need to work with raw API dictionaries. The banner card, visibility helper, and event log are separate views that can be reused.

## How ad fetching works

Tapping **Load Ad** calls `loadAds()` on the view model. A loading flag prevents another request while one is already running, and the button is disabled during that time. The demo adds a 1.2-second delay before fetching to make the loading state visible during recording.

The service calls `fetchDisplayAdsWithAu` with `cliUbid: "Any"`, `pageType: "demo_page"`, `adUnits: ["banner_ads"]`, and `productCount: 5`.

The parser reads the banner entries and extracts the image URL, destination URL, dimensions, tracking URLs, and `uclid`. Entries without a parseable image or destination URL are skipped. Each valid banner is rendered with SwiftUI's `AsyncImage` inside a scrollable `LazyVStack`.

There is also a direct API fallback for responses the parser cannot use. If the SDK returns a non-nil response but parsing produces no valid banners, the service makes an AU request to `https://demo-ba.o-s.io/v2/bsda` with the same demo parameters. This includes empty or invalid SDK payloads, not just wrapped responses. A nil SDK response goes straight to the error state.

If neither response produces valid ads, the screen shows **Ad not available** with a **Retry** button. The number of banners returned depends on the demo inventory; requesting five does not guarantee five results.

## Impression tracking: 50% visibility

`VisibilityTracking.swift` provides a reusable `trackWhenAtLeastHalfVisible` modifier. It uses SwiftUI's `onScrollVisibilityChange(threshold: 0.5)` to detect when at least half of a banner card is visible.

Two guards prevent repeated attempts:

- The modifier keeps a local `hasFired` flag.
- The view model keeps a set of ad IDs in `impressedAdIDs`.

When the threshold is reached, the view model records the ad ID and asks the service to call `registerAdImpressionEvent` with the ad's `uclid` and its zero-based position in the list. The parsed `impression_tracking_url` is retained in the model; this implementation sends impressions through the SDK's `uclid`-based method instead of requesting that URL directly.

Deduplication lasts for the lifetime of the view model, including subsequent loads of the same ad ID. An ID is recorded before the tracking request completes, so a failed impression is not automatically retried. Visibility is measured on the card and is not gated on successful image loading or a minimum time on screen.

## Click tracking

Tapping a banner opens `elements.destination_url` through SwiftUI's `openURL`. The view model then asks the service to call `registerAClickEvent` with the ad's `click_tracking_url`.

Each tap can send a click event. A missing click tracking URL prevents the tracking call, but the destination can still open. The event log records the attempt and result; it does not confirm that the destination page finished loading.

## Error handling and logging

The app handles SDK initialization failure, missing SDK components, empty or invalid ad responses, and fetch failures. Fetch errors show **Ad not available**, with a retry action. Image download failures have their own message inside the banner card.

`AdAnalyticsLogger` prints events to the Xcode console and supplies the in-app Event Log. It records loading, failures, visibility, impression and click results, retries, and scene phase changes. Tracking is reported as successful when the SDK returns a non-nil response; the app does not independently verify server-side delivery.

`ContentView` owns the view model through `@StateObject`, preserving its state during normal redraws and scene transitions while the view remains alive. Flexible layouts let banners adapt to the available width after rotation.

## Assumptions

- The assignment's demo hosts and client ID are available and return compatible banner data.
- Ads provide usable image and destination URLs. SDK impression tracking additionally needs a `uclid`, and click tracking needs a click tracking URL.
- The same ad ID represents the same ad for impression deduplication during the current view-model lifetime.
- Banner dimensions describe the intended aspect ratio. Missing dimensions default to 16:9; the parser also bounds extreme ratios.
- This is an online demo. Loaded ads and logs are kept in memory, with no persistence across app launches.

## Challenges and implementation decisions

**Parsing the response:** The parser accepts dictionaries, JSON strings, and JSON data to handle different payload shapes. The direct AU fallback provides another fetch path when no usable banners can be extracted from the SDK response.

**Avoiding duplicate impressions:** Scrolling and view recreation can trigger repeated visibility updates. Keeping a guard in both the view and view model limits each ad ID to one impression attempt.

**Keeping banner layout flexible:** Banner sizes come from the response. The card uses the parsed aspect ratio and available screen width rather than a fixed device-specific size.

**Showing error handling in a demo:** The **Demo: Simulate Error** button clears the ads and displays a simulated failure. It makes the fallback and retry flow easy to demonstrate without changing network conditions. It does not simulate an actual SDK network request failure.

## Demo Video

[Watch the demo video](./OsmosAds-Demo.mov)

The recording demonstrates:
- Ad loading
- Banner rendering
- 50% visibility impression tracking
- Click tracking
- Error and retry handling

## How to run the demo

1. Launch the app and show the initial screen.
2. Tap **Load Ad** to show the loading indicator and fetched banners.
3. Scroll through the banners. Check the Event Log or Xcode console for the 50% visibility message and impression result.
4. Scroll away from a banner and back to show that the same ad does not trigger another impression attempt.
5. Tap a banner to open its destination. Return to the app and show the click result in the Event Log.
6. Tap **Demo: Simulate Error** to show **Ad not available**, then tap **Retry** to request ads again.
7. Rotate the simulator or device to show the layout adapting.

For submission, include a short recording covering loading, rendering, impression tracking, click handling, and the error/retry flow. The assignment also requests an app file in the GitHub repository, but does not specify its format.
