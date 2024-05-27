//
//  DDLoggerSwiftFilterTypeView.swift
//  DDLoggerSwift
//
//  Created by Damon on 2023/4/9.
//  Copyright © 2023 Damon. All rights reserved.
//

import UIKit

protocol DDLoggerSwiftFilterTypeViewDelegate: AnyObject {
    func filterSelected(filterType: DDLogType?)
}

class DDLoggerSwiftFilterTypeView: UIView {
    private let dataList = ["none", "debug", "info", "warn", "error", "privacy"]
    weak var delegate: DDLoggerSwiftFilterTypeViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self._createUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: UI
    private lazy var mTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.plain)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = true
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tableView.backgroundColor = UIColor.dd.color(hexValue: 0xfcfcfc)
        tableView.separatorColor = UIColor.dd.color(hexValue: 0xcccccc)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return tableView
    }()

}

extension DDLoggerSwiftFilterTypeView {
    func _createUI() {
        self.addSubview(mTableView)
        mTableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        mTableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        mTableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        mTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}

extension DDLoggerSwiftFilterTypeView: UITableViewDelegate, UITableViewDataSource {
    //MARK:UITableViewDelegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let loggerItem = self.dataList[indexPath.row]
        
        let loggerCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")!
        loggerCell.backgroundColor = UIColor.clear
        loggerCell.selectionStyle = .none
        loggerCell.textLabel?.text = loggerItem
        return loggerCell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = delegate {
            switch indexPath.row {
            case 0:
                delegate.filterSelected(filterType: nil)
            case 1:
                delegate.filterSelected(filterType: .debug)
            case 2:
                delegate.filterSelected(filterType: .info)
            case 3:
                delegate.filterSelected(filterType: .warn)
            case 4:
                delegate.filterSelected(filterType: .error)
            case 5:
                delegate.filterSelected(filterType: .privacy)
            default:
                break
            }
            
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
