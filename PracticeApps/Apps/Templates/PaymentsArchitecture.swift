//
//  PaymentsArchitecture.swift
//  Templates
//
//  Created by Ashish Shaik on 1/16/26.
//

import Foundation


// MARK: - Domain

enum PaymentMethod: Sendable, Equatable {
    case card(numberLast4: String)
    case applePay(token: String)
}

struct PaymentRequest: Sendable, Equatable {
    let amountCents: Int
    let currency: String
    let method: PaymentMethod
}

struct PaymentReceipt: Sendable, Equatable {
    let id: String
    let amountCents: Int
    let provider: String
}

// MARK: - Processor boundary

protocol PaymentProcessor: Sendable {
    func canProcess(_ method: PaymentMethod) -> Bool
    func charge(_ request: PaymentRequest) async throws -> PaymentReceipt
}

// MARK: - Router (picks processor)

struct PaymentRouter: Sendable {
    let processors: [PaymentProcessor]

    func charge(_ request: PaymentRequest) async throws -> PaymentReceipt {
        guard let processor = processors.first(where: { $0.canProcess(request.method) }) else {
            throw NSError(domain: "Payment", code: 404, userInfo: [NSLocalizedDescriptionKey: "No processor for method"])
        }
        return try await processor.charge(request)
    }
}

// MARK: - Concrete processors (stubs for interview)

struct CardProcessor: PaymentProcessor {
    func canProcess(_ method: PaymentMethod) -> Bool {
        if case .card = method { return true }
        return false
    }

    func charge(_ request: PaymentRequest) async throws -> PaymentReceipt {
        // call gateway, tokenize, etc.
        return PaymentReceipt(id: "card_txn_1", amountCents: request.amountCents, provider: "CardGateway")
    }
}

struct ApplePayProcessor: PaymentProcessor {
    func canProcess(_ method: PaymentMethod) -> Bool {
        if case .applePay = method { return true }
        return false
    }

    func charge(_ request: PaymentRequest) async throws -> PaymentReceipt {
        return PaymentReceipt(id: "applepay_txn_1", amountCents: request.amountCents, provider: "ApplePay")
    }
}

// MARK: - Tests

final class PaymentRouterTests: XCTestCase {

    func test_routesToApplePay() async throws {
        let router = PaymentRouter(processors: [CardProcessor(), ApplePayProcessor()])

        let receipt = try await router.charge(.init(
            amountCents: 999,
            currency: "USD",
            method: .applePay(token: "tok")
        ))

        XCTAssertEqual(receipt.provider, "ApplePay")
        XCTAssertEqual(receipt.amountCents, 999)
    }

    func test_routesToCard() async throws {
        let router = PaymentRouter(processors: [ApplePayProcessor(), CardProcessor()])

        let receipt = try await router.charge(.init(
            amountCents: 500,
            currency: "USD",
            method: .card(numberLast4: "4242")
        ))

        XCTAssertEqual(receipt.provider, "CardGateway")
    }
}
