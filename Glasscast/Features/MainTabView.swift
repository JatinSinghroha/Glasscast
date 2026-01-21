//
//  MainTabView.swift
//  Glasscast
//

import SwiftUI

enum Tab: Int, CaseIterable {
    case home = 0
    case cities = 1
    case search = 2
    case favorites = 3
    case settings = 4

    var title: String {
        switch self {
        case .home: return "Home"
        case .cities: return "Cities"
        case .search: return "Search"
        case .favorites: return "Favorites"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .cities: return "building.2.fill"
        case .search: return "magnifyingglass"
        case .favorites: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case .home:
                    MainHomeView()
                case .cities:
                    MyCitiesView()
                case .search:
                    SearchView()
                case .favorites:
                    FavoritesView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }

    private var customTabBar: some View {
        ZStack {
            // Floating glass tab bar
            HStack(spacing: 0) {
                // Left tabs (Home, Cities)
                tabButton(for: .home)
                tabButton(for: .cities)

                // Center search button
                centerSearchButton
                    .padding(.horizontal, 4)

                // Right tabs (Favorites, Settings)
                tabButton(for: .favorites)
                tabButton(for: .settings)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background {
                // Liquid glass background
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Selection indicator
                    if selectedTab == tab {
                        Circle()
                            .fill(AppColors.teal.opacity(0.15))
                            .frame(width: 44, height: 44)
                    }

                    Image(systemName: tab.iconName)
                        .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                        .symbolEffect(.bounce, value: selectedTab == tab)
                }
                .frame(height: 44)

                Text(tab.title)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
            }
            .foregroundStyle(selectedTab == tab ? AppColors.teal : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var centerSearchButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = .search
            }
        } label: {
            ZStack {
                // Outer glow when selected
                if selectedTab == .search {
                    Circle()
                        .fill(AppColors.teal.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .blur(radius: 8)
                }

                // Glass button background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.teal,
                                AppColors.darkTeal
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay {
                        // Glass highlight
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .padding(2)
                    }
                    .shadow(color: AppColors.teal.opacity(0.5), radius: 12, x: 0, y: 6)

                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(selectedTab == .search ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedTab == .search)
    }
}

// Main Home View - shows weather for selected/default city
struct MainHomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var favoritesViewModel: FavoritesViewModel = {
        let vm = FavoritesViewModel()
        vm.viewMode = .allCities
        return vm
    }()
    /// Persist selected city ID across tab switches
    @AppStorage("selectedCityId") private var selectedCityIdString: String = ""
    @State private var isInitialLoad = true

    /// Access FavoritesManager directly so SwiftUI observes changes
    private var favoritesManager: FavoritesManager {
        FavoritesManager.shared
    }

    var cities: [FavoriteCity] {
        favoritesViewModel.favorites
    }

    var selectedCityId: UUID? {
        get { UUID(uuidString: selectedCityIdString) }
        set { selectedCityIdString = newValue?.uuidString ?? "" }
    }

    var selectedCity: FavoriteCity? {
        guard let selectedCityId = selectedCityId else { return nil }
        return cities.first { $0.id == selectedCityId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if let weather = viewModel.weather {
                    WeatherBackgroundGradient(condition: weather.condition)
                } else {
                    GradientBackground()
                }

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        if isInitialLoad && viewModel.weather == nil {
                            loadingSection
                        } else if let weather = viewModel.weather {
                            WeatherCardView(weather: weather)

                            if !viewModel.forecast.isEmpty {
                                ForecastListView(forecasts: viewModel.forecast)
                            }
                        } else if !isInitialLoad && cities.isEmpty {
                            emptyStateSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await refreshAll()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await loadInitialData()
        }
        .onChange(of: selectedCityIdString) { _, newValue in
            if let uuid = UUID(uuidString: newValue),
               let city = cities.first(where: { $0.id == uuid }) {
                Task {
                    await viewModel.loadWeather(for: city)
                }
            }
        }
    }

    private func loadInitialData() async {
        // Load cities from cache first (fast)
        await favoritesViewModel.loadCities(mode: .allCities)
        await favoritesManager.loadCities()

        // Restore persisted selection or select default city
        let sortedCities = sortedByFavorite(cities)
        let cityToLoad: FavoriteCity?

        if let persistedId = selectedCityId,
           let persistedCity = cities.first(where: { $0.id == persistedId }) {
            // Use persisted selection
            cityToLoad = persistedCity
        } else if let defaultCity = sortedCities.first {
            // Select first city (favorites first)
            selectedCityIdString = defaultCity.id.uuidString
            cityToLoad = defaultCity
        } else {
            cityToLoad = nil
        }

        // Load weather (from cache first, then refresh)
        if let city = cityToLoad {
            await viewModel.loadWeather(for: city)
        }

        isInitialLoad = false
    }

    /// Sort cities with favorites first
    private func sortedByFavorite(_ cities: [FavoriteCity]) -> [FavoriteCity] {
        cities.sorted { city1, city2 in
            let fav1 = favoritesManager.isFavorite(city1.id)
            let fav2 = favoritesManager.isFavorite(city2.id)
            if fav1 != fav2 {
                return fav1
            }
            return city1.cityName < city2.cityName
        }
    }

    private func refreshAll() async {
        await favoritesViewModel.loadCities(mode: .allCities, forceRefresh: true)
        if let city = selectedCity {
            await viewModel.loadWeather(for: city, forceRefresh: true)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            // City name centered with favorite button on trailing edge
            ZStack {
                // Centered city name/picker
                if cities.count > 1 {
                    Menu {
                        ForEach(sortedByFavorite(cities)) { city in
                            Button {
                                selectedCityIdString = city.id.uuidString
                            } label: {
                                HStack {
                                    Text(city.cityName)
                                    if let country = city.country {
                                        Text("(\(country))")
                                            .foregroundStyle(.secondary)
                                    }
                                    if city.id == selectedCityId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedCity?.cityName ?? "Select City")
                                .font(.title2.bold())
                                .foregroundStyle(AppColors.textPrimary)

                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppColors.teal)
                        }
                    }
                } else {
                    Text(selectedCity?.cityName ?? "Welcome")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)
                }

                // Favorite button on trailing edge
                HStack {
                    Spacer()
                    if let city = selectedCity {
                        let isFavorite = favoritesManager.favoriteIds.contains(city.id)
                        let isToggling = favoritesManager.togglingIds.contains(city.id)
                        FavoriteButton(
                            isFavorite: isFavorite,
                            action: {
                                Task {
                                    await favoritesManager.toggleFavorite(city)
                                }
                            },
                            size: .large,
                            isLoading: isToggling
                        )
                    }
                }
            }

            Text(viewModel.dateString)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 8)
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.teal)
                .scaleEffect(1.5)

            Text("Loading weather...")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .glassCard(cornerRadius: 20)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary)

            Text("No City Selected")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Add a city from Search to see\nweather information here")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .glassCard(cornerRadius: 20)
    }
}

#Preview {
    MainTabView()
}
