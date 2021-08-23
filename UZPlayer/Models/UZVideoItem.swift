//
//  UZVideoItem.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/28/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import UIKit
import AVFoundation
import UZM3U8Kit

public enum UZResolution : Int64{
    case UltraHD = 8_294_400 /// 3840 x 2160 == 4k
    case QHD = 2_211_840 // 2048×1080 == 2k
    case FullHD = 2_073_600 // 1920x1080
    case HD = 921_600 // 1280 x720
    case p544 = 526_108 // 1280 x720
}

extension MediaResoulution {
    public var pixels : Int64 {
        return Int64(width * height)
    }
}

extension M3U8ExtXStreamInf {
    open var shortDescription : String {
        return "\(findRes(resolution: resolution))(\(Int(bandwidth/1000)) kps)"
    }
    
    private func findRes(resolution: MediaResoulution) -> String {
        let pixels = resolution.pixels
        if pixels >= UZResolution.UltraHD.rawValue {
            return "4K+"
        } else if pixels >= UZResolution.QHD.rawValue {
            return "4K"
        } else if pixels >= UZResolution.FullHD.rawValue {
            return "2K"
        } else if pixels >= UZResolution.HD.rawValue {
            return "FullHD"
        } else if pixels >= UZResolution.p544.rawValue {
            return "HD"
        } else {
            if(pixels == 0) {
                return "Audio Only"
            }
            return "\(Int(resolution.width))x\(Int(resolution.height))"
        }
    }
}

/**
Link Play info
*/
public struct UZVideoLinkPlay {
	/// Definition (etc 480, 720, 1080)
	public var definition: String
	/// Linkplay URL
	public var url: URL
	
	/// An instance of NSDictionary that contains keys for specifying options for the initialization of the AVURLAsset. See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above.
	public var options: [String: AnyHashable]?
	
	/// `AVURLAsset` of this linkPlay
    public var avURLAsset: AVURLAsset {
		return AVURLAsset(url: url, options: options)
    }
	
	/**
	Video recource item with defination name and specifying options
	
	- parameter url:        video url
	- parameter definition: url deifination
	- parameter options:    specifying options for the initialization of the AVURLAsset
	
	you can add http-header or other options which mentions in https://developer.apple.com/reference/avfoundation/avurlasset/initialization_options
	
	to add http-header init options like this
	```
	let header = ["User-Agent":"UZPlayer"]
	let definiton.options = ["AVURLAssetHTTPHeaderFieldsKey":header]
	```
	*/
	public init(definition: String, url: URL, options: [String: AnyHashable]? = nil) {
		self.url        = url
		self.definition = definition
		self.options    = options
	}
}

extension UZVideoLinkPlay: Equatable {
	
	public static func == (lhs: UZVideoLinkPlay, rhs: UZVideoLinkPlay) -> Bool {
		return lhs.url == rhs.url
	}
	
}

/**
Class chứa các thông tin về video item
*/
public struct UZVideoItem {
	public var name: String?
	public var thumbnailURL: URL?
    public var extLinkPlay: UZVideoLinkPlay?
    public fileprivate(set) var extIsTimeshift: Bool = false
    public fileprivate(set) var timeshiftSupport: Bool = false
    public fileprivate(set) var streams: [M3U8ExtXStreamInf]?
    
	public var linkPlay: UZVideoLinkPlay? {
		didSet {
			guard let url = linkPlay?.url else { return }
            do {
                let manifest = try M3U8PlaylistModel(url: url)
                if let timeshift = manifest.masterPlaylist.uzTimeshift {
                    timeshiftSupport = true
                    isLive = true
                    if timeshift.hasPrefix("extras/") {
                        do{
                            let plName = try timeshift.replace("extras/", replacement: "")
                            let extLink = try url.absoluteString.replace(plName, replacement: timeshift)
                            guard let extUrl = URL(string: extLink) else { return }
                            extLinkPlay = UZVideoLinkPlay(definition: linkPlay?.definition ?? "", url: extUrl)
                            extIsTimeshift = true
                        } catch {
                            DLog("not parse extras/ in timeshift link")
                        }
                    } else {
                        do {
                           let extLink = try url.absoluteString.replace("extras/\(timeshift)", replacement:timeshift)
                           guard let extUrl = URL(string: extLink) else { return }
                           extLinkPlay = UZVideoLinkPlay(definition: linkPlay?.definition ?? "", url: extUrl)
                            extIsTimeshift = false
                       } catch {
                           DLog("not parse extras/ in timeshift link")
                       }
                    }
                    isTimeshiftOn = !extIsTimeshift
                } else {
                    timeshiftSupport = false
                    // Not live == VOD
                    let list = manifest.masterPlaylist.xStreamList
                    list?.sortByBandwidth(inOrder: .orderedDescending)
                    streams = [M3U8ExtXStreamInf]()
                    for value in 0..<(list?.count ?? 0) {
                        if let item = list?.xStreamInf(at: value),
                            item.resolution.pixels > 0 {
                            streams?.append(item)
                        }
                    }
                }
            } catch {
                print("Error when read content m3u8")
            }
            // parse cm
			guard let cmParam = url.params()["cm"] as? String else { return }
			guard let dictionary = cmParam.base64Decoded.toDictionary() else { return }
			
			appId = dictionary["app_id"] as? String
			entityId = dictionary["entity_id"] as? String
			entitySource = dictionary["entity_source"] as? String
			isLive = entitySource?.lowercased() == "live"
		}
	}
	public var subtitleURLs: [URL]?
	
    public var isTimeshiftOn: Bool = false
    
	public fileprivate(set) var appId: String?
	public fileprivate(set) var entityId: String?
	public fileprivate(set) var entitySource: String?
	public fileprivate(set) var isLive: Bool = false
	
	/** Object description */
	public var description: String {
		return "[\(name ?? "")] url:\(linkPlay?.url.absoluteString ?? "")"
	}
	
	public init(name: String?, thumbnailURL: URL?, linkPlay: UZVideoLinkPlay, subtitleURLs: [URL]? = nil) {
		self.name = name
		self.thumbnailURL = thumbnailURL
		self.subtitleURLs = subtitleURLs
		defer {
			self.linkPlay = linkPlay
		}
	}
}

extension UZVideoItem: Equatable {
	
	public static func == (lhs: UZVideoItem, rhs: UZVideoItem) -> Bool {
		return lhs.linkPlay == rhs.linkPlay
	}
	
}
