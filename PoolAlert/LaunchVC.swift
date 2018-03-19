//
//  ViewController.swift
//
//  Created by John Borkowski on 9/26/17.
//  Copyright © 2017 John Borkowski. All rights reserved.
//

import UIKit
import UserNotifications
import GooglePlaces
import GoogleMaps
import GooglePlacePicker
import LocalAuthentication
import UserNotifications
import Firebase
import FirebaseDatabase

class LaunchVC: UIViewController , GMSAutocompleteViewControllerDelegate, CLLocationManagerDelegate {

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////VARIABLES START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    let locationManager = CLLocationManager()
    var currentLocationCoordinates: CLLocationCoordinate2D!
    var activeField: Int = 0
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var markers: [GMSMarker] = [GMSMarker(),GMSMarker() ]
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////IBOUTLETS START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    @IBOutlet weak var mapView: GMSMapView!

    
    @IBOutlet weak var destinationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var greenImage: UIImageView!
    
    @IBOutlet weak var redImage: UIImageView!
    @IBOutlet weak var submitButton: UIButton!
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////IBACTIONS START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    
    @IBAction func startButton(_ sender: Any) {
        self.activeField = 0
    
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self

        if locationManager.location != nil {
        let currentLocation = locationManager.location!.coordinate
        let startBounds: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: currentLocation.latitude - 5, longitude: currentLocation.longitude - 5)
        let endBounds: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: currentLocation.latitude + 5, longitude: currentLocation.longitude + 5)
        autocompleteController.autocompleteBounds = GMSCoordinateBounds(coordinate: startBounds, coordinate: endBounds)
        }
        present(autocompleteController, animated: true, completion: nil)

    }
    @IBAction func destinationButton(_ sender: Any) {
        self.activeField = 1
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self

        if locationManager.location != nil {
        let currentLocation = locationManager.location!.coordinate
        let startBounds: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: currentLocation.latitude - 5, longitude: currentLocation.longitude - 5)
        let endBounds: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: currentLocation.latitude + 5, longitude: currentLocation.longitude + 5)
        autocompleteController.autocompleteBounds = GMSCoordinateBounds(coordinate: startBounds, coordinate: endBounds)
        }
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    @IBAction func submitButton(_ sender: Any) {

        if startButton.titleLabel?.text! == "ENTER START" {
            systemInformation.displayAlert(self, title: "Missing Start", message: "Please enter a starting address")
        } else if startButton.titleLabel?.text! == "ENTER DESTINATION" {
            systemInformation.displayAlert(self, title: "Missing Destination", message: "Please enter a destination")
        } else if systemInformation.fareEstimate == "Distance Exceeded" {
            systemInformation.displayAlert(self, title: "Distance Exceeded", message: "The distance between your starting point and destination cannot exceed 100 miles.")

        } else if systemInformation.fareEstimate == "Not Available" {
            systemInformation.displayAlert(self, title: "UberPOOL Not Available", message: "UberPOOL is not available in the area that you requested.")
  
        } else if systemInformation.fareEstimate == "" || systemInformation.currentlyPinging {
            systemInformation.addBlurEffect(self)
            self.view.bringSubview(toFront: activityIndicator)
            self.activityIndicator.startAnimating()
            systemInformation.getPrices()
            systemInformation.startTimer(selectedVC: self, timerLength: 1, selectionFunction: "checkForFareEstimate")
        } else {
            self.performSegue(withIdentifier: "toFareLimitVC", sender: self)

        }
        
    }
    
    @IBAction func unwindToVC(_ segue: UIStoryboardSegue) {
        //this is the "Log out segue", which logs user out of aws and brings back to the launch screen.
        //cancels the user session once a user logs out
        systemInformation.alertSet = false
        systemInformation.fareEstimateSet = false
        systemInformation.stopTimer()
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////OVERRIDES START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    func addSpacing(text: String, spacing: Float) -> NSAttributedString {
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(spacing), range: NSRange(location: 0, length:(text.characters.count)))
        return attributedString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        redImage.isHidden = true
        greenImage.isHidden = true
        
        self.activityIndicator.center = CGPoint(x: self.view.bounds.width/2.0, y: self.view.bounds.height/3.0)
        self.view.addSubview(activityIndicator)

        setViewFormats()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if systemInformation.initialAppLoad {
            systemInformation.initialAppLoad = false
            if let token = Messaging.messaging().fcmToken {
                Auth.auth().signInAnonymously { (user, error) in
                    if error != nil {
                        print("error: \(String(describing: error?.localizedDescription))")
                    } else {
                        let dbRef = Database.database().reference()
                        let freqArray = ["60", "120", "300", "600", "900"]
                        for freq in freqArray {
                            dbRef.child("cron-jobs").child(freq).observeSingleEvent(of: .value, with: {(snapshot) in
                                if snapshot.hasChild(token) {
                                    systemInformation.alertSet = true
                                    systemInformation.fareEstimateSet = true
                                    let tokenData = (snapshot.value as! NSDictionary)[token] as! NSDictionary//
                                    systemInformation.startCoordinates = [tokenData["startLat"] as! Double, tokenData["startLong"] as! Double]
                                    systemInformation.endCoordinates = [tokenData["endLat"] as! Double, tokenData["endLong"] as! Double]
                                    systemInformation.addBlurEffect(self)
                                    self.view.bringSubview(toFront: self.activityIndicator)
                                    self.activityIndicator.startAnimating()
                                    systemInformation.getPrices()
                                    systemInformation.startTimer(selectedVC: self, timerLength: 1, selectionFunction: "checkForFareEstimate")
                                }
                            })
                            
                        }
                    }
                }
            }
        }


    }

    override func viewDidAppear(_ animated: Bool) {
        // For use in foreground
        print("view did appear")
        // check token
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            self.currentLocationCoordinates = locationManager.location?.coordinate
            let camera = GMSCameraPosition.camera(withLatitude: self.currentLocationCoordinates.latitude, longitude: self.currentLocationCoordinates.longitude, zoom: 14)
            
            self.mapView.camera = camera// = GMSMapView.map(withFrame: self.mapView.frame, camera: camera)

        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////DELEGATES START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    
    // Handle the user's selection.
    
    
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        if self.activeField == 0 {
            self.startButton.titleLabel?.text = place.name
            
            var toArray = place.name.components(separatedBy: " ")
            let backToString = toArray.joined(separator: "%20")
            toArray = backToString.components(separatedBy: ",")
            systemInformation.formattedStartAddress = toArray.joined(separator: "%2C")
            self.startButton.setAttributedTitle(addSpacing(text: place.name, spacing: 1), for: .normal)
            systemInformation.startCoordinates = [Double(place.coordinate.latitude), Double(place.coordinate.longitude)]
            
        } else {
            self.destinationButton.titleLabel?.text = place.name
            var toArray = place.name.components(separatedBy: " ")
            let backToString = toArray.joined(separator: "%20")
            toArray = backToString.components(separatedBy: ",")
            systemInformation.formattedEndAddress = toArray.joined(separator: "%2C")
            self.destinationButton.setAttributedTitle(addSpacing(text: place.name, spacing: 1.5), for: .normal)
            systemInformation.endCoordinates = [Double(place.coordinate.latitude), Double(place.coordinate.longitude)]
        }
        
        self.setMapView(startLat: systemInformation.startCoordinates[0], startLong: systemInformation.startCoordinates[1], endLat: systemInformation.endCoordinates[0], endLong: systemInformation.endCoordinates[1])
        dismiss(animated: true, completion: nil)
        
        if self.startButton.titleLabel!.text! != "ENTER START" && self.destinationButton.titleLabel!.text! != "ENTER DESTINATION" {
            
            systemInformation.getPrices()
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    

    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////FUNCTIONS START//////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    
    func setMapView(startLat: Double?, startLong: Double?, endLat: Double?, endLong: Double?) {
        let path = GMSMutablePath()
        var camera = GMSCameraPosition()
        self.mapView.clear()
        if endLong != nil && startLong != nil {
            redImage.isHidden = false
            greenImage.isHidden = false
            
            let array = [["lat": startLat!, "long": startLong!],["lat": endLat!, "long": endLong!]]
            for i in 0 ..< array.count //Here take your "array" which contains lat and long.
            {
                markers[i].position = CLLocationCoordinate2DMake(array[i]["lat"]!,array[i]["long"]!)
                path.add(markers[i].position)
                markers[i].map = self.mapView
            }
            let bounds = GMSCoordinateBounds(path: path)
            
            self.mapView.moveCamera(GMSCameraUpdate.fit(bounds, with: UIEdgeInsetsMake(225, 50, 125, 50)))
            
        } else if endLong == nil && startLong != nil{
            redImage.isHidden = true
            greenImage.isHidden = false
            markers[0].position = CLLocationCoordinate2DMake(startLat!,startLong!)
            
            markers[0].map = self.mapView
            
            camera = GMSCameraPosition.camera(withLatitude: startLat!, longitude: startLong!, zoom: 14)
            self.mapView.camera = camera
            
        } else if endLong != nil && startLong == nil {
            redImage.isHidden = false
            greenImage.isHidden = true
            markers[1].position = CLLocationCoordinate2DMake(endLat!,endLong!)
            markers[1].map = self.mapView
            camera = GMSCameraPosition.camera(withLatitude: endLat!, longitude: endLong!, zoom: 14)
            self.mapView.camera = camera
            
        } else {
            redImage.isHidden = true
            greenImage.isHidden = true
        }
        
    }

    func setViewFormats() {
        markers[0].icon = #imageLiteral(resourceName: "maps_pin_green")
        markers[1].icon = #imageLiteral(resourceName: "maps_pin_red")
        
        self.startButton.layer.shadowColor = UIColor.gray.cgColor
        self.startButton.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        self.startButton.layer.masksToBounds = false
        self.startButton.layer.shadowOpacity = 1
        self.startButton.setAttributedTitle(addSpacing(text: self.startButton.titleLabel!.text!, spacing: 1.5), for: .normal)
        self.startButton.setTitleColor(UIColor.black, for: .normal  )
        self.destinationButton.layer.shadowColor = UIColor.gray.cgColor
        self.destinationButton.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        self.destinationButton.layer.masksToBounds = false
        self.destinationButton.layer.shadowOpacity = 1
        self.destinationButton.setAttributedTitle(addSpacing(text: self.destinationButton.titleLabel!.text!, spacing: 1.5), for: .normal)
        self.destinationButton.setTitleColor(UIColor.black, for: .normal)
        
        self.submitButton.layer.cornerRadius = 10.0
        self.submitButton.layer.shadowColor = UIColor.gray.cgColor
        self.submitButton.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        self.submitButton.layer.masksToBounds = false
        self.submitButton.layer.shadowOpacity = 1
        self.submitButton.setAttributedTitle(addSpacing(text: self.submitButton.titleLabel!.text!, spacing: 1.5), for: .normal)
        self.submitButton.setTitleColor(UIColor.white, for: .normal)
        
        
    }
    
    func requestPermissions() {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
    }
    
    func checkForFareEstimate() {
        systemInformation.timeCounter += 1
        if systemInformation.fareEstimate != "" {
            
            if systemInformation.fareEstimate == "Not Available" {
                systemInformation.removeBlurEffect(self)
                systemInformation.stopTimer()
                self.activityIndicator.stopAnimating()
                systemInformation.displayAlert(self, title: "UberPOOL Not Available", message: "UberPOOL is not available in the area that you requested.")
            } else if systemInformation.fareEstimate == "Distance Exceeded" {
                systemInformation.removeBlurEffect(self)
                systemInformation.stopTimer()
                self.activityIndicator.stopAnimating()
                systemInformation.displayAlert(self, title: "Distance Exceeded", message: "The distance between your starting point and destination cannot exceed 100 miles.")
            } else {
                systemInformation.removeBlurEffect(self)
                systemInformation.stopTimer()
                self.activityIndicator.stopAnimating()
                if systemInformation.alertSet {
                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let yourVC = mainStoryboard.instantiateViewController(withIdentifier: "FinalAlertVC") as! FinalAlertVC
                    self.present(yourVC, animated: true, completion: nil)
                    
                } else {
                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

                    let yourVC = mainStoryboard.instantiateViewController(withIdentifier: "SubmitFareOrder") as! SubmitFareOrder
                    //self.present(yourVC, animated: true, completion: nil)
                    self.performSegue(withIdentifier: "toFareLimitVC", sender: self)
                    
                }
            }
            
        }
    }
    func dismissViewPicker() {
        view.endEditing(true)

    }

}

