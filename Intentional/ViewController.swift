//
//  ViewController.swift
//  Intentional
//
//  Created by Craig Hockenberry on 7/19/23.
//

import UIKit

import WidgetKit

class ViewController: UIViewController {

	@IBOutlet var currentCountLabel: UILabel!
	@IBOutlet var selectedIdLabel: UILabel!
	@IBOutlet var widgetDataLabel: UILabel!

	private func updateView() {
		currentCountLabel.text = String(WidgetModel.currentCount)
		selectedIdLabel.text = "'\(WidgetModel.selectedId)'"
		widgetDataLabel.text = WidgetModel.widgetData.description
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		updateView()	}

	@IBAction func refresh() {
		updateView()
	}

	@IBAction func incrementCount() {
		WidgetModel.incrementCount()
		WidgetCenter.shared.reloadAllTimelines()

		updateView()
	}

}

