//
//  DDLoggerSwiftItem.swift
//  DDLoggerSwiftSwift
//
//  Created by Damon on 2020/6/10.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit
import DDUtils

let t = Date()

enum Section: CaseIterable {
    case main
}
///log的内容
public class DDLoggerSwiftItem {
    let identifier = UUID()                                 //用于hash计算
    var databaseID: Int = 0                                 //存在database的id
    public var mLogItemType = DDLogType.debug             //log类型
    public var mLogFile: String = ""                        //log调用的文件
    public var mLogLine: String = ""                        //log调用的行数
    public var mLogFunction: String = ""                    //log调用的函数名
    public var mLogContent: Any? = "DDLoggerSwift: Click Log To Copy"  //log的内容
    public var mCreateDate = t                      //log日期
    
    private var mCurrentHighlightString = ""            //当前需要高亮的字符串
    private var mCacheHasHighlightString = false        //上次查询是否包含高亮的字符串
    private var mCacheHighlightCompleteString = NSMutableAttributedString(string: "")   //上次包含高亮支付的富文本
}

public extension DDLoggerSwiftItem {
    func icon() -> String {
        switch mLogItemType {
        case .info:
            return "✅"
        case .warn:
            return "⚠️"
        case .error:
            return "❌"
        case .privacy:
            return "⛔️"
        default:
            return "💜"
        }
    }
    
    func level() -> String {
        switch mLogItemType {
        case .info:
            return "INFO"
        case .warn:
            return "WARN"
        case .error:
            return "ERROR"
        case .privacy:
            return "PRIVACY"
        default:
            return "DEBUG"
        }
    }
    
    //LogContent转字符串格式化
    func getLogContent() -> String {
        var contentString = ""
        if let mContent = mLogContent  {
            if mContent is LogContent {
                contentString = (mContent as! LogContent).logStringValue
            } else {
                contentString = "\(mContent)"
            }
            if self.mLogItemType == .privacy {
                contentString = contentString.dd.aesCBCEncrypt(password: DDLoggerSwift.privacyLogPassword, ivString: DDLoggerSwift.privacyLogIv, encodeType: DDLoggerSwift.privacyResultEncodeType) ?? "Invalid encryption".ZXLocaleString
            }
        }
        return contentString
    }
    
    //获取完整的输出内容
     func getFullContentString() -> String {
        //日期
         let dateStr = DDLoggerSwift.dateFormatterISO8601.string(from: mCreateDate)
        //所有的内容
         return "\(self.icon())" + " " + "[\(dateStr)]" + " " + "[\(self.level())]" + " " +  "File: \(mLogFile) | Line: \(mLogLine) | Function: \(mLogFunction) " + "\n---------------------------------\n" + self.getLogContent() + "\n"
    }
    
    //根据需要高亮内容查询组装高亮内容
    func getHighlightAttributedString(contentString: String, highlightString: String, complete:(Bool, NSAttributedString)->Void) -> Void {
        if highlightString.isEmpty {
            //空的直接返回
            let newString = NSMutableAttributedString(string: contentString, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13)])
            self.mCacheHighlightCompleteString = newString
            self.mCacheHasHighlightString = false
            complete(self.mCacheHasHighlightString, newString)
        } else if highlightString == self.mCurrentHighlightString{
            //和上次高亮相同，直接用之前的回调
            complete(self.mCacheHasHighlightString, self.mCacheHighlightCompleteString)
        } else {
            self.mCurrentHighlightString = highlightString
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

extension DDLoggerSwiftItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func ==(lhs: DDLoggerSwiftItem, rhs: DDLoggerSwiftItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func contains(query: String?) -> Bool {
        guard let query = query else { return true }
        guard !query.isEmpty else { return true }
        return self.getFullContentString().contains(query)
    }
}
