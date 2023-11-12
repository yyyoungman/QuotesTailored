//
//  ContentView.swift
//  QuotesTailored
//
//  Created by Yangming Chong on 2023/11/1.
//

import SwiftUI
import WidgetKit

let appGroup = "group.tonyc.QuotesTailored"

struct ContentView: View {
    
    enum RefreshTime: String, CaseIterable, Identifiable {
        case hour1 = "1 hour"
        case hour3 = "3 hours"
        case hour24 = "24 hours"
        var id: RefreshTime { self }
    }
    @State private var selectedTime: RefreshTime = .hour3
    
    @State private var wish: String = (UserDefaults(suiteName: appGroup)!.string(forKey: "wish") ?? "")
    
    @State private var showReminder = false
    
    @State private var showFeedback = false
    @State private var feedbackStr: String = ""

    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    Text("Hi! Quotes will be recommended based on your thoughts.")
                }
                .listRowBackground(Color(.systemGroupedBackground))
                Section(header: Text("What's on your mind?"), footer: Text("You can be specific, e.g. I'm stressed in my new job which I don't like. Or, I want to become a successful entrepreneur like Steve Jobs and Elon Musk. ")) {
                    HStack {
                        TextField("", text: $wish)
                            .submitLabel(.done)
                            .onSubmit {
                                UserDefaults(suiteName: appGroup)!.set(self.$wish.wrappedValue, forKey: "wish")
                                WidgetCenter.shared.reloadAllTimelines()
                                showReminder = true
                            }
                            .alert("To get daily quotes on your home screen:\n 1.Long press home screen.\n2.Tap '+' top left.\n3.Add our widget. Enjoy!", isPresented: $showReminder) {
                                Button("Got it", role: .cancel) { }
                            }
                    }
                }
                Section(header: Text("Widget settings")) {
                    Picker("Refresh time", selection: $selectedTime) {
                        ForEach(RefreshTime.allCases) { v in
                            Text(v.rawValue).tag(v)
                        }
                    }
                    .onChange(of:selectedTime) { value in
                        print("selectedTime set = ", selectedTime)
                        UserDefaults(suiteName: appGroup)!.set(selectedTime.rawValue, forKey: "refresh")
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                Section() {
                    HStack {
                        Spacer()
                        Button("Feedback", action: {
                            showFeedback = true
                        })
                        Spacer()
                    }
                }
                .listRowBackground(Color(.systemGroupedBackground))
                
            }
            .navigationTitle("Quotes")
            .onAppear {
                // set default values
                UserDefaults(suiteName: appGroup)!.set("e.g. I want to get motivated", forKey: "wish")
                UserDefaults(suiteName: appGroup)!.set("3 hours", forKey: "refresh")
                checkStatus()
            }
            .alert("Your feedback is appreciated", isPresented: $showFeedback, actions: {
                TextField("Feedback", text: $feedbackStr)
                
                Button("Send", action: {
                    sendFeedback(feedback:feedbackStr)
                })
                .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel, action: {})
            })
            .buttonStyle(.borderless)
        }
    }
    
    func sendRequest(key:String, value: String) {
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_udid"
        let payloadStr = "{\"" + key + "\": \"" + value + "\", " + "\"udid\": \"" + udid + "\"" + "}"
        print("payloadStr = ", payloadStr)
        
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
    
    func sendFeedback(feedback:String) {
        sendRequest(key: "feedback", value: feedback)
    }
    
    func checkStatus() {
        WidgetCenter.shared.getCurrentConfigurations { results in
            guard let widgets = try? results.get() else { return }
            var widgetStatus = ""
            for wid in widgets {
                widgetStatus += "\(wid.family)"
            }
            sendRequest(key: "widgetStatus", value: widgetStatus)
        }
    }
}

#Preview {
    ContentView()
}
