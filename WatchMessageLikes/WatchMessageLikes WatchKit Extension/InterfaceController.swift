//
//  InterfaceController.swift
//  WatchKitTestProject WatchKit Extension
//
//  Created by Rost on 01.03.17.
//  Copyright © 2017 Rost Gress. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate, TitleRowControllerDelegate {
    @IBOutlet var titlesTable: WKInterfaceTable!
    private let session : WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    var titlesArray: [String] = []
    
        
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        
        loadData()
        
        session?.delegate = self
        session?.activate()
    }
    
    func loadData() {
        self.titlesTable.setNumberOfRows(titlesArray.count, withRowType: "TitleRow")
        
        for (index, title) in self.titlesArray.enumerated() {
            if let tableRow = self.titlesTable.rowController(at: index) as? TitleRowController {
                tableRow.titleButton?.setTitle(title)
                tableRow.delegate = self
                tableRow.tag = index
            }
        }

    }
    
    func tappedRowController(_: TitleRowController, didSelectRow tag: Int) {
        let applicationData = ["selectedIndex" : tag]
        
        // The paired iPhone has to be connected via Bluetooth.
        if let session = self.session, session.isReachable {
            session.sendMessage(applicationData, replyHandler: nil, errorHandler: { error in
                // Handle any errors here
                print(error)
            });
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        //Dispatch to main thread to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async {
            if let titleValue = message["message"] as? String {                
                self.titlesArray.append(titleValue)
                
                self.loadData()
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
