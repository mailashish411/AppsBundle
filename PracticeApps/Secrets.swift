//
//  Secrets.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

enum Secrets {
    static let openWeatherAPIKey: String = {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let key = dict["OPEN_WEATHER_API_KEY"] as? String
        else {
            fatalError("OPEN_WEATHER_API_KEY not found in Secrets.plist")
        }
        return key
    }()
}
