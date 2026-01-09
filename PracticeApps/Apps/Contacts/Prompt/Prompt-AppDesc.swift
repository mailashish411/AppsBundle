//
//  Prompt-AppDesc.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/6/26.
//

/*
 *** OVERVIEW ***
Take Home / Live Interview Example
  
Live Setting - 1-2 hours of live coding. Get as far as you can
Take Home - Complete all tasks
  
Tests your knowledge of:
    - Data modeling
    - Navigation
    - App architecture
    - CRUD Operations and data persistence between views
    - General SwiftUI functionality
 -----------------------------------------------------
 
*** PROBLEM STATEMENT ***

 Design and implement a simple Contacts App using SwiftUI that provides basic
 functionality similar to the native iPhone Contacts app.
 
 Requirements:
 
 Contact Data:
    - First name
    - Last name
    - Email

 View Contacts:
    - Display a vertically scrollable list of contacts.
    - Display contact initials in a circular view for each contact
    - Next to the initials view, display contact first name, last name and email (See UI)
 
 Add a Contact:
    - Provide a screen where users can add new contacts by entering a first name, last name and email.
 
 Edit a Contact:  ✅
    - Allow users to edit an existing contact's details. ✅
    - Enable save button only if changes have been made to contact (Bonus) ✅
    - If changes have been made and user tries to exit, show an alert confirmation warning (Bonus)  ✅
 
 Search for contacts: ✅
    - Add a search bar to filter contacts ✅
    - Search should be on user's name or email ✅
 
 Delete a Contact:
    - Add deletion button on contact detail screen ✅
    - Add confirmation alert for contact deletion in edit screen (Bonus) ✅
    - Swipe to delete (Bonus feature) ✅

Navigation Logic:  ✅
    - Add contact should be a modal sheet  ✅
    - Edit contact should be a navigation push to a contact detail screen  ✅
 
 The contact list should persist for the session (no need for long-term storage like Core Data). ✅
 
 Follow-Up Questions
    1. How would you persist the contact list between app sessions?
    Answer: Use Core/Swift Data, file-storage with FileManager or SQLite.
 
    2. Should we use a remote data base for this application?
    Answer: Potentially yes, simply to serve as backup storage in case a user were to lose their device.
 
    3. How would you handle large lists of contacts for performance?
    Answer: Pagination
*/

