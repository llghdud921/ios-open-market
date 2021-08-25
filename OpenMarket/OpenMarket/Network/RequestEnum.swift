//
//  ApiURL.swift
//  OpenMarket
//
//  Created by 박태현 on 2021/08/16.
//

import Foundation

enum APIMethod: CaseIterable {
    case get
    case post
    case patch
    case delete
    
    var method: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        }
    }
}

enum APIURL: CustomStringConvertible {
    case getItems
    case getItem
    case post
    case patch
    case delete
    
    private static let baseUrl = "https://camp-open-market-2.herokuapp.com/"
    
    var description: String {
        switch self {
        case .getItems:
            return  Self.baseUrl + "items/"
        case .post, .getItem, .patch, .delete:
            return Self.baseUrl + "item/"
        }
    }
}

enum ContentType: CustomStringConvertible{
    case json
    case multipart
    
    var description: String {
        switch self {
        case .json:
            return "application/json"
        case .multipart:
            return "multipart/form-data; boundary="
        }
    }
}
