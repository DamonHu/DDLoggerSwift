//
//  HDLoggerSwiftTableViewCell.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2019/6/24.
//  Copyright © 2019 Damon. All rights reserved.
//

import UIKit

class HDLoggerSwiftTableViewCell: UITableViewCell {
    
    private lazy var mContentLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
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
        self.p_createUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func p_createUI() -> Void {
        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(self.mContentLabel)
    }
    
    func updateWithLoggerItem(loggerItem:HDWindowLoggerItem) {
        self.mContentLabel.text = loggerItem.getFullContentString()
        switch loggerItem.mLogItemType {
        case .kHDLogTypeNormal:
            self.mContentLabel.textColor = UIColor(red: 93.0/255.0, green: 174.0/255.0, blue: 139.0/255.0, alpha: 1.0)
            break
        case .kHDLogTypeWarn:
            self.mContentLabel.textColor = UIColor(red: 246.0/255.0, green: 244.0/255.0, blue: 157.0/255.0, alpha: 1.0)
            break
        case .kHDLogTypeError:
            self.mContentLabel.textColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
            break
        }
        let size = self.mContentLabel.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(MAXFLOAT)))
        self.mContentLabel.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
}
