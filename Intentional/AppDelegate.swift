//
//  AppDelegate.swift
//  Intentional
//
//  Created by Craig Hockenberry on 7/19/23.
//

import UIKit

import WidgetKit
import Intents

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
		
		DispatchQueue.global(qos: .userInitiated).async {
			let context = INMediaUserContext()
			context.numberOfLibraryItems = 123
			
			context.subscriptionStatus = .notSubscribed
			
			context.becomeCurrent()
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

	func application(_ application: UIApplication, handle intent: INIntent, completionHandler: @escaping (INIntentResponse) -> Void) {
		if let playMediaIntent = intent as? INPlayMediaIntent {
			handlePlayMediaIntent(playMediaIntent, completion: completionHandler)
		}
		completionHandler(INPlayMediaIntentResponse(code: .failure, userActivity: nil))
	}

	func application(_ application: UIApplication, handlerFor intent: INIntent) -> Any? {
		if let mediaIntent = intent as? INPlayMediaIntent {
			debugLog("mediaSearch = \(String(describing: mediaIntent.mediaSearch))")
			return IntentHandler()
			//guard let mediaItem = mediaIntent.mediaItems?.first else { return nil }
			//guard let identifier = mediaItem.identifier else { return nil }
		}
		
		return nil
	}
	
	func handlePlayMediaIntent(_ intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
		// Extract the first media item from the intent's media items (these will have been resolved in the extension).
#if true
		let response = INPlayMediaIntentResponse(code: .success, userActivity: nil)
		completion(response)
#else
		if let mediaItem = intent.mediaItems?.first,
		   let identifier = mediaItem.identifier {
			
			debugLog("mediaItem.type = \(mediaItem.type), identifier = \(identifier)")
			
			let response = INPlayMediaIntentResponse(code: .success, userActivity: nil)
			completion(response)
		}
		else {
			let response = INPlayMediaIntentResponse(code: .failure, userActivity: nil)
			completion(response)
		}
#endif
	}
	
}

class IntentHandler: NSObject, INPlayMediaIntentHandling {
	
	func resolveMediaItems(for intent: INPlayMediaIntent, with completion: @escaping ([INPlayMediaMediaItemResolutionResult]) -> Void) {
		completion([INPlayMediaMediaItemResolutionResult.unsupported(forReason: .unsupportedMediaType)])
		
		debugLog("mediaSearch = \(String(describing: intent.mediaSearch))")

		/*
		(lldb) po intent.mediaSearch
		▿ Optional<INMediaSearch>
		  - some : <INMediaSearch: 0x600002618000> {
			reference = 0;
			mediaType = 0;
			sortOrder = 0;
			albumName = <null>;
			mediaName = XYZ;
			genreNames = (
			);
			artistName = <null>;
			moodNames = (
			);
			releaseDate = <null>;
			mediaIdentifier = <null>;
		}
		 */
		
		if let mediaSearch = intent.mediaSearch {
			let mediaItem = INMediaItem(identifier: "1234-abcd", title: mediaSearch.mediaName, type: .radioStation, artwork: nil)
			let mediaItems = [ mediaItem ]
			completion(INPlayMediaMediaItemResolutionResult.successes(with: mediaItems))
		}
		else {
			completion([INPlayMediaMediaItemResolutionResult.unsupported(forReason: .unsupportedMediaType)])
		}
//		resolveMediaItems(for: intent.mediaSearch) { optionalMediaItems in
//			guard let mediaItems = optionalMediaItems else {
//				completion([INPlayMediaMediaItemResolutionResult.unsupported()])
//				return
//			}
//			completion(INPlayMediaMediaItemResolutionResult.successes(with: mediaItems))
//		}
	}
	
	// The handler for INPlayMediaIntent returns the .handleInApp response code, so that the main app can be background
	// launched and begin playback. The extension is short-lived, and if playback was begun in the extension, it could
	// abruptly end when the extension is terminated by the system.
	func handle(intent: INPlayMediaIntent, completion: (INPlayMediaIntentResponse) -> Void) {
		debugLog("intent = \(String(describing: intent))")
		debugLog("mediaSearch = \(String(describing: intent.mediaSearch))")
		completion(INPlayMediaIntentResponse(code: .success, userActivity: nil))
	}
	
}

