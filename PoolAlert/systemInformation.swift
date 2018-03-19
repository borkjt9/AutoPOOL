//
//  systemInformation.swift
//
//  Created by John Borkowski on 9/26/17.
//  Copyright © 2017 John Borkowski. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import GooglePlaces
import GoogleMaps
import GooglePlacePicker
import LocalAuthentication

open class SystemInformation{
    
    var initialAppLoad: Bool = true
    var timeCounter = 0
    var loadingTimer = Timer()
    var fareDict: [[String: Any]] = []
    var rideType: String = "POOL"
    var fareEstimate: String = "$14-17"
    var lowerEstimate: Double = 0
    var upperEstimate: Double = 0
    var startCoordinates: [Double?] = [nil, nil]
    var endCoordinates: [Double?] = [nil, nil]
    var formattedStartAddress: String = ""
    var formattedEndAddress: String = ""
    var currentlyPinging: Bool = false
    var updateFrequency: Int = 15
    var alertSet: Bool = false
    var fareEstimateSet: Bool = false
    var requestedFare: Double = 150
    var enteredForeground: Bool = false
    func startTimer(selectedVC: UIViewController, timerLength: Double, selectionFunction: String) {
        //default start timer function
        if !self.loadingTimer.isValid {
        self.timeCounter =  0
        self.loadingTimer = Timer.scheduledTimer(timeInterval: timerLength, target: selectedVC, selector: Selector(selectionFunction), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        self.timeCounter = 0
        systemInformation.currentlyPinging = false
        self.loadingTimer.invalidate()
    }
    
    func authenticateApp() {
        systemInformation.currentlyPinging = true
        let urlString: String = "https://login.uber.com/oauth/v2/authorize?client_id=L7vcTOvSNB8_omdxqHGO5CoJTddAQ9q3&response_type=code"
        let session: URLSession = URLSession.shared
        let url: URL = URL(string: urlString)!
        var urlRequest: URLRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
  
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        session.dataTask(with: urlRequest,
                         completionHandler: { (data:Data?,
                            response:URLResponse?,
                            error:Error?) -> Void in
                            systemInformation.currentlyPinging = false
                            if let responseData = data {
                                do {
                                    let json: NSDictionary = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                                    print("pinged json: \(json)")
                                    
                                }catch{
                                    print("pinged error: \(error)")
                                }
                            }
                            
        }).resume()
    }
    func getPrices() -> Void {
        systemInformation.currentlyPinging = true
        systemInformation.fareEstimate = ""
        let urlString: String = "https://api.uber.com/v1.2/estimates/price?start_latitude=\(startCoordinates[0]!)&start_longitude=\(startCoordinates[1]!)&end_latitude=\(endCoordinates[0]!)&end_longitude=\(endCoordinates[1]!)"
        let session: URLSession = URLSession.shared
        let url: URL = URL(string: urlString)!
        var urlRequest: URLRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        urlRequest.addValue("Token 2MMGqjjuts0HxF8u3n0Bk5VFFsAhS10zws_zcGgF", forHTTPHeaderField: "Authorization")
        
        urlRequest.addValue("en_US", forHTTPHeaderField: "Accept-Language")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        session.dataTask(with: urlRequest,
                         completionHandler: { (data:Data?,
                            response:URLResponse?,
                            error:Error?) -> Void in
                            systemInformation.currentlyPinging = false

                            if let responseData = data {
                                do {
                                    let json: NSDictionary = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                                    if (json["code"] as? String) != nil {
                                        let code = json["code"] as! String
                                        if code == "distance_exceeded" {
                                            self.fareEstimate = "Distance Exceeded"
                                        }
                                    } else {
                                        self.fareDict = json["prices"] as! [[String: Any]]
                                        (self.lowerEstimate, self.upperEstimate, self.fareEstimate) = self.findEstimate(pricesDict: self.fareDict)
                                        systemInformation.timeCounter = 0
                                        
                                    }
                                                                   }catch{
                                    
                                }
                            }
        }).resume()
    }
    
    func findEstimate(pricesDict: [[String: Any]]) -> (Double, Double, String) {
        var estimate: String = "Not Available"
        var lowerEstimate: Double = 0
        var upperEstimate: Double = 0
        for dict in pricesDict {
            if dict["display_name"] as! String == "uberPOOL" || dict["display_name"] as! String == "POOL" {
                estimate = dict["estimate"] as! String
                lowerEstimate = dict["low_estimate"] as! Double
                upperEstimate = dict["high_estimate"] as! Double
                return (lowerEstimate, upperEstimate, estimate)
            }
        }
        return (lowerEstimate, upperEstimate, estimate)
    }
    
    func sendAlert() {
        
        if self.requestedFare > self.lowerEstimate {
            let content = UNMutableNotificationContent()
            content.title = "Wild Fare Caught!"
            content.body = "Your requested fare is within the estimated price range for UberPOOL: \(systemInformation.fareEstimate)."
            content.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (1), repeats: false)
            let request = UNNotificationRequest(identifier: "textNotification", content: content, trigger: trigger)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().add(request) {(error) in
                if let error = error {
                    print("Uh oh! We had an error: \(error)")
                }
            }
           systemInformation.stopTimer()
            
        } else {
            let content = UNMutableNotificationContent()
            content.title = "Fare Alert"
            content.body = "Current UberPOOL Fare: \(systemInformation.fareEstimate)"
            content.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (1), repeats: false)
            let request = UNNotificationRequest(identifier: "textNotification", content: content, trigger: trigger)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().add(request) {(error) in
                if let error = error {
                    print("Uh oh! We had an error: \(error)")
                }
            }
 
        }
        
    }

    func displayAlert(_ selectedVC: UIViewController, title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        //the below is in case we ever want to customize the formatting of the uialert view. It sets the groundwork. For now we've decided to leave with apple system.
        let action: UIAlertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
        })
        //action.setValue(UIColor.white, forKey: "titleTextColor")
        alert.addAction(action)
        
        
        selectedVC.present(alert, animated: true, completion: nil)
    }
    
    
    func addBlurEffect(_ vc: UIViewController) {
        //blur gets added whenver a popover occurs.
        let darkView: UIView = UIView()
        darkView.tag = 99 //tag is set to a unique value is a reference point for what sub-view to remover when popover is dismissed
        darkView.frame = vc.view.bounds
        darkView.backgroundColor = UIColor.black
        darkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        darkView.alpha = 0.3 
        vc.view.addSubview(darkView)
    }
    
    func removeBlurEffect(_ vc: UIViewController) {
        //used to remove blue of both the above blur functions
        for subview in vc.view.subviews {
            if subview.tag == 99 {
                subview.removeFromSuperview()
            }
        }
        
        
    }
    
    
}
