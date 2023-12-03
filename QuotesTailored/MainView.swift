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
    @State private var newThought = false
    
    @State private var showAddOwn = false
    
    @ObservedObject var requestQuotes = RequestQuotes.shared
    
    @State private var displayList: [Dictionary<String, String>] = [["quote": "Loading quotes...", "author": ""]]
    @State private var curIdx = 0
    @State private var displayQuote = "Loading quotes..."
    @State private var displayAuthor = ""
    enum DisplayStatus {
        case loading
        case showing
        case error
    }
    @State private var displayStatus = DisplayStatus.loading
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "mainview")

    var body: some View {
        VStack {
            Spacer()
            
            quotesView
            
            Spacer()
            
            menuView
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
            loadQuoteList(resetCurIdx: false)
            showNextQuote()
        }
    }
    
    var quotesView: some View {
        VStack {
            Text(displayQuote)
                .foregroundColor(.white)
                .font(.largeTitle)
                .bold()
                .padding()
            Text(displayAuthor)
                .foregroundColor(.white)
                .font(.title3)
                .bold()
                .onChange(of: requestQuotes.requestStatus) { newValue in
                    if requestQuotes.requestStatus == .newList {
                        // when new list ready, reload list. if display is loading, update display; if not, don't update
                        loadQuoteList(resetCurIdx: true)
                        requestQuotes.requestStatus = .idle
                    }
                }
                .onChange(of: newThought) { newValue in
                    if newThought {
                        // show loading screen
                        showNextQuote()
                        newThought = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // update quote
                    showNextQuote()
                }
            //            Text(requestQuotes.quoteJson)
            //            TabView {
            //                Text("First")
            //                Text("Second")
            //                Text("Third")
            //                Text("Fourth")
            //            }
            //            .tabViewStyle(.page(indexDisplayMode: .never))
            
            if (displayStatus == .loading) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2.0, anchor: .center) // Makes the spinner larger
            }
        }
    }
    
    var menuView: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
                    showAddOwn = true
                }) {
//                    Label("", systemImage: "plus.app")
                    Image(systemName: "plus.app")
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.5))
                        )
                    
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sheet(isPresented: $showAddOwn) {
                    AddOwnView(showModal: self.$showAddOwn)
                        .presentationDetents([.medium])
                }
            }
            
            HStack {
                Button(action: {
                    showThoughts = true
                    disableThoughtsCancel = false
                }) {
                    Label("Thoughts", systemImage: "square.and.pencil")
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.5))
                        )
                }
                .foregroundColor(.blue)
//                .frame(maxWidth: .infinity, alignment: .leading)
                .sheet(isPresented: $showThoughts) {
                    ThoughtsView(showModal: self.$showThoughts, disableCancel: self.$disableThoughtsCancel, newThought: self.$newThought)
//                        .presentationDetents([.fraction(0.1), .large])
                }
            }
        }
    }
    
    func showNextQuote() {
        print("[MainView] showNextQuote")
        ReportUtils.shared.sendRequest(key: "enteredMainUI", value: "")

        // if new batch is being prepared, show loading
        // if requestQuotes.preparingQuotes {
        if requestQuotes.requestStatus == .requesting {
            displayStatus = .loading
            displayQuote = "Preparing quotes..."
            displayAuthor = ""
            return
        }
        displayStatus = .showing

        // check time elasped since last display, if > interval, show next quote
        let lastQuoteTimestamp = UserDefaults.standard.object(forKey: udkey_lastQuoteTimestamp) as? Date ?? Date()
        print("[MainView] lastQuoteTimestamp", lastQuoteTimestamp)
        let elaspedHours: Int = Calendar.current.component(.hour, from: lastQuoteTimestamp)
        let interval = RefreshTime.getUserDefault().intValue
        if elaspedHours > interval {
            curIdx = (curIdx + 1) % displayList.count
            UserDefaults.standard.set(curIdx, forKey: udkey_curIdx)
            print("[MainView] curIdx: \(curIdx)")

            // if there is only one quote left, request next batch
            if curIdx >= displayList.count - 1 {
                RequestQuotes.shared.requestQuotes()
            }
        }

        displayQuote = displayList[curIdx]["quote"] ?? "Loading quotes..."
        displayAuthor = displayList[curIdx]["author"] ?? ""

        UserDefaults.standard.set(Date(), forKey: udkey_lastQuoteTimestamp)

        setNotification()

    }
    
    func loadQuoteList(resetCurIdx: Bool) {
        print("[MainView] loadQuoteList")
        let recList = UserDefaults.standard.object(forKey: udkey_recList) as? [Dictionary<String, String>] ?? []
        let ownList = UserDefaults.standard.object(forKey: udkey_ownList) as? [Dictionary<String, String>] ?? []
        
        // pick randmoized items from ownList, and concatenate with recList
        var ownListRand = ownList.shuffled()
        if ownListRand.count > 0 {
            let ownCap = min(ownListRand.count / 3, recList.count)
            if ownListRand.count > ownCap {
                ownListRand = Array(ownListRand[0..<ownCap])
            }
        }
        // make sure the first one is from recList, and then shuffle the rest
        displayList = []
        if recList.count > 0 {
            displayList = Array(recList[1...])
        }
        displayList += ownListRand
        displayList.shuffle()
        if recList.count > 0 {
            displayList = Array(recList[0...0]) + displayList
        }
        print(displayList)
        if displayList.count <= 0 {
            displayList = [["quote": "No quotes yet.\n Enter thoughts to start.", "author": ""]]
        }
        
        // if resetCurIdx {
        if displayStatus == .loading {
            curIdx = displayList.count - 1 // set to last, so it will be incremented to 0 later
            displayStatus = .showing
            showNextQuote()
        } else {
            curIdx = UserDefaults.standard.integer(forKey: udkey_curIdx)
            if curIdx >= displayList.count {
                curIdx = 0
            }
        }
        print("[MainView] reading curIdx: \(curIdx)")
    }
    
    
    func checkFirstStart() {
        // check user defaults
        let wishStr = UserDefaults(suiteName: appGroup)?.string(forKey: udkey_wish) ?? ""
        if wishStr.isEmpty {
            showThoughts = true
            disableThoughtsCancel = true
            ReportUtils.shared.sendRequest(key: "firstStart", value: "")
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            // if let error = error {
            //     // Handle the error here.
            // }
            // Enable or disable features based on the authorization.
        }
    }

    func setNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // schedule the notification to send every n hours, based on user setting
        // avoiding night time, i.e. 9am, 12pm, 3pm, 6pm, 9pm
        let interval = RefreshTime.getUserDefault().intValue
        var hour = 9
        while hour <= 21 {
            setSingleNotification(hour: hour)
            hour += interval
        }
    }

    func setSingleNotification(hour: Int) {
        print("[MainView] setSingleNotification, hour: \(hour)")

        let content = UNMutableNotificationContent()
        content.title = "Quotes Tailored"
        content.subtitle = "New quote is ready"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = hour
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

}

#Preview {
    MainView()
}
