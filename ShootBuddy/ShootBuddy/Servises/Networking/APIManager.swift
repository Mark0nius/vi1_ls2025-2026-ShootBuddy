//
//  APIManager.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

protocol APIManaging {
    // generic function
    // Meaning: Object T must be decodable (specified inside <>)
    // We fire request and in return we want any object that is decodable
    func request<T: Decodable>(_ endpoint: Router) async throws -> T
}

// APIManager needs to implement APIManaging for DI
final class APIManager: APIManaging {
    private let decoder = JSONDecoder()

    func request<T: Decodable>(_ endpoint: Router) async throws -> T {
        // make URLRequest from endpoint
        let request = try endpoint.asRequest()
        // URLSession sends URLRequest
        let (data, response) = try await URLSession.shared.data(for: request)

        // retype to HTTPURLResponse for status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noResponse
        }

        // accept only 200-299 status codes
        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.unacceptableResponseStatusCode
        }

        // decode data to decodable object
        let object = try decoder.decode(T.self, from: data)
        return object
    }
}
