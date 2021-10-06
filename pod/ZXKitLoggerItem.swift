//
//  ZXKitLoggerItem.swift
//  ZXKitLoggerSwift
//
//  Created by Damon on 2020/6/10.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit
import CommonCrypto
import ZXKitUtil

enum Section: CaseIterable {
    case main
}
///log的内容
public class ZXKitLoggerItem {
    let identifier = UUID()                                 //用于hash计算
    public var mLogItemType = ZXKitLogType.info             //log类型
    public var mLogDebugContent: String = ""              //log输出的文件、行数、函数名
    public var mLogContent: Any?                         //log的内容
    public var mCreateDate = Date()                      //log日期
    
    private var mCurrentHighlightString = ""            //当前需要高亮的字符串
    private var mCacheHasHighlightString = false        //上次查询是否包含高亮的字符串
    var mCacheHighlightCompleteString = NSMutableAttributedString()   //上次包含高亮支付的富文本
    
    //获取完整的输出内容
    public func getFullContentString() -> String {
        //日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let dateStr = dateFormatter.string(from: mCreateDate)
        //内容
        var contentString = ""
        if let mContent = mLogContent  {
            if mContent is LogContent {
                contentString = (mContent as! LogContent).logStringValue
            } else {
                contentString = "\(mContent)"
            }
            if self.mLogItemType == .privacy {
                contentString = contentString.zx.aesCBCEncrypt(password: ZXKitLogger.privacyLogPassword, ivString: ZXKitLogger.privacyLogIv, encodeType: ZXKitLogger.privacyResultEncodeType) ?? "Invalid encryption".ZXLocaleString
            }
        }
        
        if ZXKitLogger.isFullLogOut {
            switch mLogItemType {
                case .info:
                    return dateStr + " ---- ✅✅ ---- " +  mLogDebugContent + "\n" + contentString + "\n"
                case .warn:
                    return dateStr + " ---- ⚠️⚠️ ---- " +  mLogDebugContent + "\n" + contentString + "\n"
                case .error:
                    return dateStr + " ---- ❌❌ ---- " +  mLogDebugContent + "\n" + contentString + "\n"
                case .privacy:
                    return dateStr + " ---- ⛔️⛔️ ---- " +  mLogDebugContent + "\n" + contentString + "\n"
                default:
                    return dateStr + " ---- 💜💜 ---- " +  mLogDebugContent + "\n" + contentString + "\n"
            }
        } else {
            switch mLogItemType {
                case .info:
                    return dateStr + " ---- ✅✅ ---- " + "\n" + contentString + "\n"
                case .warn:
                    return dateStr + " ---- ⚠️⚠️ ---- " + "\n" + contentString + "\n"
                case .error:
                    return dateStr + " ---- ❌❌ ---- " + "\n" + contentString + "\n"
                case .privacy:
                    return dateStr + " ---- ⛔️⛔️ ---- " + "\n" + contentString + "\n"
                default:
                    return dateStr + " ---- 💜💜 ---- " + "\n" + contentString + "\n"
            }
        }
    }
    
    //根据需要高亮内容查询组装高亮内容
    public func getHighlightAttributedString(highlightString: String, complete:(Bool, NSAttributedString)->Void) -> Void {
        if highlightString.isEmpty {
            //空的直接返回
            let contentString = self.getFullContentString()
            let newString = NSMutableAttributedString(string: contentString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13)])
            self.mCacheHighlightCompleteString = newString
            self.mCacheHasHighlightString = false
            complete(self.mCacheHasHighlightString, newString)
        } else if highlightString == self.mCurrentHighlightString{
            //和上次高亮相同，直接用之前的回调
            complete(self.mCacheHasHighlightString, self.mCacheHighlightCompleteString)
        } else {
            self.mCurrentHighlightString = highlightString
            let contentString = self.getFullContentString()
            let newString = NSMutableAttributedString(string: contentString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13)])
            let regx = try? NSRegularExpression(pattern: highlightString, options: NSRegularExpression.Options.caseInsensitive)
            if let searchRegx = regx {
                self.mCacheHasHighlightString = false;
                searchRegx.enumerateMatches(in: contentString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: contentString.count)) { (result: NSTextCheckingResult?, flag, stop) in
                    newString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 255.0/255.0, green: 0.0, blue: 0.0, alpha: 1.0), range: result?.range ?? NSRange(location: 0, length: 0))
                    if result != nil {
                        self.mCacheHasHighlightString = true
                    }
                    self.mCacheHighlightCompleteString = newString
                    complete(self.mCacheHasHighlightString, newString)
                }
            } else {
                self.mCacheHighlightCompleteString = newString
                self.mCacheHasHighlightString = false
                complete(self.mCacheHasHighlightString, newString)
            }
        }
    }
}

extension ZXKitLoggerItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func ==(lhs: ZXKitLoggerItem, rhs: ZXKitLoggerItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func contains(query: String?) -> Bool {
        guard let query = query else { return true }
        guard !query.isEmpty else { return true }
        return self.getFullContentString().contains(query)
    }
}
