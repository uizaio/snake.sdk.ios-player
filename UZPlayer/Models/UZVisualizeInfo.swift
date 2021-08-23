//
//  UZVisualizeInfo.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/21/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation
import UIKit

struct UZVisualizeSavedInformation {
    static var shared = UZVisualizeSavedInformation()
    
    var osInformation = "\(UIDevice.current.systemVersion), \(UIDevice.current.hardwareName())" {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var volume: Float = 0 {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var host = "" {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var quality: CGFloat = 0 {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var currentVideo: UZVideoItem? {
        didSet {
            updateVisualizeInformation()
        }
    }
    
    var livestreamCurrentDate: Date?
    
    var isUpdateLivestreamLatency: Bool = false {
        didSet {
            if isUpdateLivestreamLatency {
                updateVisualizeInformation()
            }
        }
    }
    
    private func updateVisualizeInformation() {
        NotificationCenter.default.post(name: .UZEventVisualizeInformaionUpdate, object: self, userInfo: nil)
    }
}
