import Foundation
import WeatherKit
import CoreLocation

/// Lightweight service that fetches and caches the current weather conditions
/// using Apple's WeatherKit and CoreLocation.
///
/// Usage: Observe `temperature` and `conditionSymbol` — both are `nil` until
/// a successful fetch. Call `refreshIfNeeded()` from the UI; the service
/// handles location permission, caching (30-min TTL), and error recovery.
@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    
    static let shared = WeatherService()
    
    // MARK: - Published State
    
    /// Formatted temperature string, e.g. "72°F"
    @Published var temperature: String?
    
    /// SF Symbol name for the current condition, e.g. "sun.max.fill"
    @Published var conditionSymbol: String?
    
    /// A short task suggestion based on current weather (e.g. "Rainy day — great for indoor tasks")
    var weatherSuggestion: String? {
        guard let symbol = conditionSymbol else { return nil }
        switch symbol {
        case let s where s.contains("rain") || s.contains("drizzle"):
            return "Rainy day — great for indoor tasks"
        case let s where s.contains("snow") || s.contains("sleet") || s.contains("hail"):
            return "Snowy day — perfect for indoor projects"
        case let s where s.contains("thunderstorm"):
            return "Stormy weather — stay in and knock out some tasks"
        case let s where s.contains("cloud.bolt"):
            return "Thunderstorm — perfect for focus tasks indoors"
        case let s where s.contains("wind"):
            return "Windy out — great day for household tasks"
        case let s where s.contains("sun.max") || s.contains("sun.min"):
            return "Beautiful day — great for an outdoor workout"
        case let s where s.contains("cloud.sun"):
            return "Partly cloudy — nice for a walk or outdoor task"
        case let s where s.contains("cloud"):
            return "Overcast — solid day for any kind of task"
        case let s where s.contains("moon") || s.contains("star"):
            return "Clear night — wind down with an evening routine"
        case let s where s.contains("fog") || s.contains("haze"):
            return "Foggy out — cozy day for creative tasks"
        default:
            return nil
        }
    }
    
    // MARK: - Private
    
    private let weather = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    private var lastFetch: Date?
    private var isFetching = false
    
    /// Minimum interval between fetches (30 minutes).
    private let cacheTTL: TimeInterval = 30 * 60
    
    // MARK: - Init
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Public
    
    /// Request a weather refresh if the cache is stale or empty.
    func refreshIfNeeded() {
        guard !isFetching else { return }
        
        if let lastFetch, Date().timeIntervalSince(lastFetch) < cacheTTL {
            return // Cache is still fresh
        }
        
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break // Denied or restricted — do nothing
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            await fetchWeather(for: location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location failed — silently ignore; the UI just won't show weather
    }
    
    // MARK: - Fetch
    
    private func fetchWeather(for location: CLLocation) async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        do {
            let current = try await weather.weather(for: location, including: .current)
            
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .providedUnit
            formatter.numberFormatter.maximumFractionDigits = 0
            
            let tempInUserUnit = current.temperature.converted(to: .fahrenheit)
            temperature = formatter.string(from: tempInUserUnit)
            conditionSymbol = current.symbolName
            lastFetch = Date()
        } catch {
            // WeatherKit unavailable — leave published values as-is (nil or stale)
        }
    }
}
