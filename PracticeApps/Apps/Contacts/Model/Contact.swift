//
//  Contact.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/6/26.
//

import Foundation

struct Contact: Identifiable, Hashable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    
    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        
        return String(first + last)
    }
}
