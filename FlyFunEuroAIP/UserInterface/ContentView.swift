//
//  ContentView.swift
//  flyguneuroaip
//
//  Created by Brice Rosenzweig on 26/10/2025.
//

import SwiftUI
import MapKit

struct Airport: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let iata: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: Airport, rhs: Airport) -> Bool {
        lhs.iata == rhs.iata
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(iata)
    }
}

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @State private var isFilterExpanded: Bool = false

    // Simple demo dataset
    @State private var airports: [Airport] = [
        Airport(name: "San Francisco International", iata: "SFO", coordinate: CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)),
        Airport(name: "Los Angeles International", iata: "LAX", coordinate: CLLocationCoordinate2D(latitude: 33.9416, longitude: -118.4085)),
        Airport(name: "John F. Kennedy International", iata: "JFK", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)),
        Airport(name: "Heathrow", iata: "LHR", coordinate: CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)),
        Airport(name: "Charles de Gaulle", iata: "CDG", coordinate: CLLocationCoordinate2D(latitude: 49.0097, longitude: 2.5479)),
    ]

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.0, longitude: -30.0),
            span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 120)
        )
    )

    @Environment(\.horizontalSizeClass) private var hSize

    var filteredAirports: [Airport] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return airports }
        return airports.filter { $0.name.localizedCaseInsensitiveContains(text) || $0.iata.localizedCaseInsensitiveContains(text) }
    }

    var body: some View {
        GeometryReader { proxy in
            let isRegular = (hSize == .regular) || proxy.size.width >= 700
            ZStack(alignment: .topLeading) {
                mapLayer
                    .ignoresSafeArea()

                // Overlay stack adapts between floating panels and side docking
                if isRegular {
                    HStack(spacing: 12) {
                        // Left: search + results
                        sidePanel
                            .frame(width: max(320, proxy.size.width * 0.28))
                            .transition(.move(edge: .leading).combined(with: .opacity))

                        Spacer(minLength: 0)

                        // Right: filter button + expandable panel
                        VStack(alignment: .trailing, spacing: 12) {
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation(.snappy) { isFilterExpanded.toggle() }
                                } label: {
                                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle.fill")
                                        .labelStyle(.iconOnly)
                                        .imageScale(.large)
                                        .foregroundStyle(.tint)
                                        .padding(10)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .accessibilityLabel("Filter")
                            }

                            if isFilterExpanded {
                                FilterPanel(isExpanded: $isFilterExpanded)
                                    .frame(width: 360)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(radius: 8)
                            }
                        }
                        .frame(maxWidth: 380)
                    }
                    .padding(16)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Spacer()
                            // Search + filter button row (compact)
                            SearchFieldCompact(searchText: $searchText, isExpanded: $isSearchExpanded)
                            Button {
                                withAnimation(.snappy) { isFilterExpanded.toggle() }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .imageScale(.large)
                                    .foregroundStyle(.tint)
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .accessibilityLabel("Filter")
                        }

                        if isSearchExpanded || !searchText.isEmpty {
                            SearchResultsList(results: filteredAirports) { airport in
                                focus(on: airport)
                                isSearchExpanded = false
                            }
                            .frame(maxHeight: 300)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(radius: 6)
                        }

                        Spacer()

                        // Single bottom-anchored filter panel when expanded
                        if isFilterExpanded {
                            FilterPanel(isExpanded: $isFilterExpanded)
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(radius: 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(16)
                    .transition(.opacity)
                }
            }
        }
        .animation(.snappy, value: isSearchExpanded)
        .animation(.snappy, value: isFilterExpanded)
    }

    // MARK: - Map
    private var mapLayer: some View {
        Map(position: $position) {
            ForEach(filteredAirports) { airport in
                Annotation(airport.iata, coordinate: airport.coordinate) {
                    ZStack {
                        Circle().fill(.blue.opacity(0.9)).frame(width: 24, height: 24)
                        Text(airport.iata)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Regular width side panel (iPad/Mac)
    private var sidePanel: some View {
        VStack(spacing: 12) {
            SearchBar(searchText: $searchText, isExpanded: $isSearchExpanded)
            if isSearchExpanded || !searchText.isEmpty {
                SearchResultsList(results: filteredAirports) { airport in
                    focus(on: airport)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .frame(maxHeight: 360)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8)
    }

    // MARK: - Helpers
    private func focus(on airport: Airport) {
        withAnimation(.snappy) {
            position = .region(MKCoordinateRegion(center: airport.coordinate, span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)))
        }
    }
}

// MARK: - Components
private struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search airports (name or IATA)", text: $searchText)
                .textFieldStyle(.plain)
                .onTapGesture { withAnimation(.snappy) { isExpanded = true } }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SearchFieldCompact: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .onTapGesture { withAnimation(.snappy) { isExpanded = true } }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.thickMaterial, in: Capsule())
    }
}

private struct SearchResultsList: View {
    var results: [Airport]
    var onSelect: (Airport) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(results) { airport in
                    Button {
                        onSelect(airport)
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(airport.iata)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 48, alignment: .leading)
                            Text(airport.name)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }
}

private struct FilterPanel: View {
    @Binding var isExpanded: Bool
    @State private var showInternationalOnly: Bool = false
    @State private var minRunwayLength: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.snappy) { isExpanded = false }
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.plain)
            }

            Toggle("International only", isOn: $showInternationalOnly)

            VStack(alignment: .leading) {
                Text("Minimum runway length")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Slider(value: $minRunwayLength, in: 0...4000, step: 100)
                    Text("\(Int(minRunwayLength)) m")
                        .monospacedDigit()
                        .frame(width: 80, alignment: .trailing)
                }
            }

            HStack {
                Button("Reset") {
                    showInternationalOnly = false
                    minRunwayLength = 0
                }
                Spacer()
                Button("Apply") {
                    withAnimation(.snappy) { isExpanded = false }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
    }
}

#Preview {
    ContentView()
}
