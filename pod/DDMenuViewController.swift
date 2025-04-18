//
//  MenuViewController.swift
//  DDLoggerSwift
//
//  Created by Damon on 2025/4/15.
//  Copyright © 2025 Damon. All rights reserved.
//

import UIKit
import DDUtils

class DDMenuViewController: UIViewController {
    var contentVC: DDContentViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self._createUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.contentVC = nil
    }
    
    func _createUI() {
        self.view.backgroundColor = UIColor.white
        //菜单view
        self.view.addSubview(self.mMenuView)
        self.mMenuView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.mMenuView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.mMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.mMenuView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }

    //MARK: UI
    private lazy var mMenuView: DDLoggerSwiftMenuView = {
        let tMenuView = DDLoggerSwiftMenuView()
        tMenuView.translatesAutoresizingMaskIntoConstraints = false
        tMenuView.clickSubject = {(index) -> Void in
            switch index {
                case 0:
                    DDLoggerSwift.cleanLog()
                    self.navigationController?.popViewController(animated: true)
                    break
                case 1:
                    DDLoggerSwift.showShare(isCloseWhenComplete: false)
                case 2:
                    self.contentVC?.isDecryptViewHidden = false
                    self.navigationController?.popViewController(animated: true)
                case 3:
                    DDLoggerSwift.fileSelectedComplete = { filePath, name in
                        self.contentVC?.dataBaseName = name
                        self.navigationController?.popViewController(animated: true)
                    }
                    DDLoggerSwift.showFileFilter()
                case 4:
                    let folder = DDLoggerSwift.getDBFolder()
                    let size = DDUtils.shared.getFileDirectorySize(fileDirectoryPth: folder)
                    //数据库条数
                    var count = 0
                    if let enumer = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [URLResourceKey.creationDateKey]) {
                        while let file = enumer.nextObject() {
                            if let file: URL = file as? URL, file.lastPathComponent.hasSuffix(".db") {
                               count = count + 1
                            }
                        }
                    }
                    let info = """

                        📅 \("Number of Today's Logs".ZXLocaleString): \(DDLoggerSwift.getItemCount(type: nil))

                        ✅ Info count: \(DDLoggerSwift.getItemCount(type: .info))

                        ⚠️ Warn count: \(DDLoggerSwift.getItemCount(type: .warn))

                        ❌ Error count: \(DDLoggerSwift.getItemCount(type: .error))

                        ⛔️ Privacy count: \(DDLoggerSwift.getItemCount(type: .privacy))

                        📊 \("LogFile count".ZXLocaleString): \(count)

                        📈 \("LogFile total size".ZXLocaleString): \(size/1024.0)kb
                    """
                    printWarn(info)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.contentVC?._resetData()
                        self.navigationController?.popViewController(animated: true)
                    }
                case 5:
                    DDLoggerSwift.showUpload(isCloseWhenComplete: false)
                default:
                    break
            }
        };
        return tMenuView
    }()

}
