//
//  SettingItem.swift
//  UZPlayerExample
//
//  Created by Nam Nguyen on 7/3/20.
//  Copyright © 2020 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import AVFoundation
import UZM3U8Kit

public enum UZSettingTag: Int, CaseIterable {
    case none = -1
    case timeshift = 101
    case speedRate = 103
    case stats = 105
    case quality = 107
    case audio = 109
    case captions = 111
    
    var description : String {
      switch self {
          case .none: return "None"
          case .timeshift: return "Timeshift"
          case .speedRate: return "Speed"
          case .stats: return "Stats"
          case .quality: return "Quality"
          case .audio: return "Audio"
          case .captions: return "Captions"
        }
    }

}

public enum UZSettingType: Int, CaseIterable {
    case normal = 0
    case array = 3
    case bool = 1
    case number = 2
}


class SettingItem: NSObject {
    fileprivate(set) var title : String = ""
    fileprivate(set) var tag: UZSettingTag = .none
    fileprivate(set) var type: UZSettingType = .normal
    open var initValue: Any?
    open var childItems: [AVMediaSelectionOption]? = nil
    open var streamItems: [M3U8ExtXStreamInf]? = nil
    
    init(tag: UZSettingTag, type: UZSettingType = .normal, initValue : Any? = nil, childItems: [AVMediaSelectionOption]? = nil, streamItems: [M3U8ExtXStreamInf]? = nil) {
        super.init()
        self.title = tag.description
        self.tag = tag
        self.type = type
        self.initValue = initValue
        self.childItems = childItems
        self.streamItems = streamItems
    }
    
    init(title: String, tag: UZSettingTag, type: UZSettingType = .normal, initValue : Any? = nil) {
        super.init()
        self.title = title
        self.tag = tag
        self.type = type
        self.initValue = initValue
    }

    
}

class SettingTableViewCell: UITableViewCell {
    
    public static let IDENTIFIER = "setting_cell_identifier"
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViews()
    }
    
    let titleLabel:UILabel = {
        let label = UILabel()
//        label.textColor =  UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let summaryLabel:UILabel = {
        let label = UILabel()
        label.textColor = label.textColor.withAlphaComponent(0.5)
        label.font = .systemFont(ofSize: 15.0, weight: .light)
        label.translatesAutoresizingMaskIntoConstraints = false
       return label
    }()
    
    let containerView:UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.clipsToBounds = true // this will make sure its children do not go out of the boundary
      return view
    }()
    
    func initViews() {

        containerView.addSubview(titleLabel)
        containerView.addSubview(summaryLabel)
        self.contentView.addSubview(containerView)
        containerView.centerYAnchor.constraint(equalTo:self.contentView.centerYAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo:self.contentView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo:self.contentView.trailingAnchor, constant:-10).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        //
        titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        // summary
        summaryLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        summaryLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        self.tintColor = UIColor.red

    }
}
