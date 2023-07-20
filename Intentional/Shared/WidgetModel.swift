//
//  WidgetModel.swift
//  Intentional
//
//  Created by Craig Hockenberry on 7/19/23.
//

import Foundation

// NOTE: This model is used in both the app and widget.

class WidgetModel {
	
	struct WidgetDatum: Codable, Identifiable, CustomStringConvertible {
		let id: String
		var name: String
		
		var description: String {
			return "\(id): \(name)"
		}
	}
	
	private static let groupContainerId = "group.com.iconfactory.Intentional"
	
	// NOTE: The model's data can be used in many different contexts. A shared resource, such as a group container,
	// is needed to ensure that the model can be populated in all cases. The model will be populated from the app's
	// process, during a widget preview, or in system process that renders the widget for a home screen. There will
	// certainly be other situations in the future as AppIntent finds new use cases.
	//
	// If you use something other than UserDefaults, be aware that the container may not be shared in the same
	// location as you're testing. For example, a widget preview and an app installed in the Simulator use
	// different folders on disk. Previews use ~/Library/Developer/Xcode/UserData/Previews/Simulator Devices/ and
	// apps in the Simulator use ~/Library/Developer/CoreSimulator/Devices/.
	//
	// You will most likely fall into this situation when storing something like a JSON payload at
	// FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainerId). This is needed
	// when you need to store more than 4 MB of data in UserDefaults. This can easily happen if you
	// are storing multiple @3x images to be rendered in the widget. Pay attention if you add a large blob of data
	// to the WidgetDatum struct above.
	//
	// Note that you can use FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:) to see the
	// path being used for the widget preview (see .onAppear in Widget.swift).
	
	private static let sharedDefaults: UserDefaults = UserDefaults(suiteName: groupContainerId)!
	
	private static let countKey = "WidgetModel_count"
	private static let selectedIdKey = "WidgetModel_id"
	private static let widgetDataKey = "WidgetModel_widgetData"
	
	static func incrementCount() {
		var count = sharedDefaults.integer(forKey: countKey)
		count += 1
		debugLog("count = \(count)")
		sharedDefaults.set(count, forKey: countKey)
	}

	static func setCount(_ count: Int) {
		debugLog("count = \(count)")
		sharedDefaults.set(count, forKey: countKey)
	}

	static var currentCount: Int {
		let currentCount = sharedDefaults.integer(forKey: countKey)
		debugLog("currentCount = \(currentCount)")
		return currentCount
	}

	static var selectedId: String {
		get {
			let selectedId = sharedDefaults.string(forKey: selectedIdKey) ?? ""
			debugLog("got selectedId = \(selectedId)")
			return selectedId
		}
		set {
			debugLog("set selectedId = \(newValue)")
			sharedDefaults.set(newValue, forKey: selectedIdKey)
		}
	}
	
	static var widgetData: [WidgetDatum] {
		get {
			if let data = sharedDefaults.data(forKey: widgetDataKey) {
				if let widgetData = try? JSONDecoder().decode(Array<WidgetDatum>.self, from: data) {
					debugLog("got widgetData = \(widgetData)")
					return widgetData
				}
			}
			return []
		}
		set {
			if let data = try? JSONEncoder().encode(newValue) {
				debugLog("set data = \(data)")
				sharedDefaults.set(data, forKey: widgetDataKey)
			}
		}
	}

}
