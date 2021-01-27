//
//  OpenMarketAPIClient.swift
//  OpenMarket
//
//  Created by Kyungmin Lee on 2021/01/27.
//

import Foundation

enum OpenMarketAPI {
    case requestMarketPage
    case registerMarketItem
    case requestMarketItem
    case modifyMarketItem
    case deleteMarketItem
    
    static let baseURL = "https://camp-open-market.herokuapp.com/"
    var path: String {
        switch self {
        case .requestMarketPage:
            return "items/"
        case .registerMarketItem:
            return "item"
        case .requestMarketItem:
            return "item/"
        case .modifyMarketItem:
            return "item/"
        case .deleteMarketItem:
            return "item/"
        }
    }
    var url: URL? {
        return URL(string: OpenMarketAPI.baseURL + path)
    }
}

enum OpenMarketAPIError: Error {
    case invalidURL
    case unknownError
}

class OpenMarketAPIClient {
    let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func requestMarketItem(id: Int, completion: @escaping (Result<MarketItem, Error>) -> Void) {
        guard let url = OpenMarketAPI.requestMarketItem.url?.appendingPathComponent("\(id)") else {
            completion(.failure(OpenMarketAPIError.invalidURL))
            return
        }
        
        let request = URLRequest(url: url)
        
        let task = urlSession.dataTask(with: request) { data, urlResponse, error in
            guard let response = urlResponse as? HTTPURLResponse, (200...399).contains(response.statusCode) else {
                completion(.failure(error ?? OpenMarketAPIError.unknownError))
                return
            }
            if let data = data,
               let marketItem = try? JSONDecoder().decode(MarketItem.self, from: data) {
                completion(.success(marketItem))
                return
            }
            completion(.failure(OpenMarketAPIError.unknownError))
        }
        task.resume()
    }
}
