//
//  WeatherAppView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import SwiftUI
import Observation

// MARK: - Async UI State (same idea as your Pokédex)
//enum LoadState<Value>: Equatable where Value: Equatable {
//    case idle
//    case loading
//    case success(Value)
//    case failure(String)
//}

// MARK: - App Entry View
struct WeatherAppView: View {
    @State private var vm = WeatherSearchVM()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchBar

                content
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: WeatherSummary.self) { summary in
                WeatherDetailView(summary: summary, service: vm.service)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search city (e.g., London)", text: $vm.query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { Task { await vm.search() } }

            if !vm.query.isEmpty {
                Button {
                    vm.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button("Search") {
                Task { await vm.search() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle:
            VStack(spacing: 10) {
                ContentUnavailableView(
                    "Search a city",
                    systemImage: "cloud.sun",
                    description: Text("Type a city name and tap Search.")
                )

                if !vm.recent.isEmpty {
                    recentList
                }
            }
            .padding(.top, 18)

        case .loading:
            VStack(spacing: 12) {
                ProgressView("Fetching weather…")
                if !vm.recent.isEmpty {
                    recentList
                }
            }
            .padding(.top, 18)

        case .failure(let message):
            VStack(spacing: 10) {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                if !vm.recent.isEmpty {
                    recentList
                }
            }
            .padding(.top, 18)

        case .success(let summary):
            VStack(spacing: 12) {
                NavigationLink(value: summary) {
                    WeatherMainCard(summary: summary)
                }
                .buttonStyle(.plain)

                if !vm.recent.isEmpty {
                    recentList
                }

                Spacer(minLength: 8)
            }
            .padding(.top, 6)
        }
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                Button("Clear") { vm.clearRecent() }
                    .font(.subheadline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.recent, id: \.self) { city in
                        Button {
                            vm.query = city
                            Task { await vm.search() }
                        } label: {
                            Text(city)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(.thinMaterial)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Main Card
struct WeatherMainCard: View {
    let summary: WeatherSummary

    var body: some View {
        HStack(spacing: 14) {
            WeatherRemoteImageView(urlString: summary.iconURL, size: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text(summary.cityDisplay)
                    .font(.title3.bold())

                Text(summary.description.capitalized)
                    .foregroundStyle(.secondary)

                Text("Updated: \(summary.updatedText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(summary.tempText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Feels \(summary.feelsLikeText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(.systemTeal).opacity(0.25),
                        Color(.systemBlue).opacity(0.18),
                        Color(.systemIndigo).opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Detail Screen
struct WeatherDetailView: View {
    let summary: WeatherSummary
    @State private var vm: WeatherDetailVM

    init(summary: WeatherSummary, service: WeatherServicing = WeatherAPI()) {
        self.summary = summary
        _vm = State(wrappedValue: WeatherDetailVM(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                WeatherMainCard(summary: summary)

                detailBody
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .navigationTitle(summary.cityDisplay)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(summary: summary) }
    }

    @ViewBuilder
    private var detailBody: some View {
        switch vm.state {
        case .idle, .loading:
            HStack { Spacer(); ProgressView("Loading details…"); Spacer() }
                .padding(.top, 10)

        case .failure(let message):
            Text(message)
                .foregroundStyle(.red)
                .padding(.top, 10)

        case .success(let d):
            VStack(spacing: 12) {
                InfoGrid(items: [
                    .init(title: "Min / Max", value: "\(d.tempMinText) / \(d.tempMaxText)", systemImage: "thermometer"),
                    .init(title: "Humidity", value: d.humidityText, systemImage: "drop.fill"),
                    .init(title: "Pressure", value: d.pressureText, systemImage: "gauge"),
                    .init(title: "Wind", value: d.windText, systemImage: "wind"),
                    .init(title: "Clouds", value: d.cloudsText, systemImage: "cloud.fill"),
                    .init(title: "Visibility", value: d.visibilityText, systemImage: "eye.fill"),
                    .init(title: "Rain (1h)", value: d.rain1hText, systemImage: "cloud.rain.fill"),
                    .init(title: "Sunrise / Sunset", value: "\(d.sunriseText) / \(d.sunsetText)", systemImage: "sunrise.fill")
                ])

                Spacer(minLength: 8)
            }
        }
    }
}

// MARK: - Reusable grid
struct InfoGrid: View {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let value: String
        let systemImage: String
    }

    let items: [Item]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.value)
                            .font(.subheadline.weight(.semibold))
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
}

// MARK: - Models (Geocoding + Current Weather)

/// OpenWeather direct geocoding: returns an array of matches.  [oai_citation:2‡OpenWeatherMap](https://openweathermap.org/api/geocoding-api?utm_source=chatgpt.com)
struct OWGeocodeItem: Decodable, Hashable, Equatable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String?
    let state: String?
}

/// Your current weather JSON shape
struct OWCurrentWeatherResponse: Decodable, Hashable, Equatable {
    struct Coord: Decodable, Hashable, Equatable { let lon: Double; let lat: Double }
    struct Weather: Decodable, Hashable, Equatable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    struct Main: Decodable, Hashable, Equatable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let pressure: Int
        let humidity: Int
    }
    struct Wind: Decodable, Hashable, Equatable {
        let speed: Double
        let deg: Int?
        let gust: Double?
    }
    struct Clouds: Decodable, Hashable, Equatable { let all: Int }
    struct Rain: Decodable, Hashable, Equatable {
        let oneHour: Double?
        enum CodingKeys: String, CodingKey { case oneHour = "1h" }
    }
    struct Sys: Decodable, Hashable, Equatable {
        let country: String?
        let sunrise: Int?
        let sunset: Int?
    }

    let coord: Coord
    let weather: [Weather]
    let main: Main
    let visibility: Int?
    let wind: Wind?
    let rain: Rain?
    let clouds: Clouds?
    let dt: Int?
    let sys: Sys?
    let timezone: Int? // seconds shift from UTC
    let name: String
}

// MARK: - View models’ display model
struct WeatherSummary: Hashable, Identifiable, Equatable {
    // Make it navigable
    let id: String

    let cityDisplay: String
    let lat: Double
    let lon: Double

    let tempC: Double
    let feelsLikeC: Double
    let tempMinC: Double
    let tempMaxC: Double

    let pressure: Int
    let humidity: Int

    let description: String
    let iconCode: String

    let visibilityMeters: Int
    let windSpeedMS: Double
    let cloudsPercent: Int
    let rain1hMM: Double

    let updatedUnix: Int
    let timezoneShiftSeconds: Int
    let sunriseUnix: Int
    let sunsetUnix: Int

    var iconURL: String {
        // OpenWeather icons: https://openweathermap.org/img/wn/{icon}@2x.png  [oai_citation:3‡OpenWeatherMap](https://openweathermap.org/weather-conditions?utm_source=chatgpt.com)
        "https://openweathermap.org/img/wn/\(iconCode)@2x.png"
    }

    var tempText: String { "\(Int(round(tempC)))°C" }
    var feelsLikeText: String { "\(Int(round(feelsLikeC)))°C" }

    var updatedText: String {
        Self.formatTime(unix: updatedUnix, tzShift: timezoneShiftSeconds)
    }

    static func formatTime(unix: Int, tzShift: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unix + tzShift))
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Service Protocol (testability like your Pokédex)
protocol WeatherServicing: Sendable {
    func geocodeCity(_ city: String) async throws -> [OWGeocodeItem]
    func currentWeather(lat: Double, lon: Double) async throws -> OWCurrentWeatherResponse
}

// MARK: - API (Real Service)
struct WeatherAPI: WeatherServicing {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = Secrets.openWeatherAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func geocodeCity(_ city: String) async throws -> [OWGeocodeItem] {
        // https://api.openweathermap.org/geo/1.0/direct?q={city}&limit=5&appid={key}  [oai_citation:4‡OpenWeatherMap](https://openweathermap.org/api/geocoding-api?utm_source=chatgpt.com)
        var comps = URLComponents(string: "https://api.openweathermap.org/geo/1.0/direct")!
        comps.queryItems = [
            .init(name: "q", value: city),
            .init(name: "limit", value: "5"),
            .init(name: "appid", value: apiKey)
        ]
        return try await request(comps.url!)
    }

    func currentWeather(lat: Double, lon: Double) async throws -> OWCurrentWeatherResponse {
        // lat/lon/appid mandatory; units optional  [oai_citation:5‡OpenWeatherMap](https://openweathermap.org/current?utm_source=chatgpt.com)
        var comps = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        comps.queryItems = [
            .init(name: "lat", value: "\(lat)"),
            .init(name: "lon", value: "\(lon)"),
            .init(name: "appid", value: apiKey),
            .init(name: "units", value: "metric") // Celsius
        ]
        return try await request(comps.url!)
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - ViewModels
@Observable
final class WeatherSearchVM {
    let service: WeatherServicing

    // UI
    var query: String = ""
    private(set) var state: LoadState<WeatherSummary> = .idle

    // Simple recents
    private(set) var recent: [String] = []

    // Cache last results by normalized city
    private static var cache: [String: WeatherSummary] = [:]

    init(service: WeatherServicing = WeatherAPI()) {
        self.service = service
    }

    func clearRecent() {
        recent.removeAll()
    }

    @MainActor
    func search() async {
        let city = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else { return }

        let key = city.lowercased()

        // Instant result from cache
        if let cached = Self.cache[key] {
            state = .success(cached)
            addRecent(city)
            return
        }

        state = .loading
        do {
            let places = try await service.geocodeCity(city)
            guard let best = places.first else {
                state = .failure("No matching city found.")
                return
            }

            let weather = try await service.currentWeather(lat: best.lat, lon: best.lon)
            let summary = WeatherSummaryMapper.map(geo: best, weather: weather)

            Self.cache[key] = summary
            addRecent(city)
            state = .success(summary)
        } catch {
            state = .failure("Failed to fetch weather. Check API key / network.")
        }
    }

    private func addRecent(_ city: String) {
        // Keep unique, most-recent-first
        recent.removeAll { $0.caseInsensitiveCompare(city) == .orderedSame }
        recent.insert(city, at: 0)
        if recent.count > 10 { recent = Array(recent.prefix(10)) }
    }
}

@Observable
final class WeatherDetailVM {
    private let service: WeatherServicing
    private(set) var state: LoadState<WeatherSummary> = .idle

    init(service: WeatherServicing = WeatherAPI()) {
        self.service = service
    }

    @MainActor
    func load(summary: WeatherSummary) async {
        // For current-weather endpoint, "detail" is basically same payload.
        // Here we refresh once (optional). You can also just set `.success(summary)` instantly.
        if case .success = state { return }

        state = .loading
        do {
            let res = try await service.currentWeather(lat: summary.lat, lon: summary.lon)
            let refreshed = WeatherSummaryMapper.mapExistingCity(summary: summary, weather: res)
            state = .success(refreshed)
        } catch {
            state = .success(summary) // fallback to passed summary
        }
    }
}

// MARK: - Mapper
enum WeatherSummaryMapper {
    static func map(geo: OWGeocodeItem, weather: OWCurrentWeatherResponse) -> WeatherSummary {
        let w = weather.weather.first
        let tz = weather.timezone ?? 0

        let visibility = weather.visibility ?? 0
        let windSpeed = weather.wind?.speed ?? 0
        let clouds = weather.clouds?.all ?? 0
        let rain1h = weather.rain?.oneHour ?? 0

        let sunrise = weather.sys?.sunrise ?? 0
        let sunset = weather.sys?.sunset ?? 0
        let updated = weather.dt ?? 0

        let cityDisplay = [
            geo.name,
            geo.state,
            geo.country
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")

        return WeatherSummary(
            id: "\(geo.lat),\(geo.lon)",
            cityDisplay: cityDisplay.isEmpty ? weather.name : cityDisplay,
            lat: geo.lat,
            lon: geo.lon,
            tempC: weather.main.temp,
            feelsLikeC: weather.main.feels_like,
            tempMinC: weather.main.temp_min,
            tempMaxC: weather.main.temp_max,
            pressure: weather.main.pressure,
            humidity: weather.main.humidity,
            description: w?.description ?? w?.main ?? "—",
            iconCode: w?.icon ?? "01d",
            visibilityMeters: visibility,
            windSpeedMS: windSpeed,
            cloudsPercent: clouds,
            rain1hMM: rain1h,
            updatedUnix: updated,
            timezoneShiftSeconds: tz,
            sunriseUnix: sunrise,
            sunsetUnix: sunset
        )
    }

    static func mapExistingCity(summary: WeatherSummary, weather: OWCurrentWeatherResponse) -> WeatherSummary {
        let w = weather.weather.first
        let tz = weather.timezone ?? summary.timezoneShiftSeconds

        return WeatherSummary(
            id: summary.id,
            cityDisplay: summary.cityDisplay,
            lat: summary.lat,
            lon: summary.lon,
            tempC: weather.main.temp,
            feelsLikeC: weather.main.feels_like,
            tempMinC: weather.main.temp_min,
            tempMaxC: weather.main.temp_max,
            pressure: weather.main.pressure,
            humidity: weather.main.humidity,
            description: w?.description ?? w?.main ?? summary.description,
            iconCode: w?.icon ?? summary.iconCode,
            visibilityMeters: weather.visibility ?? summary.visibilityMeters,
            windSpeedMS: weather.wind?.speed ?? summary.windSpeedMS,
            cloudsPercent: weather.clouds?.all ?? summary.cloudsPercent,
            rain1hMM: weather.rain?.oneHour ?? summary.rain1hMM,
            updatedUnix: weather.dt ?? summary.updatedUnix,
            timezoneShiftSeconds: tz,
            sunriseUnix: weather.sys?.sunrise ?? summary.sunriseUnix,
            sunsetUnix: weather.sys?.sunset ?? summary.sunsetUnix
        )
    }
}

// MARK: - Convenience computed texts for Detail grid
extension WeatherSummary {
    var tempMinText: String { "\(Int(round(tempMinC)))°C" }
    var tempMaxText: String { "\(Int(round(tempMaxC)))°C" }
    var humidityText: String { "\(humidity)%" }
    var pressureText: String { "\(pressure) hPa" }

    var windText: String {
        String(format: "%.1f m/s", windSpeedMS)
    }

    var cloudsText: String { "\(cloudsPercent)%" }

    var visibilityText: String {
        let km = Double(visibilityMeters) / 1000.0
        return String(format: "%.1f km", km)
    }

    var rain1hText: String {
        guard rain1hMM != 0 else { return "—" }
        return String(format: "%.2f mm", rain1hMM)
    }

    var sunriseText: String { Self.formatTime(unix: sunriseUnix, tzShift: timezoneShiftSeconds) }
    var sunsetText: String { Self.formatTime(unix: sunsetUnix, tzShift: timezoneShiftSeconds) }
}

// MARK: - Tiny Remote image (like your RemoteImageView idea)
struct WeatherRemoteImageView: View {
    let urlString: String
    let size: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var placeholder: some View {
        Image(systemName: "cloud.sun.fill")
            .resizable()
            .scaledToFit()
            .padding(12)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview
#Preview {
    WeatherAppView()
}
