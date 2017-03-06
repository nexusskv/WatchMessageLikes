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


public enum MessageAction: Int {
    case add
    case edit
    case delete
}


class InterfaceController: WKInterfaceController {
    @IBOutlet var titlesTable: WKInterfaceTable!
    let session : WCSession? = WCSession.isSupported() ? WCSession.default() : nil
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

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}


extension InterfaceController: TitleRowControllerDelegate {
    
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
}


extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        //Dispatch to main thread to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async {
            let actionValue: Int = message["action"] as! Int
            
            switch actionValue {
            case MessageAction.add.rawValue:
                if let titleValue = message["message"] as? String {
                    self.titlesArray.append(titleValue)
                }
                
            case MessageAction.edit.rawValue:
                if let titleValue = message["message"] as? String {
                    let selectedIndex = message["index"] as! Int
                    self.titlesArray[selectedIndex] = titleValue
                }
                
            case MessageAction.delete.rawValue:
                if let deleteIndex = message["index"] as? Int {
                    self.titlesArray.remove(at: deleteIndex)
                }
            default:
                break
            }
            
            self.loadData()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let receiedError = error {
            print(receiedError)
        }
    }
}
