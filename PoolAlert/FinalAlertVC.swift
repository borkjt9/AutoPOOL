//
//  finalAertVC.swift
//
//  Created by John Borkowski on 9/28/17.
//  Copyright © 2017 John Borkowski. All rights reserved.
//

import UIKit
import UserNotifications
import GooglePlaces
import GoogleMaps
import GooglePlacePicker
import LocalAuthentication
import Firebase
import FirebaseDatabase

class FinalAlertVC: UIViewController  {

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////VARIABLES START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var currentFareEstimate: String = ""
    var localCurrentlyPinging: Bool = false
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////IBOUTLETS START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var currentFare: UILabel!
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var currentFareSubtitle: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var requestedFareSubtitle: UILabel!
    
    @IBOutlet weak var requestedFare: UILabel!
    @IBOutlet weak var requestUberButton: UIButton!
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////IBACTIONS START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    @IBAction func backArrow(_ sender: Any) {
        
        systemInformation.alertSet = false
        systemInformation.stopTimer()
        self.removeToken()
        if self.presentingViewController?.presentedViewController == self {
            self.dismiss(animated: true, completion: nil)
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let yourVC = mainStoryboard.instantiateViewController(withIdentifier: "SubmitFareOrder") as! SubmitFareOrder
            appDelegate.window?.rootViewController = yourVC
            appDelegate.window?.makeKeyAndVisible()
            
        }

    }
    
    func refreshFare() {
        systemInformation.getPrices()
        systemInformation.startTimer(selectedVC: self, timerLength: 1.0, selectionFunction: "updateFareEstimate")
        systemInformation.addBlurEffect(self)
        self.view.bringSubview(toFront: activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        self.refreshFare()
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        systemInformation.alertSet = false
        systemInformation.startCoordinates = [nil, nil]
        systemInformation.endCoordinates = [nil, nil]
        systemInformation.stopTimer()
        self.removeToken()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let yourVC = mainStoryboard.instantiateViewController(withIdentifier: "LaunchVC") as! LaunchVC
        appDelegate.window?.rootViewController = yourVC
        appDelegate.window?.makeKeyAndVisible()

        
    }
    
    func removeToken() {
        if let token = Messaging.messaging().fcmToken {
            
            let dbRef = Database.database().reference()
            /*
            dbRef.child("fcmTokens").observeSingleEvent(of: .value, with: {(snapshot) in
                if snapshot.hasChild(token) {
                    dbRef.child("fcmTokens").child(token).removeValue()
                    
                }
            })
             */
            let freqArray = ["60", "120", "300", "600", "900"]
            for freq in freqArray {
                    dbRef.child("cron-jobs").child(freq).observeSingleEvent(of: .value, with: {(snapshot) in
                        if snapshot.hasChild(token) {
                            dbRef.child("cron-jobs").child(freq).child(token).removeValue()
                        }
                    })
            }
        }
    }

    @IBAction func requestUberButton(_ sender: Any) {
        self.removeToken()

        //let uberDeepLink: String = "https://m.uber.com/ul/?action=setPickup&client_id=L7vcTOvSNB8_omdxqHGO5CoJTddAQ9q3&product_id=ca1b6def-bf00-4a37-91ff-694d2e8dc0bd&pickup[latitude]=39.969813&pickup[longitude]=-75.132412&dropoff[latitude]=39.423822&dropoff[longitude]=-75.190880"
        let uberDeepLink: String = "https://m.uber.com/ul/?action=setPickup&client_id=L7vcTOvSNB8_omdxqHGO5CoJTddAQ9q3&product_id=ca1b6def-bf00-4a37-91ff-694d2e8dc0bd&pickup[formatted_address]=\(systemInformation.formattedStartAddress)&pickup[latitude]=\(systemInformation.startCoordinates[0]!)&pickup[longitude]=\(systemInformation.startCoordinates[1]!)&dropoff[formatted_address]=\(systemInformation.formattedEndAddress)&dropoff[latitude]=\(systemInformation.endCoordinates[0]!)&dropoff[longitude]=\(systemInformation.endCoordinates[1]!)"
        if UIApplication.shared.canOpenURL(URL(string: uberDeepLink)!) {
            UIApplication.shared.openURL(URL(string: uberDeepLink)!)
        } else {
            systemInformation.displayAlert(self, title: "Uber not installed", message: "You must install uber in order to use this AutoPool")
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////OVERRIDES START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.center = CGPoint(x: self.view.bounds.width/2.0, y: self.view.bounds.height/3.0)
        self.view.addSubview(activityIndicator)
        // Do any additional setup after loading the view.
        
        self.currentFare.text = systemInformation.fareEstimate
        
        //systemInformation.startTimer(selectedVC: self, timerLength: 1, selectionFunction: "pingServer")
        
        setViewFormats()

    }
    
    
    func setViewFormats() {
        self.currentFare.attributedText = addSpacing(text: systemInformation.fareEstimate, spacing: 1)
        let requestedFare = "$\(String(Int(systemInformation.requestedFare)))"
        self.requestedFare.attributedText = addSpacing(text: requestedFare, spacing: 1)

        self.currentFareSubtitle.attributedText = addSpacing(text: "CURRENT ESTIMATE", spacing: 1)
        self.requestedFareSubtitle.attributedText = addSpacing(text: "REQUESTED FARE", spacing: 1)

        self.titleLabel.attributedText = addSpacing(text: "ALL SET", spacing: 2.0)
        self.subtitleLabel.attributedText = addSpacing(text: self.subtitleLabel.text!, spacing: 0.5)
        
        self.requestUberButton.layer.cornerRadius = 10.0
        self.requestUberButton.setAttributedTitle(addSpacing(text: self.requestUberButton.titleLabel!.text!, spacing: 1.5), for: .normal)

        self.cancelButton.layer.cornerRadius = 10.0
        self.cancelButton.setAttributedTitle(addSpacing(text: self.cancelButton.titleLabel!.text!, spacing: 1.5), for: .normal)

    }

    override func viewDidAppear(_ animated: Bool) {
        self.currentFareEstimate = systemInformation.fareEstimate
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////DELEGATES START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////FUNCTIONS START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    
    func updateFareEstimate() {
        if !systemInformation.currentlyPinging {
            systemInformation.removeBlurEffect(self)
            systemInformation.stopTimer()
            self.activityIndicator.stopAnimating()
            if !systemInformation.enteredForeground {
                 systemInformation.displayAlert(self, title: "Current Fare Estimate ", message: "If you book now, your uberPool ride will cost \(systemInformation.fareEstimate).")
            } else {
                systemInformation.enteredForeground = false
            }
           
            self.currentFare.text = systemInformation.fareEstimate
            

        }

        
    }

    
    func addSpacing(text: String, spacing: Float) -> NSAttributedString {
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(spacing), range: NSRange(location: 0, length:(text.characters.count)))
        return attributedString
    }
}
