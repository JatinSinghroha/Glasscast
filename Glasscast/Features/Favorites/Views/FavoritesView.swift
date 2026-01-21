//
//  FavoritesView.swift
//  Glasscast
//

import SwiftUI

struct FavoritesView: View {
    @State private var viewModel: FavoritesViewModel = {
        let vm = FavoritesViewModel()
        vm.viewMode = .favoritesOnly
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
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
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
            viewModel.viewMode = .favoritesOnly
            await viewModel.loadCities(mode: .favoritesOnly)
            await favoritesManager.loadCities()
        }
        .refreshable {
            await viewModel.loadCities(mode: .favoritesOnly, forceRefresh: true)
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

    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.favorites) { favorite in
                    // Access togglingIds directly for SwiftUI observation
                    let isToggling = favoritesManager.togglingIds.contains(favorite.id)
                    FavoriteCityCard(
                        favorite: favorite,
                        onTap: { selectedCity = favorite },
                        isToggling: isToggling,
                        onUnfavorite: {
                            Task {
                                await favoritesManager.toggleFavorite(favorite)
                                await viewModel.toggleFavorite(favorite)
                            }
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await favoritesManager.toggleFavorite(favorite)
                                await viewModel.toggleFavorite(favorite)
                            }
                        } label: {
                            Label("Remove from Favorites", systemImage: "heart.slash")
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

            Text("Loading favorites...")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.teal.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "heart")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.teal)
            }

            Text("No Favorites Yet")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)

            Text("Go to My Cities and tap the heart\nto add cities to your favorites")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

#Preview {
    FavoritesView()
}
