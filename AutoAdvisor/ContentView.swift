//
//  ContentView.swift
//  Auto Advisor
//
//  Created by Charles Clark on 3/17/23.
//

import SwiftUI
import Foundation


struct ContentView: View {
    
    @State private var myVin = ""
    @State private var vehicleModel = ""
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var recalls: [Recall] = []
    @State private var showText = false
    @State private var showNewPage = false
    @State private var isShowingScanner = false
    
    var body: some View {
        if showNewPage {
            RecallView(recallsData: recalls, vinData: [myVin, year, make, model])
        } else {
            VStack {
                Spacer()
                Text("Your Second Opinion First!")
                Spacer()
                Text("Your Vehicle:")
                TextField("Enter 17 digit VIN #", text: $myVin)
                    .multilineTextAlignment(.center)
                Button("Scan VIN") {
                    isShowingScanner = true
                }
                .sheet(isPresented: $isShowingScanner) {
                    VINScannerView(scannedVIN: $myVin, isShowingScanner: $isShowingScanner)
                }
                Button("Submit", action: {
                    fetchData(vin: myVin)
                })
                if showText {
                    Spacer()
                    Text("Is your vehicle a: \(vehicleModel)?")
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Yes", action: {
                            fetchRecalls(year: year, make: make, model: model)
                        })
                        Spacer()
                        Button("No", action: {
                            showText = false
                        })
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
    func fetchData(vin: String) {
        let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/\(vin)*BA?format=json")!
        
        let request = URLRequest(url: url)
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Something went wrong")
                return
            }
            
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let vehicleObject = jsonObject["Results"] as? [[String: Any]],
                   let year = vehicleObject[10]["Value"] as? String,
                   let make = vehicleObject[7]["Value"] as? String,
                   let trim = vehicleObject[13]["Value"] as? String,
                   let model = vehicleObject[9]["Value"] as? String {
                    DispatchQueue.main.async {
                        self.vehicleModel = "\(year) \(make) \(model) \(trim)"
                        self.year = year
                        self.make = make
                        self.model = model
                        self.showText = true
                    }
                }
                
            } catch {
                print("Error Serializing JSON")
            }
        }
        dataTask.resume()
    }

    func fetchRecalls(year: String, make: String, model: String) {
        let url = URL(string: "https://api.nhtsa.gov/recalls/recallsByVehicle?make=\(make)&model=\(model)&modelYear=\(year)")!

        let request = URLRequest(url: url)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Something went wrong")
                return
            }
            
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let results = jsonObject["results"] as? [[String: Any]] else {
                    print("Unable to parse results")
                    return
                }
                var recallsData: [Recall] = []
                for result in results {
                    guard let campaignNumber = result["NHTSACampaignNumber"] as? String,
                          let reportDate = result["ReportReceivedDate"] as? String,
                          let component = result["Component"] as? String,
                          let summary = result["Summary"] as? String else {
                              continue
                    }
                    recallsData.append(Recall(campaignNumber: campaignNumber, summary: summary, reportDate: reportDate, component: component))
                }
                DispatchQueue.main.async {
                    self.recalls = recallsData
                    showNewPage = true
                }
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
            }
        }
        dataTask.resume()
    }
}

extension VINScannerView.ScannerViewController {
    func found(code: String) {
        scannedVIN = code
        isShowingScanner = false
    }
}

struct Recall: Equatable, Identifiable {
    let id = UUID()
    let campaignNumber: String
    let summary: String
    let reportDate: String
    let component: String
    var isSummaryVisible: Bool = false
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
