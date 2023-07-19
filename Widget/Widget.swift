//
//  IntentionalWidget.swift
//  Widget
//
//  Created by Craig Hockenberry on 7/19/23.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		let entry = SimpleEntry(date: .now)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
		let currentDate = Date.now
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
	let currentCount: Int
    let selectedId: String
	
	init(date: Date) {
		self.date = date
		self.currentCount = WidgetModel.currentCount
		self.selectedId = WidgetModel.selectedId
	}
}

struct WidgetEntryView : View {
    var entry: Provider.Entry

	@Environment(\.widgetFamily) var widgetFamily: WidgetFamily

	// NOTE: The WidgetModel needs a group container: make sure that entitlement is granted
	// to the widget extension.
	
// NOTE: In theory, the Widget preview and UserDefaults for the app should be shared. In
// practice, this is buggy (see WidgetModel.swift to understand how group containers differ
// between the two environments. To minimize confusion, you can force the model to be populated
// at design time by setting this flag to true:
#if false
#if !DEBUG
#error("Using test data in non-DEBUG build")
#endif
	init(entry: Provider.Entry) {
		self.entry = entry

		WidgetModel.widgetData = [
			WidgetModel.WidgetDatum(id: "1", name: "A"),
			WidgetModel.WidgetDatum(id: "2", name: "BB"),
			WidgetModel.WidgetDatum(id: "3", name: "CCC"),
			WidgetModel.WidgetDatum(id: "4", name: "DDDD"),
		]
		WidgetModel.selectedId = "3"
	}
#endif
	
	var widgetData = WidgetModel.widgetData
	
    var body: some View {
		if widgetData.isEmpty {
			Text("No Widget Data")
		}
		else {
			HStack {
				ForEach(widgetData) { widgetDatum in
					Button(intent: WidgetSelectIntent(selectingId: widgetDatum.id)) {
						Text(widgetDatum.name)
					}
					.buttonStyle(.borderedProminent)
					.tint(entry.selectedId == widgetDatum.id ? .green : .red)
				}
				Button(intent: WidgetCountIntent()) {
					Image(systemName: "plus")
				}
				.buttonStyle(.borderedProminent)
				.tint(.blue)
			}
			.onAppear {
				// NOTE: See the note in WidgetModel.swift about group containers issues for widget previews. There's
				// a reason this debug logging is here.
				debugLog("widgetData = \(widgetData)")
				let groupContainerId = "group.com.iconfactory.Intentional"
				if let groupContainerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainerId) {
					debugLog("groupContainerUrl = `\(groupContainerUrl.path(percentEncoded: false))`")
				}

			}
		}
        VStack {
			Text("Updated at \(entry.date.formatted(date: .omitted, time: .standard))")
			Text("Count: entry = \(entry.currentCount), model = \(WidgetModel.currentCount)")
			Text("Selected: entry = \(entry.selectedId), model = \(WidgetModel.selectedId)")
        }
    }
}

struct IntentionalWidget: Widget {
    let kind: String = "IntentionalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemMedium) {
	IntentionalWidget()
} timeline: {
    SimpleEntry(date: .now)
	SimpleEntry(date: .now)
}
