//
//  RecallView.swift
//  Auto Advisor
//
//  Created by Charles Clark on 3/22/23.
//
import SwiftUI

struct RecallView: View {
    var recallsData: [Recall]
    var vinData: [String]
    @State private var selectedRecall: Recall?
    @State private var myOdometer = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Spacer()
            Text("Your vehicle may have these recalls:")
            Spacer()
            List(recallsData) { recall in
                VStack(alignment: .leading) {
                    Text("Report Date: \(recall.reportDate)")
                    Text("Campaign Number: \(recall.campaignNumber)")
                    Text("Component: \(recall.component)")
                    Button(action: { self.selectedRecall = recall }) {
                        Text("...")
                    }
                    if selectedRecall == recall {
                        Text("Summary: \(recall.summary)")
                    }
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.vertical, 5)
            Spacer()
            Text("For updated recall status visit safercar.gov")
            Spacer()
            TextField("Enter current odometer", text: $myOdometer).multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }
}







