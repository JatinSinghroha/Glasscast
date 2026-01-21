//
//  HomeView.swift
//  Glasscast
//

import SwiftUI

struct HomeView: View {
    let city: FavoriteCity
    @State private var viewModel = HomeViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Access FavoritesManager directly so SwiftUI observes changes
    private var favoritesManager: FavoritesManager {
        FavoritesManager.shared
    }

    var body: some View {
        ZStack {
            if let weather = viewModel.weather {
                WeatherBackgroundGradient(condition: weather.condition)
            } else {
                AppBackgroundGradient()
            }

            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    if viewModel.isLoading && viewModel.weather == nil {
                        WeatherCardView(weather: .placeholder)
                            .redacted(reason: .placeholder)
                    } else if let weather = viewModel.weather {
                        WeatherCardView(weather: weather)

                        if !viewModel.forecast.isEmpty {
                            ForecastListView(forecasts: viewModel.forecast)
                        } else if viewModel.isLoading {
                            ForecastListView(forecasts: Forecast.placeholders)
                                .redacted(reason: .placeholder)
                        }
                    } else {
                        emptyStateSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(AppColors.teal)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Access favoriteIds directly so SwiftUI observes changes
                let isFavorite = favoritesManager.favoriteIds.contains(city.id)
                let isToggling = favoritesManager.togglingIds.contains(city.id)
                FavoriteToolbarButton(
                    isFavorite: isFavorite,
                    action: {
                        Task {
                            await favoritesManager.toggleFavorite(city)
                        }
                    },
                    isLoading: isToggling
                )
            }
        }
        .task {
            await favoritesManager.loadCities()
            await viewModel.loadWeather(for: city)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.currentCity?.cityName ?? "")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)

            Text(viewModel.dateString)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 8)
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.teal.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.icloud")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.teal)
            }

            Text("Unable to load weather")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Pull down to refresh")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(city: FavoriteCity(
            userId: UUID(),
            cityName: "San Francisco",
            country: "US",
            lat: 37.7749,
            lon: -122.4194
        ))
    }
}
