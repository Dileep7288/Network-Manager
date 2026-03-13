// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public final class NetworkManager: @unchecked Sendable {
    
    public static let shared = NetworkManager()
    
    private let session: URLSession
    
    // MARK: - Initializer (Testable)
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Request Method
    
    public func request<T: Decodable>(
        urlString: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        bodyType: BodyType = .json,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        
        // MARK: - URL Construction
        guard var components = URLComponents(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        // Handle Query Parameters for GET/DELETE/PATCH/PUT if not using body
        if method == .get, let params = parameters {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // MARK: - Headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // MARK: - Body Handling (Only if not GET)
        if method != .get {
            switch bodyType {
            case .formURLEncoded:
                try setFormURLEncodedBody(for: &request, parameters: parameters)
            case .json:
                try setJSONBody(for: &request, parameters: parameters)
            case .multipart(let boundary, let media):
                setMultipartBody(for: &request, parameters: parameters, boundary: boundary, media: media)
            }
        }
        
        // MARK: - Perform Request
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw NetworkError.noInternet
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.unknown(error)
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        #if DEBUG
        if let raw = String(data: data, encoding: .utf8) {
            debugPrint("📩 [\(httpResponse.statusCode)] \(url.absoluteString)\nResponse: \(raw)")
        }
        #endif
        
        // MARK: - Success
        if (200...299).contains(httpResponse.statusCode) {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        }
        
        // MARK: - Failure
        let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
        
        if (500...599).contains(httpResponse.statusCode) {
            throw NetworkError.serverError(code: httpResponse.statusCode, message: message)
        } else {
            throw NetworkError.httpError(code: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - Private Helpers

private extension NetworkManager {
    
    func setFormURLEncodedBody(for request: inout URLRequest, parameters: [String: Any]?) throws {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        guard let params = parameters else { return }
        
        let bodyString = params
            .map { "\($0.key)=\(percentEscape("\($0.value)"))" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
    }
    
    func setJSONBody(for request: inout URLRequest, parameters: [String: Any]?) throws {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let parameters = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
    }
    
    func setMultipartBody(for request: inout URLRequest, parameters: [String: Any]?, boundary: String?, media: [Media]?) {
        let finalBoundary = boundary ?? "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(finalBoundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartBody(parameters: parameters, media: media, boundary: finalBoundary)
    }
    
    func createMultipartBody(parameters: [String: Any]?, media: [Media]?, boundary: String) -> Data {
        
        var body = Data()
        let lineBreak = "\r\n"
        
        // Parameters
        parameters?.forEach { key, value in
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
            body.append("\(value)\(lineBreak)")
        }
        
        // Media Files
        media?.forEach { media in
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(media.key)\"; filename=\"\(media.filename)\"\(lineBreak)")
            body.append("Content-Type: \(media.mimeType)\(lineBreak + lineBreak)")
            body.append(media.data)
            body.append(lineBreak)
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    func percentEscape(_ string: String) -> String {
        let allowed = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._* "
        )
        
        return string
            .addingPercentEncoding(withAllowedCharacters: allowed)?
            .replacingOccurrences(of: " ", with: "+")
            ?? string
    }
}

// MARK: - Data Extension

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
