//
//  ReportUtils.swift
//  QuotesTailored
//
//  Created by Limeng Ye on 2023/11/26.
//

import Foundation
import SwiftUI

class ReportUtils {
    public static let shared = ReportUtils()

    func sendRequest(key:String, value: String) {
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_udid"
        let payloadStr = "{\"" + key + "\": \"" + value + "\", " + "\"udid\": \"" + udid + "\"" + "}"
//        print("payloadStr = ", payloadStr)
        
        let urlStr = "https://ailisteners.com/v1"
        guard let url = URL(string: urlStr),
            let payload = payloadStr.data(using: .utf8) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer cf-Kl814QbGR7tn050enmJdT3BlbkFJH4VX9XwQ6V3HmZo6hUq4", forHTTPHeaderField: "Authorization") // cloudflare
        request.httpBody = payload

        URLSession.shared.dataTask(with: request) { (data, response, error) in
        }.resume()
    }
    
}
