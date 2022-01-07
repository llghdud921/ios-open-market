import Foundation

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

class APIService {
    private let session: URLSessionProtocol
    private let identifier = "cd706a3e-66db-11ec-9626-796401f2341a"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
        
    private func dataTask(request: URLRequest, completion: @escaping (Result<Data, APIError>) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(.failure(.invalidRequest))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                      completion(.failure(.invalidResponse))
                      return
                  }

            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            completion(.success(data))
        }
        
        return task
    }
}

// MARK: - OpenMarket APIs

extension APIService {
    func retrieveProductDetail(productId: Int, completion: @escaping (Result<ProductDetail, APIError>) -> Void) {
        guard let url = URLCreator.productDetail(id: productId).url else {
            completion(.failure(.invalidURL))
            return
        }
        
        let request = URLRequest(url: url, api: .productDetail)
        
        let task = dataTask(request: request) { result in
            switch result {
            case .success(let data):
                guard let productDetail = try? self.decoder.decode(ProductDetail.self, from: data) else {
                    return
                }
                completion(.success(productDetail))
            case .failure(let error):
                completion(.failure(error))
            }
        }
            
        task.resume()
    }
    
    func retrieveProductList(pageNo: Int, itemsPerPage: Int, completion: @escaping (Result<ProductList, APIError>) -> Void) {
        guard let url = URLCreator.productList(pageNo: pageNo, itemsPerPage: itemsPerPage).url else {
            completion(.failure(.invalidURL))
            return
        }
        
        let request = URLRequest(url: url, api: .productList)
        
        let task = dataTask(request: request) { result in
            switch result {
            case .success(let data):
                guard let productList = try? self.decoder.decode(ProductList.self, from: data) else {
                    return
                }
                completion(.success(productList))
            case .failure(let error):
                completion(.failure(error))
            }
        }
            
        task.resume()
    }
    
    func retrieveProductSecret(productId: Int, secret: String, completion: @escaping (Result<String, APIError>) -> Void) {
        guard let url = URLCreator.productSecret(id: productId).url else {
            return
        }
        
        guard let body = try? JSONEncoder().encode(secret) else {
            return
        }
        
        let request = URLRequest(url: url, api: .productSecret(body: body, id: identifier))
        
        let task = dataTask(request: request) { result in
            switch result {
            case .success(let data):
                if let convertedData = String(data: data, encoding: .utf8) {
                    completion(.success(convertedData))
                }
            case .failure(let error):
                print(error)
            }
        }
        
        task.resume()
    }
    
    func registerProduct(newProduct: ProductRegisterInformation, images: [ImageData], completion: @escaping (Result<Data, APIError>) -> Void) {
        guard let url = URLCreator.productRegister.url else {
            return
        }
                
        guard let body = createBody(productRegisterInformation: newProduct, images: images) else {
            return
        }
        
        let request = URLRequest(url: url, api: .productRegister(body: body, id: identifier))
        
        let task = dataTask(request: request, completion: completion)
        
        task.resume()
    }
    
    func updateProduct(productId: Int, modifiedProduct: ProductRegisterInformation, completion: @escaping (Result<Data, APIError>) -> Void) {
        guard let url = URLCreator.productUpdate(id: productId).url else {
            return
        }
        
        guard let body = try? JSONEncoder().encode(modifiedProduct) else {
            return
        }
        
        let request = URLRequest(url: url, api: .productUpdate(body: body, id: identifier))
        
        let task = dataTask(request: request, completion: completion)
        
        task.resume()
    }
    
    func deleteProduct(productId: Int, secret: String, completion: @escaping (Result<Data, APIError>) -> Void) {
        guard let url = URLCreator.deleteProduct(id: productId, secret: secret).url else {
            return
        }
        
        let request = URLRequest(url: url, api: .deleteProduct(id: identifier))
        
        let task = dataTask(request: request, completion: completion)
        
        task.resume()
    }
}

// MARK: - Create Request Body

private extension APIService {
    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    func createBody(productRegisterInformation: ProductRegisterInformation, images: [ImageData]) -> Data? {
        var body: Data = Data()
        let boundary = generateBoundary()
        
        guard let jsonData = try? JSONEncoder().encode(productRegisterInformation) else {
            return nil
        }
        
        let parameters: [String: Any] = ["params": jsonData]
        
        parameters.forEach { (key, value) in
            body.append(convertDataToMultiPartForm(name: key, value: value, boundary: boundary))
        }
        
        images.forEach { image in
            body.append(convertFileToMultiPartForm(imageData: image, boundary: boundary))
        }
        
        return body
    }

    func convertDataToMultiPartForm(name: String, value: Any, boundary: String) -> Data {
        var data: Data = Data()
        let mimeType = "application/json"
        
        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.appendString("\(value)\r\n")
        
        return data
    }
    
    func convertFileToMultiPartForm(imageData: ImageData, boundary: String) -> Data {
        var data: Data = Data()
        
        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"images\"; filename=\(imageData.fileName)\r\n")
        data.appendString("Content-Type: image/\(imageData.type.description)\r\n\r\n")
        data.appendString("\(imageData.data)\r\n")
        
        return data
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        self.append(data)
    }
}