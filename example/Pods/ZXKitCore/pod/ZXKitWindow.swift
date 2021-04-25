//
//  ZXKitWindow.swift
//  ZXKit
//
//  Created by Damon on 2021/4/23.
//

import UIKit

class ZXKitWindow: UIWindow {

    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self._initVC()
        self._createUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self._initVC()
        self._createUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: UI
    lazy var mCollectionView: UICollectionView = {
        let tCollectionViewLayout = UICollectionViewFlowLayout()
        tCollectionViewLayout.itemSize = CGSize(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.width / 4)
        tCollectionViewLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        tCollectionViewLayout.minimumLineSpacing = 0
        tCollectionViewLayout.minimumInteritemSpacing = 0
        tCollectionViewLayout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 40)
        let tCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: tCollectionViewLayout)
        tCollectionView.contentInsetAdjustmentBehavior = .never
        tCollectionView.backgroundColor = UIColor.clear
        tCollectionView.dataSource = self
        tCollectionView.delegate = self
        tCollectionView.isPagingEnabled = false
        tCollectionView.showsHorizontalScrollIndicator = false
        tCollectionView.register(ZXKitPluginCollectionViewCell.self, forCellWithReuseIdentifier: "ZXKitPluginCollectionViewCell")
        tCollectionView.register(ZXKitCollectionViewHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "ZXKitCollectionViewHeaderView")
        return tCollectionView
    }()
}

extension ZXKitWindow {
    func reloadData() {
        self.mCollectionView.reloadData()
    }
}

extension ZXKitWindow: UICollectionViewDelegate,UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return ZXKit.pluginList.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ZXKit.pluginList[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let plugin = ZXKit.pluginList[indexPath.section][indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZXKitPluginCollectionViewCell", for: indexPath) as! ZXKitPluginCollectionViewCell
        cell.updateUI(plugin: plugin)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let title = [NSLocalizedString("UI", comment: ""), NSLocalizedString("Data", comment: ""), NSLocalizedString("Other", comment: "")]
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ZXKitCollectionViewHeaderView", for: indexPath) as! ZXKitCollectionViewHeaderView
        cell.updateUI(title: title[indexPath.section])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let plugin = ZXKit.pluginList[indexPath.section][indexPath.item]
        ZXKit.hide()
        plugin.start()
    }
}

private extension ZXKitWindow {

    func _initVC() {
        self.backgroundColor = UIColor.zx.color(hexValue: 0xfcecdd, alpha: 0.6)
        let rootViewController = UIViewController()

        let navigation = UINavigationController(rootViewController: rootViewController)
        navigation.navigationBar.barTintColor = UIColor.white
        //set title
        let view = UIView()
        let label = UILabel()
        label.attributedText = NSAttributedString(string: "ZXKIT", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 18, weight: .medium), NSAttributedString.Key.foregroundColor:UIColor.black])
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        rootViewController.navigationItem.titleView = view
        //navigationBar
        let leftBarItem = UIBarButtonItem(title: NSLocalizedString("close", comment: ""), style: .plain, target: self, action: #selector(_leftBarItemClick))
        rootViewController.navigationItem.leftBarButtonItem = leftBarItem
        let rightBarItem = UIBarButtonItem(title: NSLocalizedString("hide", comment: ""), style: .plain, target: self, action: #selector(_rightBarItemClick))
        rootViewController.navigationItem.rightBarButtonItem = rightBarItem
        //
        self.rootViewController = navigation
        self.windowLevel =  UIWindow.Level.alert
        self.isUserInteractionEnabled = true
    }

    @objc func _leftBarItemClick() {
        ZXKit.close()
    }

    @objc func _rightBarItemClick() {
        ZXKit.hide()
    }

    func _createUI() {
        guard let navigationController = self.rootViewController as? UINavigationController, let rootViewController = navigationController.topViewController else {
            return
        }

        rootViewController.view.addSubview(mCollectionView)
        mCollectionView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(rootViewController.view.safeAreaLayoutGuide.snp.top)
            $0.bottom.equalTo(rootViewController.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}
