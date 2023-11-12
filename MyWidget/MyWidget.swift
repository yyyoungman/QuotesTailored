//
//  MyWidget.swift
//  MyWidget
//
//  Created by Yangming Chong on 2023/11/1.
//

import WidgetKit
import SwiftUI

let appGroup = "group.tonyc.QuotesTailored"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), quote: "Stay hungry, stay foolish.", author: "Steve Jobs", imageName: "default_bg")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), quote: "Stay hungry, stay foolish.", author: "Steve Jobs", imageName: "default_bg")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let urlStr = "https://ailisteners.com/v1"
        guard let wishStr = UserDefaults(suiteName: appGroup)!.string(forKey: "wish") else {return}
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_udid"
        let payloadStr = "{\"wishStr\": \"" + wishStr + "\", \"udid\": \"" + udid + "\"}"
        print("payloadStr = ", payloadStr)
        
        guard let url = URL(string: urlStr),
            let payload = payloadStr.data(using: .utf8) else { return }
 
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer cf-Kl814QbGR7tn050enmJdT3BlbkFJH4VX9XwQ6V3HmZo6hUq4", forHTTPHeaderField: "Authorization") // cloudflare
        request.httpBody = payload

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Empty data"); return }

            let str = String(data: data, encoding: .utf8) ?? "no data"
//            print(str)
            
//            var answer = "The journey of a thousand miles begins with one step. | LaoTzu\nStay hungry, stay foolish. | Steve Jobs"
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
//            if let dictionary = json as? [String: Any] {
//                if let choices = dictionary["choices"] as? [Any] {
//                    if let firstChoice = choices.first as? [String: Any] {
//                        if let message = firstChoice["message"] as? [String: Any] {
//                            if let content = message["content"] as? String {
////                                print(content)
//                                answer = content
//                            }
//                        }
//                    }
//                }
//            }
            
            var interval = 4
            var intervalUnit = Calendar.Component.hour
            guard let intervalStr = UserDefaults(suiteName: appGroup)!.string(forKey: "refresh") else {return}
//            print("[urlReq] intervalStr read = ", intervalStr)
            if intervalStr == "1 hour" {
                interval = 1
                intervalUnit = Calendar.Component.hour
            } else if intervalStr == "3 hours" {
                interval = 3
                intervalUnit = Calendar.Component.hour
            } else if intervalStr == "24 hours" {
                interval = 24
                intervalUnit = Calendar.Component.hour
            }
//            print("[urlReq] interval int = ", interval)
            
            var entries: [SimpleEntry] = []
            let currentDate = Date()
//            let myStrings = answer.components(separatedBy: .newlines)
//            let num_lines = myStrings.count//  - 1
            let imageName = "default_bg"
//            for i in 0 ..< num_lines {
//                let entryDate = Calendar.current.date(byAdding: intervalUnit, value: i*interval, to: currentDate)!
//                let line = myStrings[i].components(separatedBy: "|")
//                if line.count < 2 {
//                    continue
//                }
//                let quote_text = line[0]
//                let author_text = line[1]
//                let entry = SimpleEntry(date: entryDate, quote: quote_text, author: author_text, imageName: imageName)
//                entries.append(entry)
//            }
            var i = 0
            if let jsonArray = json as? [Dictionary<String, String>] {
                for item in jsonArray {
                    guard let quote_text = item["quote"] else {continue}
                    guard let author_text = item["author"] else {continue}
                    let entryDate = Calendar.current.date(byAdding: intervalUnit, value: i*interval, to: currentDate)!
                    let entry = SimpleEntry(date: entryDate, quote: quote_text, author: author_text, imageName: imageName)
                    entries.append(entry)
                    i += 1
                }
            }
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
            
        }.resume()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quote: String
    let author: String
    let imageName: String
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

struct MyWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            // Show view size
            Text(entry.quote)
                .font(.system(.headline, weight: .light))
                .bold()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
            
            // Show provider info
            Text(entry.author)
                .font(.system(.footnote))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(Image(entry.imageName)
            .resizable()
            .scaledToFill()
            .grayscale(0.99)
            .colorMultiply(.gray)
        )
    }
}

struct MyWidget: Widget {
    let kind: String = "MyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MyWidgetEntryView(entry: entry)
//            if #available(iOS 17.0, *) {
//                MyWidgetEntryView(entry: entry)
//                    .containerBackground(.fill.tertiary, for: .widget)
//            } else {
//                MyWidgetEntryView(entry: entry)
//                    .padding()
//                    .background()
//            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    MyWidget()
} timeline: {
    SimpleEntry(date: Date(), quote: "Stay hungry, stay foolish.", author: "Steve Jobs", imageName: "default_bg")
}
