//
//  WidgetModel.swift
//  Intentional
//
//  Created by Craig Hockenberry on 7/19/23.
//

import Foundation
import AppIntents

// NOTE: This model, and the corresponding AppIntent, is used in both the app and widget.

class WidgetModel {
	
	struct WidgetDatum: Codable, Identifiable, CustomStringConvertible {
		let id: String
		let name: String
		
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

// NOTE: This is an example of an AppIntent without parameters.

struct WidgetCountIntent: AppIntent {
	
	static var title: LocalizedStringResource = "Increment counter"
	static var description = IntentDescription("Adds one to a counter in the model")

	func perform() async throws -> some IntentResult {
		WidgetModel.incrementCount()
		debugLog("currentCount = \(WidgetModel.currentCount)")
		return .result()
	}
	
}

// NOTE: This is an example of an AppIntent that uses a parameter, and was harder than expected.
//
// Thanks to Adam Overholtzer (@adam@iosdev.space), Michael Gorbach (@mgorbach@mastodon.social),
// and Luca Bernardi (@lucabernardi@mastodon.social) for the help in in figuring it out.

struct WidgetSelectIntent: AppIntent {
	
	static var title: LocalizedStringResource = "Select by ID"
	static var description = IntentDescription("Select an item in the model using its ID")
	
	// NOTE: This @Parameter definition is unused, but is required initialize the stored properties of
	// the AppIntent's struct. The selectingId is set directly using the initializer.
	@Parameter(title: "selectingId", description: "The ID to select")
	var selectingId: String
	
	init() {
	}
	
	init(selectingId: String) {
		debugLog("new selectingId = \(selectingId)")
		self.selectingId = selectingId
	}
	
	func perform() async throws -> some IntentResult {
		debugLog("selectingId = \(selectingId)")
		WidgetModel.selectedId = selectingId
		return .result()
	}
	
}
