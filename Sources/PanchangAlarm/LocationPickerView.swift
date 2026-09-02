import SwiftUI
import MapKit

struct LocationPickerView: View {
    @StateObject private var search = LocationSearchService()
    var onSelect: (String, Double, Double) -> Void

    var body: some View {
        List {
            ForEach(search.results, id: \.self) { result in
                Button {
                    Task {
                        if let resolved = await search.resolve(result) {
                            onSelect(resolved.name, resolved.latitude, resolved.longitude)
                        }
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(result.title)
                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .overlay {
            if search.isResolving {
                ProgressView()
            }
        }
        .searchable(text: $search.queryFragment, prompt: "Search for a city")
        .navigationTitle("Choose Location")
    }
}

#Preview {
    NavigationStack {
        LocationPickerView { _, _, _ in }
    }
}
