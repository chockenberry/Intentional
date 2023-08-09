//
//  AppIntents.swift
//  Intentional
//
//  Created by Craig Hockenberry on 7/20/23.
//

import Foundation
import AppIntents
import WidgetKit

// NOTE: These AppIntents are used in both the app and widget.

// NOTE: This is an example of an AppIntent without parameters. The availability check is because the app can
// run on iOS 16, but the widget that uses this intent has a deployment target for iOS 17.

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
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

// ================================================================================================
// NOTE: The code below to add Shortcuts support for the model is work-in-progress.
// ================================================================================================

// NOTE: A lot of ideas here were adapted from these sources:
//
//		Booky: https://github.com/mralexhay/Booky
//		WWDC Video: https://developer.apple.com/videos/play/wwdc2022/10032

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
	
	// Equatable conformance
	static func ==(lhs: ShortcutsModelEntity, rhs: ShortcutsModelEntity) -> Bool {
		return lhs.id == rhs.id
	}
	
}

struct ShortcutsDatumEntity: Identifiable, Hashable, Equatable, AppEntity {
	
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Datum")
	
	typealias DefaultQueryType = ShortcutsDatumQuery
	static var defaultQuery = ShortcutsDatumQuery()

	@Property(title: "ID")
	var id: String
	
	@Property(title: "Name")
	var name: String

	init(id: String, name: String?) {
		self.id = id
		self.name = name ?? ""
	}
	
	var displayRepresentation: DisplayRepresentation {
		return DisplayRepresentation(
			title: "\(name)",
			subtitle: "ID \(id)"
		)
	}
	
}

extension ShortcutsDatumEntity {
	
	// Hashable conformance
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	// Equatable conformance
	static func ==(lhs: ShortcutsDatumEntity, rhs: ShortcutsDatumEntity) -> Bool {
		return lhs.id == rhs.id
	}
	
}

struct ShortcutsDatumQuery: EntityQuery {

	func entities(for identifiers: [ShortcutsDatumEntity.ID]) async throws -> [ShortcutsDatumEntity] {
		return identifiers.compactMap { identifier in
			
			for widgetDatum in WidgetModel.widgetData {
				if widgetDatum.id == identifier {
					return ShortcutsDatumEntity(id: widgetDatum.id, name: widgetDatum.name)
				}
			}
			
			return nil
		}
	}
	
}

extension ShortcutsDatumQuery: EntityStringQuery {
	
	func suggestedEntities() async throws -> [ShortcutsDatumEntity] {
		return WidgetModel.widgetData.map { widgetDatum in
			return ShortcutsDatumEntity(id: widgetDatum.id, name: widgetDatum.name)
		}
	}

	func entities(matching string: String) async throws -> [ShortcutsDatumEntity] {
		
		// Allows the user to filter the list of Books by title or author when tapping on a param that accepts a 'Book'
		let matchingData = WidgetModel.widgetData.filter { widgetDatum in
			return widgetDatum.name.localizedCaseInsensitiveContains(string)
		}

		return matchingData.map { widgetDatum in
			return ShortcutsDatumEntity(id: widgetDatum.id, name: widgetDatum.name)
		}
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
	
	@Parameter(title: "Selected ID", description: "The model's selected ID", requestValueDialog: IntentDialog("What is the selected ID?"))
	var selectedId: String
	
	// How the summary will appear in the shortcut action.
	// More parameters are included below the fold in the trailing closure. In Shortcuts, they are listed in the reverse order they are listed here
	static var parameterSummary: some ParameterSummary {
		Summary("Update model with \(\.$selectedId) and \(\.$count)")
	}

#if false // NOTE: The following code generates a weird "malformed JSON" compile error.
	//@MainActor // <-- include if the code needs to be run on the main thread
	func perform() async throws -> some ReturnsValue<ShortcutsModelEntity> {

		WidgetModel.setCount(count)
		WidgetModel.selectedId = selectedId
		let entity = ShortcutsModelEntity(id: UUID(), count: WidgetModel.currentCount, selectedId: WidgetModel.selectedId)

		return .result(value: entity)
	}
#else
	func perform() async throws -> some IntentResult {
		return .result()
	}
#endif
}

struct UpdateDatumIntent: AppIntent {

	// the name of the action in Shortcuts
	static var title: LocalizedStringResource = "Update Datum"
	
	// description of the action in Shortcuts
	// category name allows you to group actions - shown when tapping on an app in the Shortcuts library
	static var description: IntentDescription = IntentDescription("Update a datum.", categoryName: "Editing")
	
	@Parameter(title: "Datum", description: "The datum to update")
	var datum: ShortcutsDatumEntity
	
	@Parameter(title: "Name", description: "The name of the datum", requestValueDialog: IntentDialog("What is the name?"))
	var name: String
	
	// How the summary will appear in the shortcut action.
	// More parameters are included below the fold in the trailing closure. In Shortcuts, they are listed in the reverse order they are listed here
	static var parameterSummary: some ParameterSummary {
		Summary("Update datum \(\.$datum) with \(\.$name)")
	}

 #if false // NOTE: The following code generates a weird "malformed JSON" compile error.
	//@MainActor // <-- include if the code needs to be run on the main thread
	func perform() async throws -> some ReturnsValue<ShortcutsDatumEntity> {

		var widgetData = WidgetModel.widgetData
		let index = widgetData.firstIndex { widgetDatum in
			datum.id == widgetDatum.id
		}
		if let index {
			widgetData[index].name = name
			datum.name = name
		}
		WidgetModel.widgetData = widgetData
		return .result(value: datum)
	}
 #else
	 func perform() async throws -> some IntentResult {
		 return .result()
	 }
 #endif

}

struct IncrementCountIntent: AppIntent {
	
	// the name of the action in Shortcuts
	static var title: LocalizedStringResource = "Increment Count"
	
	// description of the action in Shortcuts
	// category name allows you to group actions - shown when tapping on an app in the Shortcuts library
	static var description: IntentDescription = IntentDescription("Increment the model's count.", categoryName: "Editing")
	
	// How the summary will appear in the shortcut action.
	// More parameters are included below the fold in the trailing closure. In Shortcuts, they are listed in the reverse order they are listed here
	static var parameterSummary: some ParameterSummary {
		Summary("Increment count")
	}

	func perform() async throws -> some IntentResult {
		WidgetModel.incrementCount()
		WidgetCenter.shared.reloadAllTimelines()
		
		// NOTE: Make sure that the WidgetCenter reload only happens once. It will kick off an animated transistion and reloads that
		// occur during that animation can interrupt it.
		
		debugLog("currentCount = \(WidgetModel.currentCount)")
		return .result()
	}
}

// NOTE: AudioPlaybackIntent can be used when you want to ensure that the AppIntent is executed within the context of the app
// (as opposed to the widget's context). This is important for things like starting a background audio session, which is not
// possible in an extension context.

struct StartStationIntent: AudioPlaybackIntent {

	//static let intentClassName = "INPlayMediaIntent"
	
	// the name of the action in Shortcuts
	static var title: LocalizedStringResource = "Start Station"
	
	// description of the action in Shortcuts
	// category name allows you to group actions - shown when tapping on an app in the Shortcuts library
	static var description: IntentDescription = IntentDescription("Start a station.", categoryName: "Editing")
	
	@Parameter(title: "Station", description: "The name of the station", requestValueDialog: IntentDialog("What is the station?"))
	var station: ShortcutsDatumEntity
	
	// How the summary will appear in the shortcut action.
	// More parameters are included below the fold in the trailing closure. In Shortcuts, they are listed in the reverse order they are listed here
	static var parameterSummary: some ParameterSummary {
		Summary("Start \(\.$station)")
	}

	//@MainActor // <-- include if the code needs to be run on the main thread
	func perform() async throws -> some IntentResult {
//		guard let name else {
//			throw $name.needsValueError("What is the station name?")
//		}
		// NOTE: requestDisambiguation and requestConfirmation can be used at this point.
		
		try await requestConfirmation(result: .result(value: station, dialog: "Play station with ID = \(station.id)"), confirmationActionName: .go, showPrompt: true)
		debugLog("name = \(station.name)")
		return .result()
	}

}

// NOTE: The following provider allows the AppIntent to show up in a Spotlight search.

struct IntentionalAppShortcutsProvider: AppShortcutsProvider {
	
	static var shortcutTileColor: ShortcutTileColor {
		return .lime
	}

	static var appShortcuts: [AppShortcut] {
		return [
			AppShortcut(
				intent: UpdateModelIntent(),
				phrases: [
					"Update \(.applicationName) model"
					// NOTE: Multiple phrases can be supplied to aid with matching (e.g. with Siri)
				],
				shortTitle: "Update Model",
				systemImageName: "rectangle.and.pencil.and.ellipsis"
			),
			AppShortcut(
				intent: UpdateDatumIntent(),
				phrases: [
					"Update \(.applicationName) datum"
				],
				shortTitle: "Update Datum",
				systemImageName: "list.bullet"
			),
			AppShortcut(
				intent: IncrementCountIntent(),
				phrases: [
					"Increment count in \(.applicationName)",
					"Increment count on \(.applicationName)"
				],
				shortTitle: "Increment Count",
				systemImageName: "plus.circle"
			),
			AppShortcut(
				intent: StartStationIntent(),
				phrases: [
					"Start station in \(.applicationName)",
					"Start station on \(.applicationName)"
				],
				shortTitle: "Start station",
				systemImageName: "play.fill"
			)
		]
	}
}

