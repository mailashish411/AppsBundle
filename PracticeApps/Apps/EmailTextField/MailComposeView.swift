//
//  EmailChip.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/8/26.
//

import SwiftUI

struct EmailChip: View {
    let email: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(email)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 12).opacity(0.15))
            Button("×", action: onRemove)
                .font(.headline)
        }
        .padding(4)
    }
}

struct RecipientInputBar: View {
    @State private var query = ""
    @State private var suggestions: [String] = []
    @State private var recipients: [String] = []
    let allEmails: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(recipients, id: \.self) { email in
                        EmailChip(email: email) {
                            recipients.removeAll { $0 == email }
                        }
                    }
                    TextField("Enter email", text: $query)
                        .frame(minWidth: 120)
//                        .onChange(of: query) { text in
//                            suggestions = allEmails.filter {
//                                $0.lowercased().contains(text.lowercased())
//                            }
//                        }
                        .onChange(of: query) { _, text in
                          suggestions = allEmails.filter {
                            $0.lowercased().contains(text.lowercased())
                          }
                        }
                }
                .padding(6)
            }
            .background(RoundedRectangle(cornerRadius: 14).stroke().opacity(0.3))

            if !suggestions.isEmpty && !query.isEmpty {
                VStack(alignment: .leading) {
                    ForEach(suggestions.prefix(5), id: \.self) { email in
                        Button(email) {
                            recipients.append(email)
                            query = ""
                            suggestions = []
                        }
                        .padding(.vertical, 6)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).opacity(0.05))
                .padding(.horizontal, 4)
            }
        }
    }
}

struct MailComposeView: View {
    let allEmails = [
        "ashish@company.com", "ash@expedia.com", "ash.manager@travel.com",
        "jeff@company.com", "ash.teamlead@casino.app"
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Compose Mail").font(.title2.bold())

            RecipientInputBar(allEmails: allEmails)
                .padding(.horizontal)

            Text("CC")
                .font(.subheadline.bold())
                .padding(.horizontal)
            RecipientInputBar(allEmails: allEmails)
                .padding(.horizontal)

            Text("BCC")
                .font(.subheadline.bold())
                .padding(.horizontal)
            RecipientInputBar(allEmails: allEmails)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }
}
