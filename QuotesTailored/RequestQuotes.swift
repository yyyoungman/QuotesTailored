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

let udkey_quotesList = "quotesList"

class RequestQuotes : ObservableObject {
 
    @Published var quotesUpdateCount = 0
    @Published var preparingQuotes = false
    
    public static let shared = RequestQuotes()
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "RequestQuotes")

    func getQuotes() {
        logger.log("getQuotes")
        
//        localMock(); return
        
        let urlStr = "https://ailisteners.com/v1"
        let wishStr = UserDefaults(suiteName: appGroup)?.string(forKey: "wish") ?? "I want to get motivated"
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_udid"
        let payloadStr = "{\"wishStr\": \"" + wishStr + "\", \"udid\": \"" + udid + "\"}"
        print("payloadStr = ", payloadStr)
        
        guard let url = URL(string: urlStr),
            let payload = payloadStr.data(using: .utf8) else { return }
 
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer cf-Kl814QbGR7tn050enmJdT3BlbkFJH4VX9XwQ6V3HmZo6hUq4", forHTTPHeaderField: "Authorization") // cloudflare
        request.httpBody = payload
        
        self.notifyMainView(json: [["quote": "Preparing quotes...", "author": ""]], preparing: true)

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Empty data"); return }
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            let dataString = String(data: data, encoding: .utf8)!
            print("dataString = ", dataString)
            self.notifyMainView(json: json, preparing: false)
        }.resume()
    }
    
    func notifyMainView(json:Any?, preparing:Bool) {
        DispatchQueue.main.async {
            self.quotesUpdateCount += 1
            UserDefaults.standard.set(json, forKey: udkey_quotesList)
            self.preparingQuotes = preparing
        }
    }
    
    func localMock() {
        let json = [
//          ["quote": "Stay hungry, stay foolish.", "author": "Steve Jobs"],
//          ["quote": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"],
//          ["quote": "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.", "author": "Steve Jobs"],
//          ["quote": "The people who are crazy enough to think they can change the world are the ones who do.", "author": "Steve Jobs"],
//          ["quote": "Remembering that you are going to die is the best way I know to avoid the trap of thinking you have something to lose.", "author": "Steve Jobs"],
//          ["quote": "Quality is more important than quantity. One home run is much better than two doubles.", "author": "Steve Jobs"],
//          ["quote": "The ones who are crazy enough to think they can change the world are the ones that do.", "author": "Steve Jobs"],
//          ["quote": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"],
          ["quote": "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.", "author": "Steve Jobs"],
          ["quote": "The people who are crazy enough to think they can change the world are the ones who do.", "author": "Steve Jobs"]
        ]
        notifyMainView(json:json, preparing: false)
    }
}
