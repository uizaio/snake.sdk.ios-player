//
//  UZAPIConnector.swift
//  UZPlayer
//
//  Created by Nam Nguyễn on 5/20/20.
//  Copyright © 2020 Nam Kennic. All rights reserved.
//

import UIKit

open class UZAPIConnector: NSObject {
	public typealias APIConnectorResultBlock = (NSDictionary?, Error?) -> Void
	/// Parameter type
	public typealias Parameters = [String: Any]
	
	public func get(url: URL, params: Parameters, completion: APIConnectorResultBlock? = nil) {
		guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
		urlComponents.queryItems = params.map { (key, value) in
			URLQueryItem(name: key, value: value as? String)
		}
		urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
		
		var request = URLRequest(url: urlComponents.url!)
//		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "GET"
		request.cachePolicy = .reloadIgnoringLocalCacheData
		request.timeoutInterval = 30
//		DLog("\(params)")
//		URLSession.shared.dataTask(with: request).resume()
		
        #if DEBUG
			print("📍 cURL:\n \(request.curlString)\n")
		#endif
		
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data,                            // is there data
				let response = response as? HTTPURLResponse,  // is there HTTP response
				(200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
				error == nil
			else {                           // was there no error, otherwise ...
                completion?(nil, error)
                return
			}
			
			let responseObject = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
			DLog("response = \(String(describing: responseObject))")
			completion?(responseObject as NSDictionary?, nil)
		}
		task.resume()
	}
	
	public func post(url: URL, params: Parameters) {
		var request = URLRequest(url: url)
		request.setValue("application/cloudevents-batch+json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "POST"
		request.cachePolicy = .reloadIgnoringLocalCacheData
		request.timeoutInterval = 30
//		request.httpBody = params.percentEncoded()
		
		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
		} catch let error {
			DLog(error.localizedDescription)
		}

//		DLog("\(params)")
		#if DEBUG
			print("📍 cURL:\n \(request.curlString)\n")
		#endif
		
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data,
				let response = response as? HTTPURLResponse,
				error == nil else {                                              // check for fundamental networking error
					DLog("error \(String(describing: error))")
					return
			}
			
			guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
				DLog("statusCode should be 2xx, but is \(response.statusCode)")
				DLog("response = \(response)")
				return
			}
			
			let responseString = String(data: data, encoding: .utf8)
			DLog("responseString = \(String(describing: responseString))")
		}
		
		task.resume()
	}
	
}

// MARK: -

extension URLRequest {
	/**
	Returns a cURL command representation of this URL request.
	*/
	public var curlString: String {
		guard let url = url else { return "" }
		var baseCommand = "curl \(url.absoluteString)"
		if httpMethod == "HEAD" {
			baseCommand += " --head"
		}
		var command = [baseCommand]
		if let method = httpMethod, method != "GET" && method != "HEAD" {
			command.append("-X \(method)")
		}
		if let headers = allHTTPHeaderFields {
			for (key, value) in headers where (key != "Cookie" && key != "charset") {
				if key == "Content-Type" {
					command.append("-H '\(key): \(value.replacingOccurrences(of: "; charset=utf-8", with: ""))'")
				}
				else {
					command.append("-H '\(key): \(value)'")
				}
			}
		}
		if let data = httpBody, let body = String(data: data, encoding: .utf8) {
			command.append("-d '\(body)'")
		}
		return command.joined(separator: " \\\n\t")
	}
	
	init?(curlString: String) {
		return nil
	}
}

extension String {
	
	public var base64Decoded: String {
		guard let data: Data = Data(base64Encoded: String(self), options: .ignoreUnknownCharacters), let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
			return ""
		}
		return String(describing: dataString)
	}
	
}

extension Dictionary {
	
	mutating func appendFrom(_ other: Dictionary) {
		for (key, value) in other {
			self.updateValue(value, forKey: key)
		}
	}
	
}

extension URL {
	
	func params() -> [String: Any] {
		var dict = [String: Any]()
		
		if let components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
			if let queryItems = components.queryItems {
				for item in queryItems {
					dict[item.name] = item.value!
				}
			}
			return dict
		}
		else {
			return [:]
		}
	}
	
}

extension NSString {
	
	func toDictionary() -> NSDictionary? {
		if let data = self.data(using: String.Encoding.utf8.rawValue) {
			do {
				return try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
			} catch {
				UZSentry.sendError(error: error)
				DLog(error.localizedDescription)
			}
		}
		
		return nil
	}
	
}

extension Dictionary {
	
	func percentEncoded() -> Data? {
		return map { key, value in
			let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
			let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
			return escapedKey + "=" + escapedValue
		}
		.joined(separator: "&")
		.data(using: .utf8)
	}
	
}

extension CharacterSet {
	
	static let urlQueryValueAllowed: CharacterSet = {
		let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
		let subDelimitersToEncode = "!$&'()*+,;="
		
		var allowed = CharacterSet.urlQueryAllowed
		allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
		return allowed
	}()
	
}
