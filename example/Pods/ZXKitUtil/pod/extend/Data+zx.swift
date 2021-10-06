//
//  Data+zx.swift
//  ZXKitUtil
//
//  Created by Damon on 2021/5/31.
//  Copyright © 2021 Damon. All rights reserved.
//

import Foundation
import CommonCrypto
#if canImport(CryptoKit)
import CryptoKit
#endif

public enum ZXKitUtilEncryType {
    case md5
    case sha1
    case sha224
    case sha256
    case sha384
    case sha512
    case base64
}

public enum ZXKitUtilEncodeType {
    case hex
    case base64
}

extension Data: ZXKitUtilNameSpaceWrappable {
    
}

public extension ZXKitUtilNameSpace where T == Data {
    ///data转hex字符串
    func hexEncodedString() -> String {
        return object.map { String(format: "%02hhx", $0) }.joined()
    }
    
    //hex生成Data
    static func data(hexString: String) -> Data? {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
          let j = hexString.index(i, offsetBy: 2)
          let bytes = hexString[i..<j]
          if var num = UInt8(bytes, radix: 16) {
            data.append(&num, count: 1)
          } else {
            return nil
          }
          i = j
        }
        return data
    }
    
    ///base64解码
    func base64Decode(lowercase: Bool = true) -> String? {
        guard let string = String(data: object, encoding: String.Encoding.utf8) else { return nil }
        return lowercase ? string.lowercased() : string.uppercased()
    }

    /*
     AES CBC加密
     model: CBC
     padding: PKCS7Padding
     AES block Size: 128
     **/
    func aesCBCEncrypt(password: String, ivString: String = "abcdefghijklmnop", encodeType: ZXKitUtilEncodeType = .base64) -> String? {
        assert(ivString.count == kCCKeySizeAES128, "iv should be 16bytes")
        assert(password.count == kCCKeySizeAES128 || password.count == kCCKeySizeAES192 || password.count == kCCKeySizeAES256, "Invalid key length")
        let encryptData = self._crypt(data: object, password: password, ivString: ivString, option: CCOperation(kCCEncrypt))
        if encodeType == .base64 {
            return encryptData?.base64EncodedString()
        } else {
            return encryptData?.zx.hexEncodedString()
        }
    }
    
    ///AES CBC解密
    func aesCBCDecrypt(password: String, ivString: String = "abcdefghijklmnop") -> String? {
        assert(ivString.count == kCCKeySizeAES128, "iv should be 16bytes")
        assert(password.count == kCCKeySizeAES128 || password.count == kCCKeySizeAES192 || password.count == kCCKeySizeAES256, "Invalid key length")
        guard let encryptData = self._crypt(data: object, password: password, ivString: ivString, option: CCOperation(kCCDecrypt)) else {
            return nil
        }
        return String(data: encryptData, encoding: String.Encoding.utf8)
    }
    
    //AES GCM加密
    @available(iOS 13.0, *)
    func aesGCMEncrypt(password: String, encodeType: ZXKitUtilEncodeType = .base64) -> String? {
        assert(password.count == kCCKeySizeAES128 || password.count == kCCKeySizeAES192 || password.count == kCCKeySizeAES256, "Invalid key length")
        let key = SymmetricKey.init(data: password.data(using:String.Encoding.utf8)!)
        guard let sealedBox = try? AES.GCM.seal(object, using: key, nonce: nil) else { return nil }
        guard let encode = sealedBox.combined else { return nil }
        if encodeType == .base64 {
            return encode.base64EncodedString()
        } else {
            return encode.zx.hexEncodedString()
        }
    }
    
    //AES GCM解密
    @available(iOS 13.0, *)
    func aesGCMDecrypt(password: String) -> String? {
        assert(password.count == kCCKeySizeAES128 || password.count == kCCKeySizeAES192 || password.count == kCCKeySizeAES256, "Invalid key length")
        let key = SymmetricKey.init(data: password.data(using:String.Encoding.utf8)!)
        guard let sealedBox = try? AES.GCM.SealedBox.init(combined: object) else { return nil }
        guard let decry = try? AES.GCM.open(sealedBox, using: key) else { return nil }
        return String(decoding: decry, as: UTF8.self)
    }
    
    //MARK: 加密
    func encryptString(encryType: ZXKitUtilEncryType, lowercase: Bool = true) -> String {
        var output = NSMutableString()
        
        switch encryType {
        case .md5:
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            _ = object.withUnsafeBytes { (messageBytes) -> Bool in
                CC_MD5(messageBytes.baseAddress, CC_LONG(object.count), &digest)
                return true
            }

            output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH))
            for byte in digest{
                output.appendFormat("%02x", byte)
            }
        case .sha1:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            _ = object.withUnsafeBytes { (messageBytes) -> Bool in
                CC_SHA1(messageBytes.baseAddress, CC_LONG(object.count), &digest)
                return true
            }

            output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
            for byte in digest{
                output.appendFormat("%02x", byte)
            }
        case .sha224:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA224_DIGEST_LENGTH))
            _ = object.withUnsafeBytes { (messageBytes) -> Bool in
                CC_SHA224(messageBytes.baseAddress, CC_LONG(object.count), &digest)
                return true
            }

            output = NSMutableString(capacity: Int(CC_SHA224_DIGEST_LENGTH))
            for byte in digest{
                output.appendFormat("%02x", byte)
            }
        case .sha256:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = object.withUnsafeBytes { (messageBytes) -> Bool in
                CC_SHA256(messageBytes.baseAddress, CC_LONG(object.count), &digest)
                return true
            }

            output = NSMutableString(capacity: Int(CC_SHA256_DIGEST_LENGTH))
            for byte in digest{
                output.appendFormat("%02x", byte)
            }
        case .sha384:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
            _ = object.withUnsafeBytes { (messageBytes) -> Bool in
                CC_SHA384(messageBytes.baseAddress, CC_LONG(object.count), &digest)
                return true
            }

            output = NSMutableString(capacity: Int(CC_SHA384_DIGEST_LENGTH))
            for byte in digest{
                output.appendFormat("%02x", byte)
            }
        case .sha512:
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            _ = object.withUnsafeBytes { (messageBytes) -> Bool in
                CC_SHA512(messageBytes.baseAddress, CC_LONG(object.count), &digest)
                return true
            }

            output = NSMutableString(capacity: Int(CC_SHA512_DIGEST_LENGTH))
            for byte in digest{
                output.appendFormat("%02x", byte)
            }
        case .base64:
            let base64Encoded:String = object.base64EncodedString()
            output = NSMutableString (string: base64Encoded)
        }
        
        if !lowercase {
            return String(output).uppercased()
        }
        return String(output)
    }
}

private extension ZXKitUtilNameSpace where T == Data {
    func _crypt(data: Data, password: String, ivString: String, option: CCOperation) -> Data? {
        guard let iv = ivString.data(using:String.Encoding.utf8) else { return nil }
        guard let key = password.data(using:String.Encoding.utf8) else { return nil }
        
        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData   = Data(count: cryptLength)

        let keyLength = key.count
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
            return nil
        }

        cryptData.removeSubrange(bytesLength..<cryptData.count)
        return cryptData
    }
}
