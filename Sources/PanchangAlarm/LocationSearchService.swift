import Foundation
import MapKit
import Combine

/// Wraps MKLocalSearchCompleter (built into iOS, no API key required) to let
/// the user type a city name and get autocomplete suggestions, then resolve
/// a chosen suggestion to an actual latitude/longitude.
@MainActor
final class LocationSearchService: NSObject, ObservableObject {
    @Published var queryFragment: String = "" {
        didSet { completer.queryFragment = queryFragment }
    }
    @Published private(set) var results: [MKLocalSearchCompletion] = []
    @Published private(set) var isResolving: Bool = false

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    /// Resolves a tapped autocomplete suggestion into coordinates.
    func resolve(_ completion: MKLocalSearchCompletion) async -> (name: String, latitude: Double, longitude: Double)? {
        isResolving = true
        defer { isResolving = false }

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return nil }
            let coordinate = item.placemark.coordinate
            let name = [completion.title, completion.subtitle]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            return (name, coordinate.latitude, coordinate.longitude)
        } catch {
            return nil
        }
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let newResults = completer.results
        Task { @MainActor in
            self.results = newResults
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
        }
    }
}
