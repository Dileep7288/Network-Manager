import Testing
import Foundation
@testable import NetworkManager

// MARK: - Mock URLProtocol
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler not set.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

// MARK: - Tests
@Suite(.serialized)
struct NetworkManagerTests {
    
    let manager: NetworkManager
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        manager = NetworkManager(session: session)
    }
    
    struct MockResponse: Codable, Equatable {
        let id: Int
        let name: String
    }
    
    @Test func testGETRequestWithQueryParameters() async throws {
        let urlString = "https://api.example.com/test"
        let parameters = ["key": "value", "id": 123] as [String : Any]
        
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            #expect(url.query?.contains("key=value") == true)
            #expect(url.query?.contains("id=123") == true)
            #expect(request.httpMethod == "GET")
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = #"{"id": 1, "name": "Test"}"#.data(using: .utf8)!
            return (response, data)
        }
        
        let result: MockResponse = try await manager.request(urlString: urlString, method: .get, parameters: parameters)
        #expect(result.id == 1)
        #expect(result.name == "Test")
    }
    
    @Test func testPOSTRequestWithJSONBody() async throws {
        let urlString = "https://api.example.com/test"
        let parameters = ["name": "New Item"]
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            
            let bodyData = request.extractBodyData()
            let body = try! JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: String]
            #expect(body?["name"] == "New Item")
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            let data = #"{"id": 2, "name": "New Item"}"#.data(using: .utf8)!
            return (response, data)
        }
        
        let result: MockResponse = try await manager.request(urlString: urlString, method: .post, parameters: parameters)
        #expect(result.id == 2)
    }
    
    @Test func testUpdateRequest() async throws {
        let urlString = "https://api.example.com/test/1"
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "UPDATE")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = #"{"id": 1, "name": "Patched"}"#.data(using: .utf8)!
            return (response, data)
        }
        
        let result: MockResponse = try await manager.request(urlString: urlString, method: .update)
        #expect(result.name == "Patched")
    }
    
    @Test func testHTTPErrorHandling() async throws {
        let urlString = "https://api.example.com/error"
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            let data = "Not Found".data(using: .utf8)!
            return (response, data)
        }
        
        do {
            let _: MockResponse = try await manager.request(urlString: urlString, method: .get)
            Issue.record("Should have thrown an error")
        } catch let NetworkError.httpError(code, message) {
            #expect(code == 404)
            #expect(message == "Not Found")
        } catch {
            Issue.record("Wrong error thrown: \(error)")
        }
    }

    @Test func testServerErrorHandling() async throws {
        let urlString = "https://api.example.com/server-error"
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = "Internal Server Error".data(using: .utf8)!
            return (response, data)
        }
        
        do {
            let _: MockResponse = try await manager.request(urlString: urlString, method: .get)
            Issue.record("Should have thrown an error")
        } catch let NetworkError.serverError(code, message) {
            #expect(code == 500)
            #expect(message == "Internal Server Error")
        } catch {
            Issue.record("Wrong error thrown: \(error)")
        }
    }
}

// MARK: - Helpers
extension URLRequest {
    func extractBodyData() -> Data {
        if let httpBody = httpBody {
            return httpBody
        }
        if let httpBodyStream = httpBodyStream {
            let data = NSMutableData()
            httpBodyStream.open()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while httpBodyStream.hasBytesAvailable {
                let read = httpBodyStream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, length: read)
                } else {
                    break
                }
            }
            buffer.deallocate()
            httpBodyStream.close()
            return data as Data
        }
        return Data()
    }
}
