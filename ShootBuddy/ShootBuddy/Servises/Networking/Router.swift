//
//  Router.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

protocol Router {
    var host: String { get }
    var path: String { get }
    var method: HttpMethod { get }
    var urlParameters: [String: Any]? { get }
    var headers: [String: String] { get }

    func asRequest() throws -> URLRequest
}

extension Router {
    func asRequest() throws -> URLRequest {
        guard let host = URL(string: host) else {
            throw APIError.invalidHost
        }
        
        let urlPath = host.appending(path: path)
        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURLComponents
        }
        
        if let urlParameters {
            urlComponents.queryItems = urlParameters.map({ (key, value) in
                URLQueryItem(name: key, value: String(describing: value))
            })
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURLComponents
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        
        print("🛜 \(request)")
        return request
    }
}

enum APIError: Error {
    case invalidHost
    case invalidURLComponents
    case noResponse
    case unacceptableResponseStatusCode
}
