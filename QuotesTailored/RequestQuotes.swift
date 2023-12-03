//
//  RequestQuotes.swift
//  QuotesTailored
//
//  Created by Limeng Ye on 2023/11/25.
//

import Foundation
import Combine
import SwiftUI
import os

let udkey_recList = "recList"

class RequestQuotes : ObservableObject {
    enum RequestStatus {
        case idle
        case requesting
        case newList
    }
    @Published var requestStatus = RequestStatus.idle

    public static let shared = RequestQuotes()
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "RequestQuotes")

    func requestQuotes() {
        print("[RequestQuotes] sending request")
        
//        localMock(); return
        
        let urlStr = "https://ailisteners.com/v1"
        let wishStr = UserDefaults(suiteName: appGroup)?.string(forKey: udkey_wish) ?? "I want to get motivated"
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_udid"
        let payloadStr = "{\"wishStr\": \"" + wishStr + "\", \"udid\": \"" + udid + "\"}"
        print("payloadStr = ", payloadStr)
        
        guard let url = URL(string: urlStr),
            let payload = payloadStr.data(using: .utf8) else { return }
 
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer cf-Kl814QbGR7tn050enmJdT3BlbkFJH4VX9XwQ6V3HmZo6hUq4", forHTTPHeaderField: "Authorization") // cloudflare
        request.httpBody = payload
        
        self.requestStatus = .requesting

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            print("[RequestQuotes] data received")
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Empty data"); return }
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            UserDefaults.standard.set(json, forKey: udkey_recList)
            DispatchQueue.main.async {
                self.requestStatus = .newList
            }
        }.resume()
    }
    
    func localMock() {
        let json = [
          ["quote": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"],
          ["quote": "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.", "author": "Steve Jobs"],
          ["quote": "The people who are crazy enough to think they can change the world are the ones who do.", "author": "Steve Jobs"]
        ]
        UserDefaults.standard.set(json, forKey: udkey_recList)
        self.requestStatus = .newList
    }
}
