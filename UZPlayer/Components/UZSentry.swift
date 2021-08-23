//
//  UZSentry.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/8/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
//import Sentry

class UZSentry {
	
	class func activate() {
//		SentrySDK.start(options: ["dsn" : "https://2fb4e767fc474b7189554bce88c628c8@sentry.io/1453018", "environment" : "GA"])
	}
	
	class func sendError(error: Error?) {
//		let event = Event(level: .error)
//		event.message = error?.localizedDescription ?? "Error"
//		event.extra = ["ios": true]
//		SentrySDK.capture(event: event)
	}
	
	class func sendData(data: [String: String]?) {
//		guard let data = data else { return }
//		guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) else { return }
//
//		sendMessage(message: String(data: jsonData, encoding: .utf8))
	}
    
    class func sendMessage(message: String?) {
//        guard let message = message else { return }
//
//        let event = Event(level: .info)
//        event.message = message
//        event.extra = ["ios": true]
//		SentrySDK.capture(event: event)
    }
	
	class func sendNSError(error: NSError) {
//		let event = Event(level: .error)
//		event.message = error.localizedDescription
//		event.extra = ["ios": true]
//		SentrySDK.capture(event: event)
	}
	
}
