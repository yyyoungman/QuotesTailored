//
//  MainView.swift
//  QuotesTailored
//
//  Created by Limeng Ye on 2023/11/25.
//

import SwiftUI
import os

let udkey_lastQuoteTimestamp = "lastQuoteTimestamp"
let udkey_curIdx = "curIdx"

struct MainView: View {
    @State private var showThoughts = false
    @State private var disableThoughtsCancel = false
    
//    @State var now = Date()
//    let timer = Timer.publish(every: 8, on: .current, in: .common).autoconnect()
    
    @State var quoteText = "example quote"
    
    @ObservedObject var requestQuotes = RequestQuotes.shared
    
//    @State private var quotesList = ["initial quote"]
//    @State private var authorsList = ["initial author"]
    
    @State private var quotesList: [Dictionary<String, String>] = [["quote": "Loading quotes...", "author": ""]]
    @State private var curIdx = 0
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "mainview")

//    @State private var isLoading = false

    var body: some View {
        VStack {
            Spacer()
            Text("\(quotesList[curIdx]["quote"] ?? "Loading quotes...")")
                .foregroundColor(.white)
                .font(.largeTitle)
                .bold()
                .padding()
            Text("\(quotesList[curIdx]["author"] ?? "")")
                .foregroundColor(.white)
                .font(.title3)
                .bold()
            .onChange(of: requestQuotes.quotesUpdateCount) { newValue in
                readQuoteList(resetCurIdx: true)
            }
//            Text("\(now)")
//            Text("\(quoteText)")
//            .onReceive(timer,
//                       perform: {_ in
////                self.now = Date()
//                updateCurQuote()
//            })
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                updateCurQuote()
            }
//            Text(requestQuotes.quoteJson)
//            TabView {
//                Text("First")
//                Text("Second")
//                Text("Third")
//                Text("Fourth")
//            }
//            .tabViewStyle(.page(indexDisplayMode: .never))
            
            if (requestQuotes.preparingQuotes) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2.0, anchor: .center) // Makes the spinner larger
            }
            
            Spacer()
            Button(action: {
                showThoughts = true
                disableThoughtsCancel = false
            }) {
                Spacer()
                Label("Thoughts", systemImage: "square.and.pencil")
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.5))
                    )
                Spacer()
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheet(isPresented: $showThoughts) {
//                thoughts
                ThoughtsView(showModal: self.$showThoughts, disableCancel: self.$disableThoughtsCancel)
//                .presentationDetents([.fraction(0.1), .large])
            }
        }
        .background(
            Image("default_bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
        )
        .onAppear() {
            checkFirstStart()
            readQuoteList(resetCurIdx: false)
            updateCurQuote()
        }
    }
    
    func updateCurQuote() {
        ReportUtils.shared.sendRequest(key: "enteredMainUI", value: "")
        let lastQuoteTimestamp = UserDefaults.standard.object(forKey: udkey_lastQuoteTimestamp) as? Date ?? Date()
        print("lastQuoteTimestamp", lastQuoteTimestamp)
        let elaspedHours: Int = Calendar.current.component(.hour, from: lastQuoteTimestamp)
        var interval = 3
        let intervalStr = UserDefaults.standard.string(forKey: udkey_refresh)
        if intervalStr == "1 hour" {
            interval = 1
        } else if intervalStr == "3 hours" {
            interval = 3
        } else if intervalStr == "24 hours" {
            interval = 24
        }
        if elaspedHours > interval {
            if curIdx < quotesList.count - 1 {
                curIdx = (curIdx + 1) % quotesList.count
                UserDefaults.standard.set(curIdx, forKey: udkey_curIdx)
                logger.log("curIdx: \(curIdx)")
            } else {
                RequestQuotes.shared.getQuotes()
            }
        }

        UserDefaults.standard.set(Date(), forKey: udkey_lastQuoteTimestamp)
    }
    
    func readQuoteList(resetCurIdx: Bool) {
        print("readQuoteList")
        let json = UserDefaults.standard.object(forKey: udkey_quotesList)
        if let jsonArray = json as? [Dictionary<String, String>] {
//            for item in jsonArray {
//                guard let quoteText = item["quote"] else {continue}
//                guard let authorText = item["author"] else {continue}
//                quotesList.append(quoteText)
//                authorsList.append(authorText)
//            }
            quotesList = jsonArray
        }
        if resetCurIdx {
            curIdx = 0
            UserDefaults.standard.set(Date(), forKey: udkey_lastQuoteTimestamp)
        } else {
            curIdx = UserDefaults.standard.integer(forKey: udkey_curIdx)
        }
        logger.log("reading curIdx: \(curIdx)")
    }
    
    
    func checkFirstStart() {
        // check user defaults
        let wishStr = UserDefaults(suiteName: appGroup)?.string(forKey: "wish") ?? ""
        if wishStr.isEmpty {
            showThoughts = true
            disableThoughtsCancel = true
            ReportUtils.shared.sendRequest(key: "firstStart", value: "")
        }
    }
}

#Preview {
    MainView()
}
