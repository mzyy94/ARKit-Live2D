/**
 *
 * AppDelegate.swift
 * ARKit-Live2D
 * Created by Yuki MIZUNO on 2017/11/14.
 *
 * Copyright (c) 2017, Yuki MIZUNO
 * All rights reserved.
 *
 * See LICENSE for license information
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let defaults = UserDefaults.standard
        let isNotFirstRun = defaults.bool(forKey: FIRST_RUN)
        if !isNotFirstRun {
            defaults.set(true, forKey: FIRST_RUN)
            defaults.set(RED_COLOR_DEFAULT, forKey: RED_COLOR)
            defaults.set(GREEN_COLOR_DEFAULT, forKey: GREEN_COLOR)
            defaults.set(BLUE_COLOR_DEFAULT, forKey: BLUE_COLOR)
            defaults.set(ZOOM_DEFAULT, forKey: ZOOM)
            defaults.set(X_POS_DEFAULT, forKey: X_POS)
            defaults.set(Y_POS_DEFAULT, forKey: Y_POS)
        }
        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
