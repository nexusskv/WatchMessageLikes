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


public enum MessageAction: Int {
    case add
    case edit
    case delete
}


class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputContainerViewBottom: NSLayoutConstraint!
    @IBOutlet weak var growingTextView: NextGrowingTextView!
    @IBOutlet var messagesTable: UITableView!
    var messagesArray: [Dictionary<String, AnyObject>] = []
    var selectedIndex: Int = -1
    let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    
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
    
    @IBAction func handleAddButton() {
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
        var messageValues = ["message": self.growingTextView.text as String] as [String : Any]
        
        var watchListAction: Int = MessageAction.add.rawValue
        
        var watchData: [String : Any] = [:]
        
        if self.selectedIndex >= 0 {
            let currentCount = self.messagesArray[self.selectedIndex]["count"] as! Int
            messageValues["count"] = currentCount
            
            self.messagesArray[self.selectedIndex] = messageValues as [String : AnyObject]
            watchListAction = MessageAction.edit.rawValue
            
            watchData["index"] = self.selectedIndex
            
        } else {
            messageValues["count"] = 0
            self.messagesArray.append(messageValues as [String : AnyObject])
        }

        watchData["message"] = self.growingTextView.text
        watchData["action"]  = watchListAction
        
        self.sendToWatch(data: watchData)
        
        self.inputContainerView.isHidden = true
        self.growingTextView.text = ""
        self.view.endEditing(true)
        
        self.messagesTable.reloadData()
        
        self.selectedIndex = -1
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
    
    func getMessage(index: Int) -> String {
        let messageParams = self.messagesArray[index]
        
        return (messageParams["message"] as! String?)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension ViewController: WCSessionDelegate {
    
    func sendToWatch(data: Dictionary<String, Any>) {
        // The paired iPhone has to be connected via Bluetooth.
        if let session = session, session.isReachable {
            session.sendMessage(data, replyHandler: nil, errorHandler: { error in
                // Handle any errors here
                print(error)
            });
        }
    }
    
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

        cell.messageLabel?.text = getMessage(index: indexPath.row)
        
        let count: Int = self.messagesArray[indexPath.row]["count"] as! Int
        cell.countLabel?.text = String(describing: count)
        
        return cell        
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedMessage = getMessage(index: indexPath.row)
        self.growingTextView.text = selectedMessage
        
        self.selectedIndex = indexPath.row
        
        handleAddButton()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.messagesArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .left)
            
            let watchData = ["action" : MessageAction.delete.rawValue,
                             "index" : indexPath.row] as [String : Any]
            self.sendToWatch(data: watchData)
            
            self.messagesTable.reloadData()
        }
    }
    
    private func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
