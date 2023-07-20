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
	
	// NOTE: This prevents this AppIntent from appearing in Shortcuts and Spotlight. Since the widget
	// interaction uses an internal id that's not meaningful to the customer, this intent is hidden.
	static var isDiscoverable: Bool {
		return false
	}
	
	// NOTE: This @Parameter definition is unused, but is required initialize the stored properties of
	// the AppIntent's struct. The selectingId is set directly using the initializer below.
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
		
		#if !IS_WIDGETS_EXTENSION
		#endif
		
		return .result()
	}
	
}

// NOTE: The code below to add Shortcuts support for the model is work-in-progress.

// NOTE: A lot of ideas here were adapted from Booky: https://github.com/mralexhay/Booky

struct ShortcutsModelEntity: Identifiable, Hashable, Equatable, TransientAppEntity {
	init() {
	}
	
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Model")
	
	var id = UUID()
	
	@Property(title: "Count")
	var count: Int
	
	@Property(title: "Selected ID")
	var selectedId: String

	init(id: UUID, count: Int?, selectedId: String?) {
		self.id = id
		self.count = count ?? 0
		self.selectedId = selectedId ?? ""
	}
	
	var displayRepresentation: DisplayRepresentation {
		return DisplayRepresentation(
			title: "\(count) count",
			subtitle: "selected \(selectedId)"
		)
	}
}

extension ShortcutsModelEntity {
	
	// Hashable conformance
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	// Equtable conformance
	static func ==(lhs: ShortcutsModelEntity, rhs: ShortcutsModelEntity) -> Bool {
		return lhs.id == rhs.id
	}
	
}


struct UpdateModelIntent: AppIntent {
	
	// the name of the action in Shortcuts
	static var title: LocalizedStringResource = "Update Model"
	
	// description of the action in Shortcuts
	// category name allows you to group actions - shown when tapping on an app in the Shortcuts library
	static var description: IntentDescription = IntentDescription("Update the model.", categoryName: "Editing")
	
	@Parameter(title: "Count", description: "The model's count", default: 0, requestValueDialog: IntentDialog("What is the count?"))
	var count: Int
	
	@Parameter(title: "Selected ID", description: "The model's ID", requestValueDialog: IntentDialog("What is the selected ID?"))
	var selectedId: String
	
	// How the summary will appear in the shortcut action.
	// More parameters are included below the fold in the trailing closure. In Shortcuts, they are listed in the reverse order they are listed here
	static var parameterSummary: some ParameterSummary {
		Summary("Update \(\.$selectedId) with \(\.$count)")
	}

	//@MainActor // <-- include if the code needs to be run on the main thread
	func perform() async throws -> some ReturnsValue<ShortcutsModelEntity> {

		WidgetModel.setCount(count)
		WidgetModel.selectedId = selectedId
		let entity = ShortcutsModelEntity(id: UUID(), count: WidgetModel.currentCount, selectedId: WidgetModel.selectedId)

		return .result(value: entity)
	}
}

// NOTE: The following provider allows the AppIntent to show up in a Spotlight search.

struct IntentionalAppShortcutsProvider: AppShortcutsProvider {
	static var appShortcuts: [AppShortcut] {
		AppShortcut(
			intent: UpdateModelIntent(),
			phrases: [
				"Update a \(.applicationName) model"
			],
			shortTitle: "Update Model",
			systemImageName: "rectangle.and.pencil.and.ellipsis"
		)
	}
}
