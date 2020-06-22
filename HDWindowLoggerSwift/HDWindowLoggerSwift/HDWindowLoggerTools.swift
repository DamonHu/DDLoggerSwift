//
//  HDWindowLoggerTools.swift
//  HDWindowLoggerSwift
//
//  Created by Damon on 2020/6/10.
//  Copyright © 2020 Damon. All rights reserved.
//

import UIKit
import CommonCrypto

class HDWindowLoggerTools: NSObject {
    let ivString = "abcdefghijklmnop";
    
    //AES256加密
    func AES256Encrypt(text: String, password: String) -> String {
        guard let data = text.data(using:String.Encoding.utf8) else { return "" }
        let encryptData = self.p_crypt(data: data, password: password, option: CCOperation(kCCEncrypt))
        return encryptData.base64EncodedString()
    }
    
    //AES256解密
    func AES256Decrypt(text: String, password: String) -> String {
        guard let data = Data(base64Encoded: text) else { return "" }
        let encryptData = self.p_crypt(data: data, password: password, option: CCOperation(kCCDecrypt))
        return String(data: encryptData, encoding: String.Encoding.utf8) ?? ""
    }
    
    func p_crypt(data: Data, password: String, option: CCOperation) -> Data {
        guard let iv = ivString.data(using:String.Encoding.utf8) else { return Data() }
        guard let key = password.data(using:String.Encoding.utf8) else { return Data() }
        
        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData   = Data(count: cryptLength)
        
        let keyLength = kCCKeySizeAES256
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        var bytesLength = Int(0)
        
        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, keyBytes.baseAddress, keyLength, ivBytes.baseAddress, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
                    }
                }
            }
        }
        
        guard UInt32(status) == UInt32(kCCSuccess) else {
            return Data()
        }
        
        cryptData.removeSubrange(bytesLength..<cryptData.count)
        return cryptData
    }
}
