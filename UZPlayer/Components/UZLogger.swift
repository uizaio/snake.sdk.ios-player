//
//  UZLogger.swift
//  UizaSDK
//
//  Created by Nam Kennic on 3/23/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

/**
Class for logging
*/
open class UZLogger: UZAPIConnector {
	static let logAPIEndpoint = "https://tracking-dev.uizadev.io/v1/events"
	static let prodAPIEndpoint = "https://tracking.uiza.sh/v1/events"
    
	public var currentVideo: UZVideoItem? = nil
	public var currentLinkPlay: URL? = nil {
		didSet {
			appId = nil
			entityId = nil
			entitySource = nil
			sessionId = nil
			
			guard let url = currentLinkPlay else { return }
			guard let cmParam = url.params()["cm"] as? String else { return }
			guard let dictionary = cmParam.base64Decoded.toDictionary() else { return }
			
			appId = dictionary["app_id"] as? String
			entityId = dictionary["entity_id"] as? String
			entitySource = dictionary["entity_source"] as? String
			sessionId = UUID().uuidString
		}
	}
	
	public var entityId: String? = nil
	public var entitySource: String? = nil
	public var sessionId: String? = nil
	public var appId: String? = nil
	
	let dateFormatter = DateFormatter()
	
	/// Singleton instance
	static public let shared = UZLogger()
	private override init() {
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
	}
	
    open func log(event: String, params: Parameters? = nil) {
		let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
		let timestamp: String = dateFormatter.string(from: Date())
		
		let logParams: Parameters = ["data" : ["entity_id": entityId ?? "",
											   "entity_source": entitySource ?? "",
											   "event": event,
											   "viewer_user_id" : uuid,
											   "viewer_session_id": sessionId ?? "",
											   "timestamp": timestamp,
											   "app_id" : appId ?? ""]]
		
		let defaultParams: Parameters! = ["type": "io.uiza.\(event)event",
										  "time": timestamp,
										  "source" : "UZData/IOSSDK/\(PLAYER_VERSION)",
										  "specversion" : "1.0"]
		
		var finalParams: Parameters! = defaultParams
		finalParams.appendFrom(logParams)
		
		if params != nil {
			finalParams.appendFrom(params!)
		}
        let prod = UZPlayerSDK.enviroment == .production
        guard let url = URL(string: prod ? Self.prodAPIEndpoint : Self.logAPIEndpoint) else { return }
		post(url: url, params: finalParams)
	}
	
}

