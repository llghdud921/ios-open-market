//
//  NetworkManager.swift
//  OpenMarket
//
//  Created by 박태현 on 2021/08/10.
//

import UIKit
typealias Parameters = [String: Any]

enum NetworkError: Error {
    case invalidURL
    case invalidResult
    case unownedResponse
    case unownedData
}

class NetworkManager {

    private let session: URLSessionProtocol
    lazy var boundary = generateBoundary()

    var valuableMethod: [APIMethod] = []
    
    
    init(session: URLSessionProtocol = URLSession.shared, valuableMethod: [APIMethod] = APIMethod.allCases) {
        self.session = session
        self.valuableMethod = valuableMethod
    }

    func commuteWithAPI(API: Requestable, completion: @escaping(Result<Data, Error>) -> Void) {
        guard let request = try? createRequest(url: API.url, API: API) else { return }
        
        guard valuableMethod.contains(API.method) else {
            return completion(.failure(NetworkError.invalidResult))
        }
        session.dataTask(with: request) { data, response, error in
            if let error = error { return completion(.failure(error)) }

            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
                return completion(.failure(NetworkError.unownedResponse))
            }
            debugPrint(response)
            
            guard let data = data else {
                return completion(.failure(NetworkError.unownedData))
            }
            debugPrint(String(decoding: data, as: UTF8.self))
                completion(.success(data))
        }.resume()
    }
}

//MARK: URL, URLRequest, RequestDataBody 구성 파트
extension NetworkManager {

    private func createRequest(url: String, API: Requestable) throws -> URLRequest {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = API.method.method
        
        if API.contentType == ContentType.multipart {
            request.setValue(API.contentType.description + boundary, forHTTPHeaderField: "Content-Type")
        } else {
            request.setValue(API.contentType.description, forHTTPHeaderField: "Content-Type")
        }
        
        if let api = API as? DeleteAPI {
            guard let body = try? JSONEncoder().encode(api.deleteItemData) else { throw NetworkError.unownedData}
            request.httpBody = body
        } else if let api = API as? RequestableWithBody {
            let body = createDataBody(withParameters: api.parameter, media: api.items)
             request.httpBody = body
               
            debugPrint(String(decoding: body, as: UTF8.self))
        }
        
        
        return request
    }

    private func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }

    private func createDataBody(withParameters params: Parameters?, media: [Media]?) -> Data {
        var body = Data()
        
        let lineBreakPoint = "\r\n"

        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary)\(lineBreakPoint)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreakPoint + lineBreakPoint)")
                body.append("\(value)\(lineBreakPoint)")
            }
        }

        if let media = media {
            for photo in media {
                body.append("--\(boundary)\(lineBreakPoint)")
                body.append("Content-Disposition: form-data; name=\"\(photo.key)\"; filename=\"\(photo.filename)\"\(lineBreakPoint)")
                body.append("Content-Type: \(photo.mimeType)\(lineBreakPoint + lineBreakPoint)")
                body.append(photo.data)
                body.append(lineBreakPoint)
            }
        }
        body.append("--\(boundary)--\(lineBreakPoint)")

        return body
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

//MARK: Image를 받아오는 logic
extension NetworkManager {
    func downloadImage(from link: String, success block: @escaping (UIImage) -> Void) {
        guard let url = URL(string: link) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            block(image)
        }.resume()
    }
}
