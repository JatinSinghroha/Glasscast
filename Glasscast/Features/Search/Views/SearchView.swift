//
//  SearchView.swift
//  Glasscast
//

import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundGradient()

                VStack(spacing: 0) {
                    searchHeader

                    if viewModel.isSearching {
                        loadingSection
                    } else if viewModel.searchResults.isEmpty && viewModel.hasSearchText {
                        emptyResultsSection
                    } else if !viewModel.searchResults.isEmpty {
                        searchResultsList
                    } else {
                        placeholderSection
                    }

                    Spacer()
                }
                .padding(.top, 8)

                if viewModel.showAddedToast {
                    VStack {
                        Spacer()
                        toastView
                            .padding(.bottom, 120)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: viewModel.showAddedToast)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .task {
            await viewModel.loadAddedCities()
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.teal)

                TextField("", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppColors.textPrimary)
                    .autocorrectionDisabled()
                    .focused($searchFieldFocused)
                    .overlay(alignment: .leading) {
                        if viewModel.searchText.isEmpty {
                            Text("Search cities...")
                                .foregroundStyle(AppColors.textSecondary)
                                .allowsHitTesting(false)
                        }
                    }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(searchFieldFocused ? AppColors.teal.opacity(0.5) : Color.clear, lineWidth: 1)
            }

            if searchFieldFocused {
                Button("Cancel") {
                    searchFieldFocused = false
                    viewModel.clearSearch()
                }
                .foregroundStyle(AppColors.teal)
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { city in
                    CityRowView(
                        city: city,
                        isAdded: viewModel.isCityAdded(city),
                        onAddTapped: {
                            Task {
                                await viewModel.addToMyCities(city)
                            }
                        }
                    )

                    if city.id != viewModel.searchResults.last?.id {
                        Divider()
                            .background(AppColors.divider)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.teal)

            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    private var emptyResultsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary)

            Text("No cities found")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .padding(.top, 32)
    }

    private var placeholderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.teal.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppColors.teal)
            }

            Text("Find Your City")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)

            Text("Search for any city to see its weather\nand add it to your favorites")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .padding(.top, 32)
    }

    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.teal)

            Text("\(viewModel.addedCityName ?? "City") added to My Cities")
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    SearchView()
}
