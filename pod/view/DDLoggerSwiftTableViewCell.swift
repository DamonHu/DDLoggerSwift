//
//  DDLoggerSwiftTableViewCell.swift
//  DDLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit

class DDLoggerSwiftTableViewCell: UITableViewCell {
    private lazy var mCollapseLabel: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return label
    }()
    
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
        
        self.contentView.addSubview(mCollapseLabel)
        self.mCollapseLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 10).isActive = true
        self.mCollapseLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.mCollapseLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true
        self.mCollapseLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.contentView.addSubview(self.mContentLabel)
        self.mContentLabel.leftAnchor.constraint(equalTo: self.mCollapseLabel.rightAnchor, constant: 10).isActive = true
        self.mContentLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        self.mContentLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
        self.mContentLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -2).isActive = true
        
        self.contentView.addSubview(self.mIDLabel)
        self.mIDLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        self.mIDLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 3).isActive = true
    }
    
    func updateWithLoggerItem(model:DDLoggerSwiftTableCellModel, highlightText:String) {
        let loggerItem = model.logItem
        self.mIDLabel.text = "#\(loggerItem.databaseID)"
        self.mContentLabel.textColor = loggerItem.mLogItemType.textColor()
        var contentString = loggerItem.getFullContentString()
        if model.isCollapse {
            mCollapseLabel.text = "🗂"
            contentString = contentString.dd.subString(rang: NSRange(location: 0, length: DDLoggerSwift.cellDisplayCount))
        } else {
            mCollapseLabel.text = loggerItem.icon()
        }
        loggerItem.getHighlightAttributedString(contentString: contentString, highlightString: highlightText) { (hasHighlightStr, hightlightAttributedString) in
            self.mContentLabel.attributedText = hightlightAttributedString
//            if hasHighlightStr {
//                self.contentView.backgroundColor = UIColor.dd.color(hexValue: 0xe58e23)
//            } else {
//                self.contentView.backgroundColor = UIColor.clear
//            }
        }
        
    }
}
