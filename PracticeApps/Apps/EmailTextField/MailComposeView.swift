//
//  EmailChip.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/8/26.
//

import SwiftUI

//struct EmailChip: View {
//    let email: String
//    let onRemove: () -> Void
//
//    var body: some View {
//        HStack {
//            Text(email)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(RoundedRectangle(cornerRadius: 12).opacity(0.15))
//            Button("×", action: onRemove)
//                .font(.headline)
//        }
//        .padding(4)
//    }
//}
//
//struct RecipientInputBar: View {
//    @State private var query = ""
//    @State private var suggestions: [String] = []
//    @State private var recipients: [String] = []
//    let allEmails: [String]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack {
//                    ForEach(recipients, id: \.self) { email in
//                        EmailChip(email: email) {
//                            recipients.removeAll { $0 == email }
//                        }
//                    }
//                    TextField("Enter email", text: $query)
//                        .frame(minWidth: 120)
//                        .onChange(of: query) { _, text in
//                          suggestions = allEmails.filter {
//                            $0.lowercased().contains(text.lowercased())
//                          }
//                        }
//                }
//                .padding(6)
//            }
//            .background(RoundedRectangle(cornerRadius: 14).stroke().opacity(0.3))
//
//            if !suggestions.isEmpty && !query.isEmpty {
//                VStack(alignment: .leading) {
//                    ForEach(suggestions.prefix(5), id: \.self) { email in
//                        Button(email) {
//                            recipients.append(email)
//                            query = ""
//                            suggestions = []
//                        }
//                        .padding(.vertical, 6)
//                    }
//                }
//                .background(RoundedRectangle(cornerRadius: 12).opacity(0.05))
//                .padding(.horizontal, 4)
//            }
//        }
//    }
//}
//
//struct MailComposeView: View {
//    let allEmails = [
//        "ashish@company.com", "ash@expedia.com", "ash.manager@travel.com",
//        "jeff@company.com", "ash.teamlead@casino.app"
//    ]
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Compose Mail").font(.title2.bold())
//
//            RecipientInputBar(allEmails: allEmails)
//                .padding(.horizontal)
//
//            Text("CC")
//                .font(.subheadline.bold())
//                .padding(.horizontal)
//            RecipientInputBar(allEmails: allEmails)
//                .padding(.horizontal)
//
//            Text("BCC")
//                .font(.subheadline.bold())
//                .padding(.horizontal)
//            RecipientInputBar(allEmails: allEmails)
//                .padding(.horizontal)
//
//            Spacer()
//        }
//        .padding(.top)
//    }
//}

// Beautify Version

//
//  EmailChip.swift
//  PracticeApps
//
//  Beautified UI version (chips + token field + dropdown suggestions)
//

import SwiftUI

// MARK: - Email Chip

struct EmailChip: View {
    let email: String
    let onRemove: () -> Void

    private var initials: String {
        let name = email.split(separator: "@").first.map(String.init) ?? "?"
        let parts = name
            .replacingOccurrences(of: ".", with: " ")
            .split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = (parts.dropFirst().first?.first).map(String.init) ?? ""
        let value = (first + second).uppercased()
        return value.isEmpty ? "?" : value
    }

    var body: some View {
        HStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.18))
                Text(initials)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 22, height: 22)

            Text(email)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(Color(.tertiarySystemFill))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    Capsule().stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                )
        )
        .contentShape(Capsule())
    }
}

// MARK: - Recipient Input Bar

struct RecipientInputBar: View {
    let title: String
    let allEmails: [String]

    @State private var query = ""
    @State private var suggestions: [String] = []
    @State private var recipients: [String] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label row
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if !recipients.isEmpty {
                    Button("Clear") {
                        recipients = []
                        query = ""
                        suggestions = []
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }

            // Token field
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipients, id: \.self) { email in
                            EmailChip(email: email) {
                                recipients.removeAll { $0 == email }
                                updateSuggestions()
                            }
                        }

                        TextField("Add recipient…", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .submitLabel(.done)
                            .focused($isFocused)
                            .frame(minWidth: 140)
                            .onSubmit { commitTypedEmailIfValid() }
                            .onChange(of: query) { _, _ in
                                updateSuggestions()
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isFocused ? Color.accentColor.opacity(0.55) : Color(.separator).opacity(0.35), lineWidth: 1)
                    )
            )
            .animation(.easeInOut(duration: 0.18), value: isFocused)

            // Suggestions dropdown
            if isFocused && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions.prefix(6), id: \.self) { email in
                        Button {
                            addRecipient(email)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)

                                Text(email)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Image(systemName: "arrow.turn.down.left")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        if email != suggestions.prefix(6).last {
                            Divider().opacity(0.7)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: suggestions)
    }

    // MARK: - Helpers

    private func updateSuggestions() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            suggestions = []
            return
        }

        // Remove already-added recipients from suggestions
        let existing = Set(recipients.map { $0.lowercased() })

        suggestions = allEmails
            .filter { !existing.contains($0.lowercased()) }
            .filter { $0.lowercased().contains(q) }
            .sorted { $0.count < $1.count }
    }

    private func addRecipient(_ email: String) {
        guard !recipients.contains(email) else { return }
        recipients.append(email)
        query = ""
        suggestions = []
    }

    private func commitTypedEmailIfValid() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // very light validation (good enough for UI demo)
        let looksValid = trimmed.contains("@") && trimmed.contains(".") && !trimmed.contains(" ")
        if looksValid {
            addRecipient(trimmed)
        } else {
            // If invalid, just keep focus and show suggestions (or clear if you want)
            // query = ""
        }
    }
}

// MARK: - Mail Compose View

struct MailComposeView: View {
    let allEmails = [
        "ashish@company.com", "ash@expedia.com", "ash.manager@travel.com",
        "jeff@company.com", "ash.teamlead@casino.app",
        "support@pokeapi.co", "team@openai.com"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header

                RecipientInputBar(title: "To", allEmails: allEmails)

                RecipientInputBar(title: "CC", allEmails: allEmails)

                RecipientInputBar(title: "BCC", allEmails: allEmails)

                Divider().opacity(0.6)
                    .padding(.vertical, 6)

                // Placeholder content area so it feels like a compose screen
                VStack(alignment: .leading, spacing: 10) {
                    Text("Subject")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Add a subject…", text: .constant(""))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Message")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextEditor(text: .constant(""))
                        .frame(minHeight: 220)
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Compose")
                    .font(.system(size: 28, weight: .heavy))
                Text("Add recipients like Yahoo Mail")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MailComposeView()
}
