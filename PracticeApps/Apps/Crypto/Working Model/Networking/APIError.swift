//
//  APIError.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import Foundation

enum APIError: LocalizedError {
    case httpError(statusCode: Int, bodySnippet: String)
    case decodingFailed(underlying: Error, bodySnippet: String)

    var errorDescription: String? {
        switch self {
        case let .httpError(code, snippet):
            return "HTTP \(code). Response: \(snippet)"
        case let .decodingFailed(underlying, snippet):
            return "Decoding failed: \(underlying). Body: \(snippet)"
        }
    }
}
