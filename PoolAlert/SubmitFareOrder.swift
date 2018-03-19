//
//  SubmitFareOrder.swift
//
//  Created by John Borkowski on 9/27/17.
//  Copyright © 2017 John Borkowski. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class SubmitFareOrder: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    let frequencyOptions = ["Every 1 minute", "Every 2 minutes", "Every 5 minutes", "Every 10 minutes", "Every 15 minutes"]
    let frequencyValues = [60, 120, 300, 600, 900]
    var pickerView = UIPickerView()
    var requestedFare = ""
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var fareEstimate: UILabel!
    
    @IBOutlet weak var fareEstimateSubTitle: UILabel!
    
    @IBOutlet weak var payQuestion: UILabel!
    
    @IBOutlet weak var payAnswer: UITextField!
    
    @IBOutlet weak var notificationQuestion: UILabel!
    
    @IBOutlet weak var notificationAnswer: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func backArrow(_ sender: Any) {
        
        systemInformation.alertSet = false
        systemInformation.startCoordinates = [nil, nil]
        systemInformation.endCoordinates = [nil, nil]
        
        if self.presentingViewController?.presentedViewController == self {
           self.dismiss(animated: true, completion: nil)
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let yourVC = mainStoryboard.instantiateViewController(withIdentifier: "LaunchVC") as! LaunchVC
            appDelegate.window?.rootViewController = yourVC
            appDelegate.window?.makeKeyAndVisible()
        }

    }
    
    @IBAction func submitButton(_ sender: Any) {
        if self.payAnswer.text == "" {
            systemInformation.displayAlert(self, title: "Missing Fare", message: "Please add a preferred fare")
        } else if self.notificationAnswer.text == "" {
            systemInformation.displayAlert(self, title: "Missing Notification Frequency", message: "Please add a preferrence option for how often you would like to be notified for changes in fare")
        } else {
            systemInformation.alertSet = true
            systemInformation.requestedFare = Double(self.requestedFare)!
            if let token = Messaging.messaging().fcmToken {
                let dbRef = Database.database().reference()
                //dbRef.child("fcmTokens").child(token).setValue([token: token as AnyObject])
                let instance: [String: AnyObject] = [
                    "startLat": systemInformation.startCoordinates[0]! as AnyObject,
                    "startLong": systemInformation.startCoordinates[1]! as AnyObject,
                    "endLat": systemInformation.endCoordinates[0]! as AnyObject,
                    "endLong": systemInformation.endCoordinates[1]! as AnyObject,
                    "requestedFare": systemInformation.requestedFare as AnyObject,
                ]
                dbRef.child("cron-jobs").child(String(systemInformation.updateFrequency)).child(token).setValue(instance)
                self.performSegue(withIdentifier: "toFinalAlertVC", sender: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.payAnswer.delegate = self
        
        
        let labelArray: [UILabel] = [self.fareEstimate, self.fareEstimateSubTitle, self.payQuestion, self.notificationQuestion]
        for label in labelArray  {
            label.attributedText = self.addSpacing(text: label.text!, spacing: 1.0)
        }
        self.fareEstimate.text = systemInformation.fareEstimate
        formatTextField(txtField: payAnswer, placeholder: "Enter Fare")
        formatTextField(txtField: notificationAnswer, placeholder: "Select Frequency")
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        titleLabel.attributedText = addSpacing(text: titleLabel.text!, spacing: 2.0)
        self.submitButton.layer.cornerRadius = 10.0
        self.submitButton.titleLabel?.attributedText = addSpacing(text: self.submitButton.titleLabel!.text!, spacing: 1.5)
        // Do any additional setup after loading the view.
        self.notificationAnswer.inputView = pickerView
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return frequencyOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return frequencyOptions[row]
    }
    /*
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as! UILabel
        label.font = UIFont(name: "Microsoft Sans Serif", size: 16)
        
        label.attributedText = addSpacing(text: frequencyOptions[row], spacing: 1)
        return label
    }
    */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        notificationAnswer.text = frequencyOptions[row]
        systemInformation.updateFrequency = frequencyValues[row]
        self.notificationAnswer.resignFirstResponder()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":

            self.requestedFare += string
            textField.text = "$\(self.requestedFare)"
            break
        default:
            //used for delete function
            let array: Array = Array(string.characters)
            var currentStringArray: Array = Array("".characters)
            currentStringArray = Array(self.requestedFare.characters)
            if array.count == 0 && currentStringArray.count != 0 { //array.count == 0 ensures that the 'delete button was tapped. current string != 0 ensures that there are elements in the string to actually delete
                currentStringArray.removeLast()
                self.requestedFare = ""
                for character in currentStringArray {
                    self.requestedFare += String(character)
                }
            }
            if self.requestedFare.characters.count == 0 {
                textField.text = ""
            } else {
                textField.text = "$\(self.requestedFare)"
            }
        }
        return false

    }
    
    func addSpacing(text: String, spacing: Float) -> NSAttributedString {
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(spacing), range: NSRange(location: 0, length:(text.characters.count)))
        return attributedString
    }
    
    func formatTextField(txtField: UITextField, placeholder: String) -> Void {
    
        txtField.backgroundColor = UIColor.clear
        txtField.borderStyle = UITextBorderStyle.none
        txtField.layer.borderColor = UIColor.clear.cgColor
        
        let attributedPlaceholder: NSMutableAttributedString = NSMutableAttributedString(string: placeholder)
        attributedPlaceholder.addAttribute(NSKernAttributeName, value: CGFloat(1), range: NSRange(location: 0, length: placeholder.characters.count))
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: txtField.text!)
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(1), range: NSRange(location: 0, length: txtField.text!.characters.count))
        txtField.attributedText = attributedString
        txtField.tintColor = UIColor.black

    }
    

    func dismissKeyboard() {
        view.endEditing(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
