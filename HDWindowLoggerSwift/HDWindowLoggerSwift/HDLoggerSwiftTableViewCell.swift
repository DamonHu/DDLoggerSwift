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
    
    func updateWithLoggerItem(loggerItem:HDWindowLoggerItem, searchText:String) {
        switch loggerItem.mLogItemType {
        case .kHDLogTypeNormal:
            self.mContentLabel.textColor = UIColor(red: 80.0/255.0, green: 216.0/255.0, blue: 144.0/255.0, alpha: 1.0)
            break
        case .kHDLogTypeWarn:
            self.mContentLabel.textColor = UIColor(red: 246.0/255.0, green: 244.0/255.0, blue: 157.0/255.0, alpha: 1.0)
            break
        case .kHDLogTypeError:
            self.mContentLabel.textColor = UIColor(red: 255.0/255.0, green: 118.0/255.0, blue: 118.0/255.0, alpha: 1.0)
            break
        case .kHDLogTypePrivacy:
            self.mContentLabel.textColor = UIColor(red: 66.0/255.0, green: 230.0/255.0, blue: 164.0/255.0, alpha: 1.0)
            break
        }
        
        if searchText.isEmpty {
            self.mContentLabel.text = loggerItem.getFullContentString()
        } else {
            let contentString = loggerItem.getFullContentString()
            let attributedString = NSMutableAttributedString(string: contentString)
            let regx = try? NSRegularExpression(pattern: searchText, options: NSRegularExpression.Options.caseInsensitive)
            if let searchRegx = regx {
                searchRegx.enumerateMatches(in: contentString, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange(location: 0, length: contentString.count)) { (result: NSTextCheckingResult?, flag, stop) in
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 255.0/255.0, green: 0.0, blue: 0.0, alpha: 1.0), range: result?.range ?? NSRange(location: 0, length: 0))
                    self.mContentLabel.attributedText = attributedString
                }
            } else {
                self.mContentLabel.text = loggerItem.getFullContentString()
            }
        }
        let size = self.mContentLabel.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(MAXFLOAT)))
        self.mContentLabel.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
}
