//
//  AppDelegate.swift
//
//  Created by John Borkowski on 9/26/17.
//  Copyright © 2017 John Borkowski. All rights reserved.
//

import UIKit
import UserNotifications
import GooglePlaces
import GooglePlacePicker
import GoogleMaps
import LocalAuthentication
import Firebase
import FirebaseDatabase
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"

    let locationManager = CLLocationManager()

    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        

        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        //application.registerUserNotificationSettings(UserNotifications(forTypes: [.Sound, .Alert, .Badge], categories: nil))
        

        
        
        GMSPlacesClient.provideAPIKey("AIzaSyBnXrxvT-suE1kA2hRbAQ9xGBU438SfW6Y")
        GMSServices.provideAPIKey("AIzaSyDUpC0kCRjXET4jfpuXWau683nDDxm29-8")
        
        
        print("did finish launching")
        print(Messaging.messaging().fcmToken)
        
        return true
    }
    
    func signIn(token: String) {
 

    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("entered background")
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if "FinalAlertVC" == UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.restorationIdentifier {
            let yourVC = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController! as! FinalAlertVC
            yourVC.refreshFare()
            print("there are the same")
            systemInformation.enteredForeground = true
        }
        print("Loadingdian" )
        //if systemInformation.alertSet {
          //  systemInformation.getPrices()
        //}
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // ----------------------------------------
    // MARK: - Apple Notification Delegates
    // ----------------------------------------
    
    
    
   
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        ///Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)

        print(deviceToken.hexEncodedString())
        print("registering here")
        if let token = Messaging.messaging().fcmToken {
            print ("token: \(token)")
        }
        locationManager.requestWhenInUseAuthorization()

    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    // The callback to handle data message received via FCM for devices running iOS 10 or above.
    func application(received remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Refreshed Firebase registration token: \(fcmToken)")
        let token: String =  Messaging.messaging().fcmToken!
        print(token)
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

}


extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
