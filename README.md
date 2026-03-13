# NetworkManager 🚀

A lightweight and reusable networking layer built with Swift Package Manager (SPM) using modern async/await.

It supports:

- ✅ GET / POST / PUT / DELETE / UPDATE requests
- ✅ URL Query Parameters for GET requests
- ✅ JSON body
- ✅ Form URL Encoded body
- ✅ Multipart image upload
- ✅ Custom headers
- ✅ Custom `JSONDecoder` support
- ✅ Strongly typed `Decodable` responses
- ✅ Modern Swift concurrency

---

## 📦 Installation

### Using Swift Package Manager

1. Open your Xcode project
2. Go to **File → Add Packages…**
3. Paste the repository URL:

```
https://github.com/Dileep7288/Network-Manager.git
```

4. Choose version rule:
```
Up to Next Major Version
```
5. Click **Add Package**

---

## 🚀 Usage

### Import the Package

```swift
import NetworkManager
```

---

## 🌍 GET Request Example

```swift
struct User: Decodable {
    let id: Int
    let name: String
}

// Support for query parameters
let parameters: [String: Any] = ["id": 123]

let user: User = try await NetworkManager.shared.request(
    urlString: "https://api.example.com/user",
    method: .get,
    parameters: parameters
)
```

---

## 📤 POST (Form URL Encoded)

```swift
let parameters: [String: Any] = [
    "mobileNumber": "9876543210",
    "code": "91"
]

let response: LoginResponse = try await NetworkManager.shared.request(
    urlString: "https://api.example.com/login",
    method: .post,
    parameters: parameters,
    bodyType: .formURLEncoded
)
```

---

## 🔄 PUT Request Example

Used to update an existing resource.

```swift
struct UpdateUserResponse: Decodable {
    let status: String
    let message: String
}

let parameters: [String: Any] = [
    "name": "John Doe",
    "email": "john@example.com"
]

let response: UpdateUserResponse = try await NetworkManager.shared.request(
    urlString: "https://api.example.com/user/1",
    method: .put,
    parameters: parameters,
    bodyType: .json
)
```

---

## ❌ DELETE Request Example

Used to delete a resource.

```swift
struct DeleteResponse: Decodable {
    let status: String
    let message: String
}

let response: DeleteResponse = try await NetworkManager.shared.request(
    urlString: "https://api.example.com/user/1",
    method: .delete
)
```

---

## 🔁 UPDATE Request Example

Used for partial updates.

```swift
struct UpdateResponse: Decodable {
    let status: String
    let message: String
}

let parameters: [String: Any] = [
    "status": "active"
]

let response: UpdateResponse = try await NetworkManager.shared.request(
    urlString: "https://api.example.com/user/status",
    method: .update,
    parameters: parameters,
    bodyType: .json
)
```
---

## 🖼 Multipart Image Upload

```swift
let media = Media(
    key: "pic",
    filename: "profile.jpg",
    data: imageData,
    mimeType: "image/jpeg"
)

let response: UploadResponse = try await NetworkManager.shared.request(
    urlString: "https://api.example.com/upload",
    method: .post,
    parameters: ["userId": "123"],
    bodyType: .multipart(boundary: nil, media: [media])
)
```

---

## 🧠 Error Handling

```swift
do {
    let response: MyModel = try await NetworkManager.shared.request(...)
} catch let error as NetworkError {
    switch error {
    case .noInternet:
        print("Check your connection")
    case .httpError(let code, let message):
        print("HTTP \(code): \(message)")
    case .serverError(let code, let message):
        print("Server \(code): \(message)")
    default:
        print(error.localizedDescription)
    }
} catch {
    print(error.localizedDescription)
}
```

---

## ⚙️ Requirements

- iOS 15+ / macOS 12+
- Swift 5.9+
- Xcode 15+

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
