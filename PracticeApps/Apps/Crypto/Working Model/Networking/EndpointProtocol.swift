//
//  EndpointProtocol.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

protocol Endpoint {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

extension Endpoint {
    var scheme: String { "https" }
    var host: String { "api.coingecko.com" }

    func url() throws -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = host
        c.path = path
        c.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = c.url else {
            throw URLError(.badURL)
        }
        return url
    }
}
