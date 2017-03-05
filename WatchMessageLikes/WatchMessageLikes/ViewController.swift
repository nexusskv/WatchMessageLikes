//
//  ViewController.swift
//  WatchKitTestProject
//
//  Created by Rost on 01.03.17.
//  Copyright © 2017 Rost Gress. All rights reserved.
//

import UIKit
import WatchConnectivity
import NextGrowingTextView


class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputContainerViewBottom: NSLayoutConstraint!
    @IBOutlet weak var growingTextView: NextGrowingTextView!
    @IBOutlet var messagesTable: UITableView!
    var messagesArray: [Dictionary<String, AnyObject>] = []
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureWCSession()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        configureWCSession()
    }
    
    private func configureWCSession() {
        session?.delegate = self;
        session?.activate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.inputContainerView.isHidden = true
        
        self.growingTextView.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func handleAddButton(_ sender: AnyObject) {
        self.inputContainerView.isHidden = false
        
        _ = self.growingTextView.becomeFirstResponder()
        
        self.growingTextView.layer.cornerRadius = 4
        self.growingTextView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        self.growingTextView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 4, right: 0)
        self.growingTextView.placeholderAttributedText = NSAttributedString(string: "Please write a message",
                                                                            attributes: [NSFontAttributeName: self.growingTextView.font!,
                                                                                         NSForegroundColorAttributeName: UIColor.gray])
    }
    
    @IBAction func handleSendButton(_ sender: AnyObject) {
        let messageValues = ["message": self.growingTextView.text as String,
                             "count": 0 as Int] as [String : Any]
        
        self.messagesArray.append(messageValues as [String : AnyObject])
        
        let applicationData = ["message" : self.growingTextView.text]
        // The paired iPhone has to be connected via Bluetooth.
        if let session = session, session.isReachable {
            session.sendMessage(applicationData, replyHandler: nil, errorHandler: { error in
                // Handle any errors here
                print(error)
            });
        }
        
        self.inputContainerView.isHidden = true
        self.growingTextView.text = ""
        self.view.endEditing(true)
        
        self.messagesTable.reloadData()
    }
    
    func keyboardWillHide(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                //key point 0,
                self.inputContainerViewBottom.constant =  0
                //textViewBottomConstraint.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
            }
        }
    }
    
    func keyboardWillShow(_ sender: Notification) {
        if let userInfo = (sender as NSNotification).userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.inputContainerViewBottom.constant = keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension ViewController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        //Dispatch to main thread to update the UI instantaneously (otherwise, takes a little while)
        DispatchQueue.main.async {
            if let counterValue = message["selectedIndex"] as? Int {
                var messageParams = self.messagesArray[counterValue]
                
                var currentCount = messageParams["count"] as! Int
                currentCount += 1
                messageParams["count"] = currentCount as AnyObject?
                
                self.messagesArray[counterValue] = messageParams
                
                self.messagesTable.reloadData()
            }
        }
    }
    
    //Handlers in case the watch and phone watch connectivity session becomes disconnected
    func sessionDidDeactivate(_ session: WCSession) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MessageViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! MessageCell
        
        let messageParams = self.messagesArray[indexPath.row]

        cell.messageLabel?.text = messageParams["message"] as! String?
        
        let count: Int = messageParams["count"] as! Int
        cell.countLabel?.text = String(describing: count)
        
        return cell        
    }
}

