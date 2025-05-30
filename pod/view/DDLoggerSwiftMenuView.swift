//
//  DDLoggerSwiftMenuView.swift
//  DDLoggerSwift
//
//  Created by Damon on 2021/5/21.
//  Copyright © 2021 Damon. All rights reserved.
//

import UIKit

class DDLoggerSwiftMenuView: UIView {
    var mCollectionList = [DDLoggerSwiftMenuCollectionViewCellModel]()
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
        tCollectionViewLayout.minimumLineSpacing = 5
        tCollectionViewLayout.minimumInteritemSpacing = 5
        tCollectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let tCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: tCollectionViewLayout)
        tCollectionView.translatesAutoresizingMaskIntoConstraints = false
        tCollectionView.backgroundColor = UIColor.clear
        tCollectionView.dataSource = self
        tCollectionView.delegate = self
        tCollectionView.isPagingEnabled = false
        tCollectionView.showsHorizontalScrollIndicator = false
        tCollectionView.register(DDLoggerSwiftMenuCollectionViewCell.self, forCellWithReuseIdentifier: "DDLoggerSwiftMenuCollectionViewCell")
        return tCollectionView
    }()
}

private extension DDLoggerSwiftMenuView {
    func _createUI() {
        self.backgroundColor = UIColor.dd.color(hexValue: 0x2d353b)
        self.addSubview(mCollectionView)
        mCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        mCollectionView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        mCollectionView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        mCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
    }

    func _loadData() {
        mCollectionList.removeAll()
        var titleList = ["Clean Log".ZXLocaleString, "Share".ZXLocaleString, "Decrypt".ZXLocaleString, "History".ZXLocaleString, "Analyse".ZXLocaleString]
        var imageList = [UIImageHDBoundle(named: "icon_delete"), UIImageHDBoundle(named: "icon_share"), UIImageHDBoundle(named: "icon_decrypt"), UIImageHDBoundle(named: "icon_search"), UIImageHDBoundle(named: "icon_analyse")]

        if DDLoggerSwift.uploadComplete != nil {
            titleList.append("Upload".ZXLocaleString)
            imageList.append(UIImageHDBoundle(named: "icon_upload"))
        }

        for i in 0..<titleList.count {
            let model = DDLoggerSwiftMenuCollectionViewCellModel(title: titleList[i], image: imageList[i])
            mCollectionList.append(model)
        }
        self.mCollectionView.reloadData()
    }
}

extension DDLoggerSwiftMenuView: UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //MARK:collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mCollectionList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = self.mCollectionList[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DDLoggerSwiftMenuCollectionViewCell", for: indexPath) as! DDLoggerSwiftMenuCollectionViewCell
        cell.updateUI(model: model)
        cell.tag = indexPath.item
        cell.switchSubject = {  (tag, isOn) in
            
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let clickSubject = clickSubject {
            clickSubject(indexPath.item)
        }
    }
}
