//
//  TitleRowController.swift
//  WatchKitTestProject
//
//  Created by Rost on 02.03.17.
//  Copyright © 2017 Rost Gress. All rights reserved.
//

import WatchKit


class TitleRowController: NSObject {
    @IBOutlet var titleButton: WKInterfaceButton!
    
    var tag: Int?
    var delegate: TitleRowControllerDelegate?
    
    
    @IBAction func titleButtonTapped() {
        guard let tag = tag else {
            return
        }
        
        delegate?.tappedRowController(self, didSelectRow: tag)
    }
}

protocol TitleRowControllerDelegate: class {
    func tappedRowController(_: TitleRowController, didSelectRow tag: Int)
}
