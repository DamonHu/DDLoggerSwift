//
//  ZXKitLoggerMenuView.swift
//  ZXKitLogger
//
//  Created by Damon on 2021/5/21.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit

class ZXKitLoggerMenuView: UIView {
    var mCollectionList = [ZXKitLoggerMenuCollectionViewCellModel]()
    var clickSubject: ((_ index: Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self._createUI()
        self._loadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var mCollectionView: UICollectionView = {
        let tCollectionViewLayout = UICollectionViewFlowLayout()
        tCollectionViewLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        tCollectionViewLayout.itemSize = CGSize(width: 100, height: 100)
        tCollectionViewLayout.minimumLineSpacing = 0
        tCollectionViewLayout.minimumInteritemSpacing = 0
        tCollectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let tCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: tCollectionViewLayout)
        tCollectionView.backgroundColor = UIColor.clear
        tCollectionView.dataSource = self
        tCollectionView.delegate = self
        tCollectionView.isPagingEnabled = false
        tCollectionView.showsHorizontalScrollIndicator = false
        tCollectionView.register(ZXKitLoggerMenuCollectionViewCell.self, forCellWithReuseIdentifier: "ZXKitLoggerMenuCollectionViewCell")
        return tCollectionView
    }()
}

private extension ZXKitLoggerMenuView {
    func _createUI() {
        self.backgroundColor = UIColor.zx.color(hexValue: 0x000000, alpha: 0.6)
        self.addSubview(mCollectionView)
        mCollectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-10)
        }
    }

    func _loadData() {
        mCollectionList.removeAll()
        var titleList = ["Back".ZXLocaleString, "Decrypt".ZXLocaleString, "Search".ZXLocaleString, "Share".ZXLocaleString, "Scroll".ZXLocaleString, "Analyse".ZXLocaleString]
        var imageList = [UIImageHDBoundle(named: "icon_normal_back"), UIImageHDBoundle(named: "icon_decrypt"), UIImageHDBoundle(named: "icon_search"), UIImageHDBoundle(named: "icon_share"), UIImageHDBoundle(named: "icon_fixed"), UIImageHDBoundle(named: "icon_analyse")]

        if ZXKitLogger.uploadComplete != nil {
            titleList.append("Upload".ZXLocaleString)
            imageList.append(UIImageHDBoundle(named: "icon_upload"))
        }

        for i in 0..<titleList.count {
            let model = ZXKitLoggerMenuCollectionViewCellModel(title: titleList[i], image: imageList[i])
            mCollectionList.append(model)
        }
        self.mCollectionView.reloadData()
    }
}

extension ZXKitLoggerMenuView: UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK:collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mCollectionList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = self.mCollectionList[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZXKitLoggerMenuCollectionViewCell", for: indexPath) as! ZXKitLoggerMenuCollectionViewCell
        cell.updateUI(model: model)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let clickSubject = clickSubject {
            clickSubject(indexPath.item)
        }
    }
}
