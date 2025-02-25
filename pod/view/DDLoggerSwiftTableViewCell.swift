//
//  DDLoggerSwiftTableViewCell.swift
//  DDLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit

class DDLoggerSwiftTableViewCell: UITableViewCell {
    private lazy var mContentLabel: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    private lazy var mIDLabel: UILabel = {
        var label = UILabel()
        label.textColor = UIColor.dd.color(hexValue: 0xcccccc)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self._createUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func _createUI() -> Void {
        self.backgroundColor = UIColor.clear
        
        self.contentView.addSubview(self.mContentLabel)
        self.mContentLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16).isActive = true
        self.mContentLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16).isActive = true
        self.mContentLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
        self.mContentLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10).isActive = true
        
        self.contentView.addSubview(self.mIDLabel)
        self.mIDLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16).isActive = true
        self.mIDLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 3).isActive = true
    }
    
    func updateWithLoggerItem(model:DDLoggerSwiftTableCellModel, highlightText:String) {
        let loggerItem = model.logItem
        self.mIDLabel.text = "#\(loggerItem.databaseID)"
        self.mContentLabel.textColor = loggerItem.mLogItemType.textColor()
        var contentString = loggerItem.getFullContentString()
        if model.isCollapse {
            contentString = contentString.dd.subString(rang: NSRange(location: 0, length: DDLoggerSwift.cellDisplayCount))
        }
        loggerItem.getHighlightAttributedString(contentString: contentString, highlightString: highlightText) { (hasHighlightStr, hightlightAttributedString) in
            if model.isCollapse {
                let read = NSAttributedString(string: "Read more", attributes: [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.dd.color(hexValue: 0xeeeeee), .foregroundColor: UIColor.dd.color(hexValue: 0xeeeeee)])
                
                let attri = NSMutableAttributedString()
                attri.append(hightlightAttributedString)
                attri.append(NSAttributedString(string: "……\n\n"))
                attri.append(read)
                self.mContentLabel.attributedText = attri
            } else {
                self.mContentLabel.attributedText = hightlightAttributedString
            }
            
//            if hasHighlightStr {
//                self.contentView.backgroundColor = UIColor.dd.color(hexValue: 0xe58e23)
//            } else {
//                self.contentView.backgroundColor = UIColor.clear
//            }
        }
        
    }
}
