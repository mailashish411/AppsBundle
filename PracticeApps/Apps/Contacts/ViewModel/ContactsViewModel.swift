//
//  ContactsViewModel.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/6/26.
//

import Foundation
import Observation

@Observable
class ContactsViewModel {
    var contacts = [Contact]()
    
    init() {
        fetchContacts()
    }
    
    func fetchContacts() {
        contacts = [
            .init(
                id: "1",
                firstName: "Michael",
                lastName: "Jordan",
                email: "jumpman23@gmail.com"
            ),
            .init(
                id: "2",
                firstName: "Kobe",
                lastName: "Bryant",
                email: "mamba@gmail.com"
            ),
            .init(
                id: "3",
                firstName: "Lebron",
                lastName: "James",
                email: "king.james@gmail.com"
            )
        ]
    }
    
    func addContact(_ contact: Contact) {
        contacts.append(contact)
    }
    
    func deleteContact(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts.remove(at: index)
    }
    
    func updateContact(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[index] = contact
    }
    
    func searchResults(for query: String) -> [Contact] {
        guard !query.isEmpty else {
            return contacts
        }
        
        return contacts.filter {
            $0.firstName.localizedCaseInsensitiveContains(query) ||
            $0.lastName.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
}
