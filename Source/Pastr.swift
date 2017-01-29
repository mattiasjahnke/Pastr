//
//  Pastr.swift
//  Pastr
//
//  Created by Mattias Jähnke on 2017-01-25.
//  Copyright © 2017 Mattias Jähnke. All rights reserved.
//


import Foundation

public enum PastrScope: Int {
    case `public`   = 0
    case unlisted   = 1
    case `private`  = 2
}

public enum PastrExpiration: String {
    case never      = "N"
    case tenMinutes = "10M"
    case oneHour    = "1H"
    case oneDay     = "1D"
    case oneWeek    = "1W"
    case twoWeeks   = "2W"
    case oneMonth   = "1M"
}

public enum PastrResult {
    case success(String)
    case failure(PastrError)
}

public struct Pastr {
    /// Your API key for Pastebin.com.
    /// For more information, see [http://pastebin.com/api](http://pastebin.com/api)
    static public var pastebinApiKey = ""
    
    /// For certain functionality, you need to login and retrieve a "user key"
    /// For more information, see [http://pastebin.com/api#8](http://pastebin.com/api#8)
    static public var pastebinUserKey: String?
}

// Functions
public extension Pastr {
    /// Submit a new Paste to Pastebin.com
    /// - parameter text: The content of the paste
    /// - parameter name: Name of the paste
    /// - parameter scope: Scope of the paste (default is unlisted)
    /// - parameter format: Syntax highlighting
    /// - parameter expiration: Expiration of the paste (default is never)
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the paste key or an error
    /// - note: For more information about the parameters, see http://pastebin.com/api
    static public func post(text: String, name: String? = nil, scope: PastrScope = .unlisted, format: String? = nil, expiration: PastrExpiration = .never, completion: @escaping (PastrResult) -> ()) {
        guard !(scope == .private && pastebinUserKey == nil) else { completion(.failure(.userKeyNotSet)); return }
        
        var params = ["api_option" : "paste",
                      "api_paste_code" : text,
                      "api_paste_private" : "\(scope.rawValue)",
            "api_paste_expire_date" : expiration.rawValue]
        
        name.map { params["api_paste_name"] = $0 }
        format.map { params["api_paste_format"] = $0 }
        
        URL(.post).execute(params) { result in
            switch result {
            case .failure: completion(result)
            case .success(let res):
                guard let key = res.components(separatedBy: "/").last else { completion(.failure(.unknown)); return }
                completion(.success(key))
            }
        }
    }
    
    /// Retrieve a Paste from Pastebin.com with a given key
    /// - parameter key: A unique string identifying the Paste
    /// - parameter isPrivate: If set to true, we'll try to fetch a private paste from the user
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the paste content or an error
    static public func get(paste key: String, isPrivate: Bool = false, completion: @escaping (PastrResult) -> ()) {
        guard !key.isEmpty else { completion(.failure(.pasteNotFound)); return }
        
        // If a user key is set, we'll use the API to retrieve the paste
        if isPrivate {
            guard pastebinUserKey != nil else { completion(.failure(.userKeyNotSet)); return }
            URL(.raw).execute(["api_option" : "show_paste", "api_paste_key" : key]) { completion($0) }
        } else {
            URL(string: "http://pastebin.com/raw/\(key)")?.execute { completion($0) }
        }
    }
    
    /// Delete a paste created by a user
    /// - parameter key: A unique string identifying the paste
    /// - note: Usage of this API requires a user key
    static public func delete(paste key: String, completion: @escaping (PastrResult) -> ()) {
        URL(.post).execute(["api_option" : "delete", "api_paste_key" : key]) { completion($0) }
    }
    
    /// Authenticate with pastebin and retrieve a user key (to be used for private scope pastes)
    /// - parameter username: A pastebin username
    /// - parameter password: A pastebin password
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the user key or an error
    static public func login(username: String, password: String, completion: @escaping (PastrResult) -> ()) {
        URL(.login).execute(["api_user_name" : username, "api_user_password" : password]) { completion($0) }
    }
    
    /// Retrieve pastes created by the authenticated user
    /// - parameter limit: How many pastes are to be retrieved. Default is 50
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the list of pastes in raw xml or an error
    /// - note: Usage of this API requires a user key
    /// TODO: This will just return unparsed XML in a string for now
    static public func getUserPastes(limit: Int? = nil, completion: @escaping (PastrResult) -> ()) {
        var params = ["api_option" : "list"]
        limit.map { params["api_results_limit"] = "\($0)" }
        URL(.post).execute(params) { completion($0) }
    }
    
    /// Retrieve the 18 currently trending pastes on pastebin
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the list of pastes in raw xml or an error
    /// TODO: This will just return unparsed XML in a string for now
    static public func getTrendingPastes(completion: @escaping (PastrResult) -> ()) {
        URL(.post).execute(["api_option" : "trends"]) { completion($0) }
    }
    
    /// Retrieves information about the user currently authenticated with the user key
    /// - note: Usage of this API requires a user key
    /// TODO: This will just return unparsed XML in a string for now
    static public func getUserInfo(completion: @escaping (PastrResult) -> ()) {
        URL(.post).execute(["api_option" : "userdetails"]) { completion($0) }
    }
}

private enum PastebinEndpoint: String {
    case post = "api_post"
    case login = "api_login"
    case raw = "api_raw"
}

private extension URL {
    
    init(_ endpoint: PastebinEndpoint) {
        self.init(string: "http://pastebin.com/api/\(endpoint.rawValue).php")!
    }
    
    func execute(_ payload: [String : String]? = nil, _ completion: @escaping (PastrResult) -> ()) {
        guard !Pastr.pastebinApiKey.isEmpty else { completion(.failure(.missingApiKey)); return }
        
        var params = payload ?? [:]
        
        params["api_dev_key"] = Pastr.pastebinApiKey
        Pastr.pastebinUserKey.map { params["api_user_key"] = $0 }
        
        guard let data = params.map({ $0.key + "=" + $0.value }).joined(separator: "&").data(using: .utf8) else {
            completion(.failure(.unknown))
            return
        }
        
        var urlRequest = URLRequest(url: self, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
        urlRequest.httpBody = data
        urlRequest.httpMethod = data.count > 0 ? "POST" : "GET"
        
        URLSession(configuration: .ephemeral).dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.httpError(error)))
                    return
                }
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else { completion(.failure(.unknown)); return }
                
                // Check for errors returned as raw text
                if let error = PastrError(pastebinResponse: responseString) { completion(.failure(error)); return }
                
                completion(.success(responseString))
            }
        }.resume()
    }
}

public enum PastrError: Error, LocalizedError {
    case badRequest(message: String)
    case blockedBySpamFilter
    case limitReached(message: String)
    case missingApiKey
    case emptyPaste
    case userKeyNotSet
    case pasteNotFound
    case httpError(Error)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .badRequest(let message): return message
        case .blockedBySpamFilter: return "Blocked by spam filter"
        case .limitReached(let message): return "Limit reached: \(message)"
        case .missingApiKey: return "Missing Pastebin API-key"
        case .emptyPaste: return "Empty paste"
        case .userKeyNotSet: return "Private paste couldn't be created because user key is not set"
        case .pasteNotFound: return "Paste not found"
        case .httpError(let error): return "HTTP error: \(error.localizedDescription)"
        case .unknown: return "An unknown error occurred"
        }
    }
}

private extension PastrError {
    // Since Pastebin.com responds with these error with http code 200 and, we have to try to serialize them like this.
    // This ofcourse mean that if you were to create a paste with content matching these rules, the get-function would return an error.
    init?(pastebinResponse message: String) {
        if message.hasPrefix("Bad API request") {
            self = .badRequest(message: message)
            return
        } else if message.contains("Your paste has triggered our automatic SPAM detection filter.") {
            self = .blockedBySpamFilter
            return
        } else if message.hasPrefix("Post limit") {
            self = .limitReached(message: message)
            return
        }
        
        return nil
    }
}
