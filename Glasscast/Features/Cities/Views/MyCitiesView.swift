//
//  MyCitiesView.swift
//  Glasscast
//

import SwiftUI

struct MyCitiesView: View {
    @State private var viewModel: FavoritesViewModel = {
        let vm = FavoritesViewModel()
        vm.viewMode = .allCities
        return vm
    }()
    @State private var selectedCity: FavoriteCity?

    private var favoritesManager: FavoritesManager {
        FavoritesManager.shared
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundGradient()

                if viewModel.isLoading && viewModel.favorites.isEmpty {
                    loadingSection
                } else if viewModel.hasNoFavorites {
                    emptyStateSection
                } else {
                    citiesList
                }
            }
            .navigationTitle("My Cities")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isSyncing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppColors.teal)
                            .scaleEffect(0.8)
                    }
                }
            }
            .navigationDestination(item: $selectedCity) { city in
                HomeView(city: city)
            }
        }
        .task {
            viewModel.viewMode = .allCities
            await viewModel.loadCities(mode: .allCities)
            await favoritesManager.loadCities()
        }
        .refreshable {
            await viewModel.loadCities(mode: .allCities, forceRefresh: true)
            await favoritesManager.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }

    /// Cities sorted with favorites first - access favoriteIds directly for SwiftUI observation
    private var sortedCities: [FavoriteCity] {
        let favIds = favoritesManager.favoriteIds
        return viewModel.favorites.sorted { city1, city2 in
            let fav1 = favIds.contains(city1.id)
            let fav2 = favIds.contains(city2.id)
            if fav1 != fav2 {
                return fav1
            }
            return city1.cityName < city2.cityName
        }
    }

    private var citiesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sortedCities) { city in
                    // Access favoriteIds and togglingIds directly for SwiftUI observation
                    let isFav = favoritesManager.favoriteIds.contains(city.id)
                    let isToggling = favoritesManager.togglingIds.contains(city.id)
                    CityWeatherCard(
                        favorite: city,
                        isFavorite: isFav,
                        isToggling: isToggling,
                        onTap: { selectedCity = city },
                        onFavoriteToggle: {
                            Task {
                                await favoritesManager.toggleFavorite(city)
                                await viewModel.toggleFavorite(city)
                            }
                        }
                    )
                    .contextMenu {
                        Button {
                            Task {
                                await favoritesManager.toggleFavorite(city)
                                await viewModel.toggleFavorite(city)
                            }
                        } label: {
                            Label(
                                isFav ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: isFav ? "heart.slash" : "heart"
                            )
                        }

                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteCity(city)
                                favoritesManager.removeCity(city.id)
                            }
                        } label: {
                            Label("Delete City", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.teal)
                .scaleEffect(1.5)

            Text("Loading your cities...")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColors.textSecondary)

            Text("No Cities Added")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)

            Text("Search for cities and add them\nto see weather updates here")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

// City card with weather info and favorite toggle
struct CityWeatherCard: View {
    let favorite: FavoriteCity
    let isFavorite: Bool
    var isToggling: Bool = false
    let onTap: () -> Void
    var onFavoriteToggle: (() -> Void)? = nil
    @State private var weather: Weather?
    @State private var isLoading = false
    @State private var hasInitialized = false

    private let weatherService = WeatherService.shared

    private var tempFormatter: TemperatureFormatter {
        TemperatureFormatter.shared
    }

    /// Effective weather - use state if available, fall back to favorite's cached weather
    private var displayWeather: Weather? {
        weather ?? favorite.weather
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Weather icon
                ZStack {
                    Circle()
                        .fill(AppColors.teal.opacity(0.15))
                        .frame(width: 50, height: 50)

                    if let weather = displayWeather {
                        Image(systemName: weather.condition.iconName)
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.teal)
                    } else {
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                // City info
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.cityName)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    if let country = favorite.country {
                        Text(country)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    if let weather = displayWeather {
                        Text(weather.condition.rawValue)
                            .font(.caption)
                            .foregroundStyle(AppColors.teal)
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                // Temperature
                VStack(alignment: .trailing, spacing: 2) {
                    let weatherForDisplay = displayWeather ?? .placeholder
                    Text(tempFormatter.format(weatherForDisplay.temperature))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: 6) {
                        Label(tempFormatter.format(weatherForDisplay.tempMax), systemImage: "arrow.up")
                        Label(tempFormatter.format(weatherForDisplay.tempMin), systemImage: "arrow.down")
                    }
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
                }
                .redacted(reason: displayWeather == nil ? .placeholder : [])

                // Favorite button with animation
                if let onFavoriteToggle = onFavoriteToggle {
                    FavoriteButton(
                        isFavorite: isFavorite,
                        action: onFavoriteToggle,
                        size: .medium,
                        isLoading: isToggling
                    )
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
        .task {
            await loadWeather()
        }
    }

    private func loadWeather() async {
        // Show loading only if we don't have any data (cached or from parent)
        if displayWeather == nil {
            isLoading = true
        }

        // Always fetch fresh data from network
        do {
            var weatherResult = try await weatherService.fetchWeather(lat: favorite.lat, lon: favorite.lon)

            // Get today's actual high/low from forecast data
            if let highLow = try? await weatherService.getTodayHighLow(lat: favorite.lat, lon: favorite.lon, forceRefresh: true) {
                weatherResult = Weather(
                    id: weatherResult.id,
                    cityName: weatherResult.cityName,
                    country: weatherResult.country,
                    temperature: weatherResult.temperature,
                    feelsLike: weatherResult.feelsLike,
                    tempMin: highLow.tempMin,
                    tempMax: highLow.tempMax,
                    humidity: weatherResult.humidity,
                    windSpeed: weatherResult.windSpeed,
                    condition: weatherResult.condition,
                    description: weatherResult.description,
                    iconCode: weatherResult.iconCode,
                    rainChance: weatherResult.rainChance,
                    timestamp: weatherResult.timestamp
                )
            }

            weather = weatherResult
        } catch {
            // Silently fail - keep showing cached data if available
        }
        isLoading = false
    }
}

#Preview {
    MyCitiesView()
}
