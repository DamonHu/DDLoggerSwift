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

}

class ZXKitLoggerMenuCollectionViewCell: UICollectionViewCell {
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

}

private extension ZXKitLoggerMenuCollectionViewCell {
    func _createUI() {
        self.backgroundColor = UIColor.zx.color(hexValue: 0x323764)
        self.layer.cornerRadius = 15
        self.contentView.addSubview(mImageView)
        mImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        mImageView.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        mImageView.widthAnchor.constraint(equalToConstant: 26).isActive = true
        mImageView.heightAnchor.constraint(equalToConstant: 26).isActive = true

        self.contentView.addSubview(mTitleLabel)
        mTitleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 10).isActive = true
        mTitleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        mTitleLabel.topAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 10).isActive = true
    }
}
