//
//  UZDeviceListTableViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/25/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalViewManager
#if canImport(GoogleCast)
import GoogleCast

class UZDeviceListTableViewController: UITableViewController {
	
	let castingManager = UZCastingManager.shared

	override func viewDidLoad() {
        super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceListUpdated), name: .UZDeviceListDidUpdate, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onSessionDidStart), name: .UZCastSessionDidStart, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onSessionDidStop), name: .UZCastSessionDidStop, object: nil)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		castingManager.startDiscovering()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		castingManager.stopDiscovering()
	}
	
	override var prefersStatusBarHidden: Bool {
		return UIApplication.shared.isStatusBarHidden
	}
	
	override var shouldAutorotate: Bool {
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .all
	}
	
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIApplication.shared.statusBarOrientation
	}
	
	override var preferredContentSize: CGSize {
		get {
			var screenSize = UIScreen.main.bounds.size
			screenSize.width = min(320, screenSize.width * 0.8)
			screenSize.height = min(min(400, screenSize.height * 0.8), CGFloat((castingManager.deviceCount + 2) * 50))
			return screenSize
		}
		set {
			super.preferredContentSize = newValue
		}
	}
	
	override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
		if let viewController = NKModalViewManager.sharedInstance().modalViewControllerThatContains(self) {
			viewController.dismissWith(animated: flag, completion: completion)
		} else {
			super.dismiss(animated: flag, completion: completion)
		}
	}
	
	func reloadCell(with device: GCKDevice) {
        // swiftlint:disable empty_count
		let count = castingManager.deviceCount
		if count > 0 {
			var index: Int?
			for temp in 0..<count {
				if device == castingManager.device(at: UInt(temp)) {
					index = temp
					break
				}
			}
			
			if let index = index {
				tableView.reloadRows(at: [IndexPath(row: 0, section: 0), IndexPath(row: index, section: 1)], with: .none)
			}
		}
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 1 ? castingManager.deviceCount : 1
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		
		if cell == nil {
			cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
		}
		
        return cell!
    }
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let normalColor = UIColor(white: 0.2, alpha: 1.0)
		let selectedColor = UIColor(red: 0.28, green: 0.49, blue: 0.93, alpha: 1.00)
		
		if indexPath.section == 0 {
			if UIDevice.isPhone() {
				cell.textLabel?.text = "This iPhone"
				cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.phoneIphone), size: CGSize(width: 32, height: 32),
                                                textColor: normalColor, backgroundColor: .clear)
				cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.phoneIphone), size: CGSize(width: 32, height: 32),
                                                           textColor: selectedColor, backgroundColor: .clear)
			} else {
				cell.textLabel?.text = "This iPad"
				cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.tabletMac), size: CGSize(width: 32, height: 32),
                                                textColor: normalColor, backgroundColor: .clear)
				cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.tabletMac), size: CGSize(width: 32, height: 32),
                                                           textColor: selectedColor, backgroundColor: .clear)
			}
			
			cell.detailTextLabel?.text = "Playing here"
			cell.accessoryType = castingManager.currentCastSession == nil ? .checkmark : .none
		} else if indexPath.section == 1 {
			let device = castingManager.device(at: UInt(indexPath.row))
			cell.textLabel?.text = device.modelName
			cell.detailTextLabel?.text = "Connect"
			cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.cast), size: CGSize(width: 32, height: 32),
                                            textColor: normalColor, backgroundColor: .clear)
			cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.cast), size: CGSize(width: 32, height: 32),
                                                       textColor: selectedColor, backgroundColor: .clear)
			
			if let currentCastSession = castingManager.currentCastSession {
				cell.accessoryType = currentCastSession.device == device ? .checkmark : .none
			} else {
				cell.accessoryType = .none
			}
		} else if indexPath.section == 2 {
			cell.textLabel?.text = "AirPlay and Bluetooth"
			cell.detailTextLabel?.text = "Show more devices..."
			cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.airplay), size: CGSize(width: 32, height: 32),
                                            textColor: normalColor, backgroundColor: .clear)
			cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.airplay), size: CGSize(width: 32, height: 32),
                                                       textColor: selectedColor, backgroundColor: .clear)
			cell.accessoryType = .none
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			castingManager.disconnect()
			self.dismiss(animated: true, completion: nil)
		} else if indexPath.section == 1 {
			let device = castingManager.device(at: UInt(indexPath.row))
			castingManager.connect(to: device)
			
			if let cell = tableView.cellForRow(at: indexPath) {
				#if swift(>=4.2)
				let loadingView = UIActivityIndicatorView(style: .gray)
				#else
				let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
				#endif
				loadingView.hidesWhenStopped = true
				loadingView.startAnimating()
				cell.accessoryView = loadingView
			}
		} else {
			self.dismiss(animated: true) {
				PostNotification(UZPlayer.ShowAirPlayDeviceListNotification)
			}
		}
	}
	
	// MARK: -
	
	@objc func onDeviceListUpdated() {
		self.tableView.reloadData()
		self.presentingModalViewController()?.setNeedsLayoutView()
	}
	
	@objc func onSessionDidStart(_ notification: Notification) {
		if let device = castingManager.currentCastSession?.device {
			reloadCell(with: device)
		} else {
			tableView.reloadData()
		}
		
		tableView.isUserInteractionEnabled = false
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			self.dismiss(animated: true, completion: nil)
		}
	}
	
	@objc func onSessionDidStop(_ notification: Notification) {
		if let device = castingManager.currentCastSession?.device {
			reloadCell(with: device)
		} else {
			tableView.reloadData()
		}
	}

}

// MARK: -

extension UZDeviceListTableViewController: NKModalViewControllerProtocol {
	
	func shouldTapOutside(toDismiss modalViewController: NKModalViewController!) -> Bool {
		return true
	}
	
	func presentingStyle(for modalViewController: NKModalViewController!) -> NKModalPresentingStyle {
		return .zoomIn
	}
	
	func dismissingStyle(for modalViewController: NKModalViewController!) -> NKModalDismissingStyle {
		return .zoomOut
	}
	
}
#endif
