//
//  AppDelegate.swift
//  Intentional
//
//  Created by Craig Hockenberry on 7/19/23.
//

import UIKit

import WidgetKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		debugLog()
		
		// NOTE: See the note in WidgetModel.swift about group containers issues for widget previews. There's
		// a reason this debug logging is here.
		let groupContainerId = "group.com.iconfactory.Intentional"
		if let groupContainerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainerId) {
			debugLog("groupContainerUrl = `\(groupContainerUrl.path(percentEncoded: false))`")
		}

		if WidgetModel.widgetData.isEmpty {
			let widgetData = [
				WidgetModel.WidgetDatum(id: "1", name: "A"),
				WidgetModel.WidgetDatum(id: "2", name: "BB"),
				WidgetModel.WidgetDatum(id: "3", name: "CCC"),
				WidgetModel.WidgetDatum(id: "4", name: "DDDD"),
			]
			WidgetModel.widgetData = widgetData
			WidgetCenter.shared.reloadAllTimelines()
		}
		
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

