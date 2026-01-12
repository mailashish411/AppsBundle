//
//  Endpoint.swift
//  SharedKit
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

public protocol Endpoint {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

public extension Endpoint {
    var scheme: String { "https" }
    var queryItems: [URLQueryItem] { [] }

    func url() throws -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = host
        c.path = path
        c.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = c.url else { throw URLError(.badURL) }
        return url
    }
}
