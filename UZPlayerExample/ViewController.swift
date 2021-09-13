//
//  ViewController.swift
//  UZPlayerExample
//
//  Created by Nam Kennic on 3/17/20.
//  Copyright © 2020 Uiza. All rights reserved.
//

import UIKit
//import UZPlayer

class ViewController: UIViewController {
	
	let playerViewController = UZPlayerViewController()
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		view.backgroundColor = .lightGray
		
		playerViewController.modalPresentationStyle = .fullScreen
//		playerViewController.player.aspectRatio = .aspectFill
		playerViewController.player.controlView.theme = UZTheme1()
		playerViewController.player.isHidden = true
		view.addSubview(playerViewController.view)
		
		askForURL()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let viewSize = view.bounds.size
		let playerSize = CGSize(width: viewSize.width, height: viewSize.width * 9/16)
		playerViewController.view.frame = CGRect(x: 0, y: 100, width: playerSize.width, height: playerSize.height)
	}
	
/// UserDefaults.standard.string(forKey: "last_url") ?? "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
	func askForURL() {
//       let prefilled = "https://1955897154.rsc.cdn77.org/live/8dee8601-931e-409a-b2e8-aa84761add1e/master.m3u8?cm=eyJlbnRpdHlfaWQiOiI4ZGVlODYwMS05MzFlLTQwOWEtYjJlOC1hYTg0NzYxYWRkMWUiLCJlbnRpdHlfc291cmNlIjoibGl2ZSIsImFwcF9pZCI6IjhhZTY3ZDlmM2EyNzQyODVhMTUwNmUzZjc3Njc5MmVhIn0="
//		let prefilled = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let prefilled = "https://hls.ted.com/talks/2639.m3u8?preroll=Thousands"
        
		let alertController = UIAlertController(title: "", message: "Please enter videoURL", preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.font = UIFont(name: "Avenir", size: 14)
			textField.keyboardType = .URL
			textField.clearButtonMode = .whileEditing
			textField.text = prefilled
            textField.frame.size.height = 153
		}
		alertController.addAction(UIAlertAction(title: "Play", style: .default, handler: { [weak self] (action) in
			if let string = alertController.textFields?.first?.text, !string.isEmpty {
				UserDefaults.standard.set(string, forKey: "last_url")
				alertController.dismiss(animated: true, completion: nil)
				self?.presentPlayer(urlPath: string)
			}
			else {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self?.askForURL()
				}
			}
		}))
		alertController.addAction(UIAlertAction(title: "Play as Float Player", style: .default, handler: { [weak self] (action) in
			if let string = alertController.textFields?.first?.text, !string.isEmpty {
				UserDefaults.standard.set(string, forKey: "last_url")
				alertController.dismiss(animated: true, completion: nil)
				self?.presentFloatingPlayer(urlPath: string)
			}
			else {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self?.askForURL()
				}
			}
		}))
		present(alertController, animated: true, completion: nil)
	}
	
	func presentPlayer(urlPath: String) {
		guard let url = URL(string: urlPath) else { return }
		playerViewController.player.isHidden = false
        playerViewController.player.loadVideo(url: url)
	}
	
	func presentFloatingPlayer(urlPath: String) {
		guard let url = URL(string: urlPath) else { return }
		
		let videoItem = UZVideoItem(name: nil, thumbnailURL: nil, linkPlay: UZVideoLinkPlay(definition: "", url: url))
		let floatPlayer = MoviePlayerViewController()
		floatPlayer.present(with: videoItem, playlist: nil).player.controlView.theme = UZTheme1()
		floatPlayer.delegate = self
	}
	
	override open var prefersStatusBarHidden: Bool {
		return true
	}
	
//	override open var shouldAutorotate: Bool {
//		return false
//	}
//	
//	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
//		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
//	}
//	
//	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
//	}
	
}

extension ViewController: UZFloatingPlayerViewDelegate {
	
	func floatingPlayer(_ player: UZFloatingPlayerViewController, didBecomeFloating: Bool) {
		print(didBecomeFloating ? "Did become floating" : "Did unfloat")
		guard let floatingPlayer = player as? MoviePlayerViewController else { return }
		floatingPlayer.topPadding = didBecomeFloating ? 0 : view.extendSafeEdgeInsets.top
	}
	
	func floatingPlayer(_ player: UZFloatingPlayerViewController, onFloatingProgress: CGFloat) {
		guard let floatingPlayer = player as? MoviePlayerViewController else { return }
		floatingPlayer.topPadding = view.extendSafeEdgeInsets.top - (view.extendSafeEdgeInsets.top * onFloatingProgress)
	}
	
	func floatingPlayerDidDismiss(_ player: UZFloatingPlayerViewController) {
		askForURL()
	}
	
}
