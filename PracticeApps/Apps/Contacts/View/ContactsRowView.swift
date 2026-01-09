//
//  ContactsRowView.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/6/26.
//

import SwiftUI

struct ContactsRowView: View {
    let contact: Contact
    
    var body: some View {
        HStack {
            Text(contact.initials)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color(.systemGray4))
                .clipShape(.circle)

            VStack(alignment: .leading) {
                Text("\(contact.firstName) \(contact.lastName)")
                
                Text(contact.email)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContactsRowView(
        contact: .init(
            id: "1",
            firstName: "Michael",
            lastName: "Jordan",
            email: "test@gmail.com"
        )
    )
}
