//
//  NetworkError.swift
//  NetworkManager
//
//  Created by Dileep Kumar on 26/02/26.
//

import Foundation

public enum NetworkError: Error, LocalizedError {
    case noInternet
    case timeout
    case invalidURL
    case invalidResponse
    case invalidParameters
    case decodingFailed(Error)
    case httpError(code: Int, message: String)
    case serverError(code: Int, message: String)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection."
        case .timeout:
            return "The request timed out. Please try again."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .invalidParameters:
            return "Invalid request parameters."
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .httpError(_, let message),
             .serverError(_, let message):
            return message
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
