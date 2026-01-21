//
//  AppConfig.swift
//  Glasscast
//

import Foundation

enum AppConfig {
    static var supabaseURL: String {
        let rawValue = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL")
        #if DEBUG
        print("DEBUG AppConfig - SUPABASE_URL raw: \(String(describing: rawValue))")
        #endif
        guard let urlString = rawValue as? String,
              !urlString.isEmpty,
              urlString != "$(SUPABASE_URL)",
              !urlString.contains("your_supabase") else {
            #if DEBUG
            print("Warning: SUPABASE_URL not configured. Please update Config.xcconfig")
            #endif
            return ""
        }
        return urlString
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              key != "$(SUPABASE_ANON_KEY)",
              !key.contains("your_supabase") else {
            #if DEBUG
            print("Warning: SUPABASE_ANON_KEY not configured. Please update Config.xcconfig")
            #endif
            return ""
        }
        return key
    }

    static var openWeatherMapAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHERMAP_API_KEY") as? String,
              !key.isEmpty,
              key != "$(OPENWEATHERMAP_API_KEY)" else {
            #if DEBUG
            print("Warning: OPENWEATHERMAP_API_KEY not configured. Please update Config.xcconfig")
            #endif
            return ""
        }
        return key
    }

    static var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty && !openWeatherMapAPIKey.isEmpty
    }
}
