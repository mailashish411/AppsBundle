//
//  Root.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/6/26.
//

import SwiftUI
import UIKit

// MARK: - 1) Your app choices
enum PracticeApp: String, CaseIterable, Identifiable {
    case contacts = "Contacts"
    case bankAccounts = "Bank Accounts"
    case movies = "Movies"
    case music = "Music"
    case weather = "Weather"
    case mailComposeView = "Mail Compose View"
    case crypto = "Coin Gecko"

    var id: String { rawValue }
}

// MARK: - 2) Root view (THIS is what you use as your start screen)
struct RootView: View {

    // Preview-friendly init so you can force picker/running states in Canvas
    @State private var selected: PracticeApp
    @State private var running: PracticeApp?

    init(initialSelected: PracticeApp = .contacts, initialRunning: PracticeApp? = nil) {
        _selected = State(initialValue: initialSelected)
        _running = State(initialValue: initialRunning)
    }

    var body: some View {
        ZStack {
            if let running {
                appRoot(for: running)
                    .overlay(alignment: .topTrailing    ) {
                        Button {
                            withAnimation { self.running = nil }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .padding()
                        }
                        .accessibilityLabel("Back to app picker")
                    }

            } else {
                launcherView
            }
        }
    }

    private var launcherView: some View {
        VStack(spacing: 16) {
            Text("Practice Apps")
                .font(.largeTitle.bold())

            Picker("Select App", selection: $selected) {
                ForEach(PracticeApp.allCases) { app in
                    Text(app.rawValue).tag(app)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxHeight: 500)
            Spacer()
            Button {
                withAnimation(.spring()) {
                    running = selected
                }
            } label: {
                Text("Run \(selected.rawValue)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Text("Tip: Use the top-left button to return to this screen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - 3) Map selection -> actual root view
    @ViewBuilder
    private func appRoot(for app: PracticeApp) -> some View {
        switch app {
        case .contacts:
            ContactsView()

        case .bankAccounts:
            BankAccountsView()

        case .movies:
            MoviesView()

        case .music:
            MusicView()

        case .weather:
            WeatherView()
            
        case .mailComposeView:
            MailComposeView()
            
        case .crypto:
            CryptoListView()
        }
    }
}

// MARK: - Dummy Screens (replace with real ones)
// NOTE: Your real ContactsView exists elsewhere, so keep it commented here.
// struct ContactsView: View { var body: some View { screen("Contacts") } }

struct BankAccountsView: View { var body: some View { screen("Bank Accounts") } }
struct MoviesView: View { var body: some View { screen("Movies") } }
struct MusicView: View { var body: some View { screen("Music") } }
struct WeatherView: View { var body: some View { screen("Weather") } }

private func screen(_ title: String) -> some View {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        Text("\(title) Root")
            .font(.largeTitle.bold())
    }
}

// MARK: - 5) Previews (Canvas)
#Preview("Picker Launcher") {
    RootView(initialSelected: .contacts, initialRunning: nil)
}

#Preview("Running Contacts") {
    RootView(initialSelected: .contacts, initialRunning: .contacts)
}

