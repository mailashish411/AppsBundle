//
//  APIClientProtocol.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

protocol APIClientProtocol {
    var session: URLSession { get }
    var decoder: JSONDecoder { get }
    func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T
}

extension APIClientProtocol {
    func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validateHTTP(response: response, data: data)
        return try decode(type, from: data)
    }

    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let url = try endpoint.url()
        return try await request(url, as: type)
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            let snippet = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            throw APIError.decodingFailed(underlying: error, bodySnippet: String(snippet.prefix(400)))
        }
    }

    func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: http.statusCode, bodySnippet: String(body.prefix(400)))
        }
    }
}
