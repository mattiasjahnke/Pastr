//
//  Pastr.swift
//  Pastr
//
//  Created by Mattias Jähnke on 2017-01-25.
//  Copyright © 2017 Mattias Jähnke. All rights reserved.
//


import Foundation

public enum PasteScope: Int {
    case asPublic   = 0
    case asUnlisted = 1
    case asPrivate  = 2
}

public enum PasteExpiry: String {
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
    
    public struct Paste {
        public var content: String
        public var name: String?
        public var scope: PasteScope
        public var pasteFormat: String?
        public var expire: PasteExpiry
        
        /// Create a `Paste`
        /// - parameter text: The content of the `Paste`
        /// - parameter name: Name of the `Paste` (Default is nil)
        /// - parameter scope: Scope of the `Paste` (Default is `unlisted`)
        /// - parameter pasteFormat: The format of the pasted content. (Default is nil. Read more: [http://pastebin.com/api#4](http://pastebin.com/api#4))
        /// - parameter expire: A TTL for the paste. (Default is `never`)
        public init(content: String, name: String? = nil, scope: PasteScope = .asUnlisted, pasteFormat: String? = nil, expire: PasteExpiry = .never) {
            self.content = content
            self.name = name
            self.scope = scope
            self.pasteFormat = pasteFormat
            self.expire = expire
        }
    }
    
    /// Submit a Paste to Pastebin.com
    /// - parameter paste: The `Paste` to submit
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the paste key or an error
    static public func post(paste: Paste, completion: @escaping (PastrResult) -> ()) {
        guard !(paste.scope == .asPrivate && pastebinUserKey == nil) else { completion(.failure(.userKeyNotSet)); return }
        
        // Required parameters
        var params = ["api_option" : "paste",
                      "api_paste_code" : paste.content,
                      "api_paste_private" : "\(paste.scope.rawValue)",
            "api_paste_expire_date" : paste.expire.rawValue]
        
        // Optional parameters
        paste.name.map { params["api_paste_name"] = $0 }
        paste.pasteFormat.map { params["api_paste_format"] = $0 }
        
        URL(string: "http://pastebin.com/api/api_post.php")!.execute(postParameters: params) { result in
            switch result {
            case .failure: completion(result)
            case .success(let res):
                guard let key = res.components(separatedBy: "/").last else { completion(.failure(.unknown)); return }
                completion(.success(key))
            }
        }
    }
    
    /// Retrieve a `Paste` from Pastebin.com with a given key
    /// - parameter pasteKey: A unique string identifying the `Paste`
    /// - parameter isPrivate: If set to true, we'll try to fetch a private paste from the user
    /// - parameter completion: A closure passing a `PastrResult` enum containing either the paste content or an error
    static public func get(paste key: String, isPrivate: Bool = false, completion: @escaping (PastrResult) -> ()) {
        guard !pastebinApiKey.isEmpty else { completion(.failure(.missingApiKey)); return }
        guard !key.isEmpty else { completion(.failure(.pasteNotFound)); return }
        
        // If a user key is set, we'll use the API to retrieve the paste
        if isPrivate {
            guard pastebinUserKey != nil else { completion(.failure(.userKeyNotSet)); return }
            // Required parameters
            let params = ["api_option" : "show_paste",
                          "api_paste_key" : key]
            URL(string: "http://pastebin.com/api/api_raw.php")!.execute(postParameters: params) { completion($0) }
        } else {
            URL(string: "http://pastebin.com/raw/\(key)")?.execute { completion($0) }
        }
    }
}

private extension URL {
    func execute(postParameters: [String : String], _ completion: @escaping (PastrResult) -> ()) {
        guard !Pastr.pastebinApiKey.isEmpty else { completion(.failure(.missingApiKey)); return }
        
        var params = postParameters
        
        params["api_dev_key"] = Pastr.pastebinApiKey
        Pastr.pastebinUserKey.map { params["api_user_key"] = $0 }
        
        guard let data = params.map({ $0.key + "=" + $0.value }).joined(separator: "&").data(using: .utf8) else {
            completion(.failure(.unknown))
            return
        }
        
        execute(data, completion)
    }
    
    func execute(_ data: Data? = nil, _ completion: @escaping (PastrResult) -> ()) {
        var urlRequest = URLRequest(url: self, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15)
        urlRequest.httpBody = data
        urlRequest.httpMethod = data.map { _ in "POST" } ?? "GET"
        
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
