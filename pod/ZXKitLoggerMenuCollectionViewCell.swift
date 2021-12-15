//
//  ZXKitLoggerMenuCollectionViewCell.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/5/21.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit

struct ZXKitLoggerMenuCollectionViewCellModel {
    var title = ""
    var image: UIImage?
    var isSwitchItem: Bool?
}

class ZXKitLoggerMenuCollectionViewCell: UICollectionViewCell {
    var switchSubject: ((_ index: Int, _ isOn: Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self._createUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func updateUI(model: ZXKitLoggerMenuCollectionViewCellModel) {
        self.mTitleLabel.text = model.title
        self.mImageView.image = model.image
        if let isSwitch = model.isSwitchItem {
            self.mImageView.isHidden = true
            self.mSwitchView.isHidden = false
            self.mSwitchView.setOn(isSwitch, animated: true)
        } else {
            self.mImageView.isHidden = false
            self.mSwitchView.isHidden = true
        }
    }

    //MARK: UI
    lazy var mTitleLabel: UILabel = {
        let tLabel = UILabel()
        tLabel.translatesAutoresizingMaskIntoConstraints = false
        tLabel.textAlignment = NSTextAlignment.center
        tLabel.numberOfLines = 1
        tLabel.font = UIFont.systemFont(ofSize: 13)
        tLabel.textColor = UIColor.zx.color(hexValue: 0xffffff)
        return tLabel
    }()

    lazy var mImageView: UIImageView = {
        let tImageView = UIImageView()
        tImageView.translatesAutoresizingMaskIntoConstraints = false
        return tImageView
    }()

    lazy var mSwitchView: UISwitch = {
        let switchView = UISwitch()
        switchView.addTarget(self, action: #selector(_switchChange(target:)), for: .valueChanged)
        switchView.translatesAutoresizingMaskIntoConstraints = false
        switchView.isHidden = true
        switchView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        return switchView
    }()
}

private extension ZXKitLoggerMenuCollectionViewCell {
    func _createUI() {
        self.backgroundColor = UIColor.zx.color(hexValue: 0x323764, alpha: 0.5)
        self.layer.cornerRadius = 15
        self.contentView.addSubview(mImageView)
        mImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        mImageView.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        mImageView.widthAnchor.constraint(equalToConstant: 26).isActive = true
        mImageView.heightAnchor.constraint(equalToConstant: 26).isActive = true

        self.contentView.addSubview(mSwitchView)
        mSwitchView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        mSwitchView.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true

        self.contentView.addSubview(mTitleLabel)
        mTitleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 10).isActive = true
        mTitleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        mTitleLabel.topAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 10).isActive = true
    }

    @objc func _switchChange(target: UISwitch) {
        if let switchSubject = self.switchSubject {
            switchSubject(self.tag, target.isOn)
        }
    }
}
