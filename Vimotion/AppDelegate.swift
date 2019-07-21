//
//  AppDelegate.swift
//  Vimotion
//
//  Created by Elazar Yifrach on 19/07/2019.
//  Copyright © 2019 Elaz. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var flowController: AppFlowController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window?.makeKeyAndVisible()
        guard let rootController = window?.rootViewController else {
            fatalError("app started with no root view controller")
        }
        flowController = AppFlowController(presentingViewController: rootController)
        DispatchQueue.main.async {
            self.flowController?.start()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }


}
