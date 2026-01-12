//
//  APIError.swift
//  SharedKit
//
//  Created by Ashish Shaik on 1/12/26.
//

import Foundation

public enum APIError: LocalizedError {
    case httpError(statusCode: Int, bodySnippet: String)
    case decodingFailed(underlying: Error, bodySnippet: String)

    public var errorDescription: String? {
        switch self {
        case let .httpError(code, snippet):
            return "HTTP \(code). Response: \(snippet)"
        case let .decodingFailed(underlying, snippet):
            return "Decoding failed: \(underlying). Body: \(snippet)"
        }
    }
}
