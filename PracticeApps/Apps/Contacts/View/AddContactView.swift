//
//  AddContactView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/6/26.
//

import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ContactsViewModel.self) var viewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("First name", text: $firstName)
                
                TextField("Last name", text: $lastName)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        addContact()
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
}

private extension AddContactView {
    func addContact() {
        let contact = Contact(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            email: email
        )
        
        viewModel.addContact(contact)
    }
}

#Preview {
    AddContactView()
        .environment(ContactsViewModel())
}
