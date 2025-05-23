//
//  Data+dd.swift
//  DDUtils
//
//  Created by Damon on 2021/5/31.
//  Copyright © 2021 Damon. All rights reserved.
//

import Foundation
import CommonCrypto
#if canImport(CryptoKit)
import CryptoKit
#endif

public enum DDUtilsHashType {
    case md5
    case sha1
    case sha224
    case sha256
    case sha384
    case sha512
}

public enum DDUtilsEncodeType {
    case hex
    case base64
    case system(String.Encoding)
}

extension Data: DDUtilsNameSpaceWrappable {
    
}

public extension DDUtilsNameSpace where T == Data {
    //string生成Data，兼容hex和base64
    static func data(from string: String, encodeType: DDUtilsEncodeType) -> Data? {
        switch encodeType {
            case .hex:
                let len = string.count / 2
                var data = Data(capacity: len)
                var i = string.startIndex
                for _ in 0..<len {
                    let j = string.index(i, offsetBy: 2)
                    let bytes = string[i..<j]
                    if var num = UInt8(bytes, radix: 16) {
                        data.append(&num, count: 1)
                    } else {
                        return nil
                    }
                    i = j
                }
                return data
            case .base64:
                return Data(base64Encoded: string)
            case .system(let encode):
                return string.data(using: encode)
        }
    }

    //编码
    func encodeString(encodeType: DDUtilsEncodeType) -> String? {
        switch encodeType {
            case .hex:
                return object.map { String(format: "%02hhx", $0) }.joined()
            case .base64:
                return object.base64EncodedString()
            case .system(let encode):
                return String(data: object, encoding: encode)
        }
    }

    ///hash计算
    func hashString(hashType: DDUtilsHashType, lowercase: Bool = true) -> String {
        var output = NSMutableString()
        switch hashType {
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
        }

        if !lowercase {
            return String(output).uppercased()
        }
        return String(output)
    }

    /*
     AES CBC加密
     model: CBC
     padding: PKCS7Padding
     AES block Size: 128
     **/
    func aesCBCEncrypt(password: String, ivString: String = "abcdefghijklmnop", encodeType: DDUtilsEncodeType = .base64) -> String? {
        guard let iv = ivString.data(using: .utf8), let key = password.data(using: .utf8) else { return nil }
        assert(iv.count == kCCKeySizeAES128, "iv should be \(kCCKeySizeAES128) bytes")
        assert(key.count == kCCKeySizeAES128 || key.count == kCCKeySizeAES192 || key.count == kCCKeySizeAES256, "Invalid key length. Available length is \(kCCKeySizeAES128) \(kCCKeySizeAES192) \(kCCKeySizeAES256)")
        let encryptData = self._crypt(data: object, key: key, iv: iv, option: CCOperation(kCCEncrypt))
        return encryptData?.dd.encodeString(encodeType: encodeType)
    }
    
    ///AES CBC解密
    func aesCBCDecrypt(password: String, ivString: String = "abcdefghijklmnop") -> String? {
        guard let iv = ivString.data(using: .utf8), let key = password.data(using: .utf8) else { return nil }
        assert(iv.count == kCCKeySizeAES128, "iv should be \(kCCKeySizeAES128) bytes")
        assert(key.count == kCCKeySizeAES128 || key.count == kCCKeySizeAES192 || key.count == kCCKeySizeAES256, "Invalid key length. Available length is \(kCCKeySizeAES128) \(kCCKeySizeAES192) \(kCCKeySizeAES256)")
        guard let encryptData = self._crypt(data: object, key: key, iv: iv, option: CCOperation(kCCDecrypt)) else {
            return nil
        }
        return String(data: encryptData, encoding: String.Encoding.utf8)
    }

    /**deprecated*/
    @available(*, deprecated, message: "Use hashString(hashType: DDUtilsHashType, lowercase: Bool) instead")
    func encryptString(encryType: DDUtilsHashType, lowercase: Bool = true) -> String {
        return self.hashString(hashType: encryType, lowercase: lowercase)
    }
}

#if canImport(CryptoKit)
@available(iOS 13.0, *)
public extension DDUtilsNameSpace where T == Data {
    //AES GCM加密
    func aesGCMEncrypt(password: String, encodeType: DDUtilsEncodeType = .base64, nonce: AES.GCM.Nonce? = AES.GCM.Nonce()) -> String? {
        assert(password.count == kCCKeySizeAES128 || password.count == kCCKeySizeAES192 || password.count == kCCKeySizeAES256, "Invalid key length. Available length is \(kCCKeySizeAES128) \(kCCKeySizeAES192) \(kCCKeySizeAES256)")
        return self.aesGCMEncrypt(key: SymmetricKey.init(data: password.data(using:String.Encoding.utf8)!), encodeType: encodeType, nonce: nonce)
    }

    ///AES GCM加密
    func aesGCMEncrypt(key: SymmetricKey, encodeType: DDUtilsEncodeType = .base64, nonce: AES.GCM.Nonce? = AES.GCM.Nonce()) -> String? {
        assert(key.bitCount / 8 == kCCKeySizeAES128 || key.bitCount / 8 == kCCKeySizeAES192 || key.bitCount / 8 == kCCKeySizeAES256, "Invalid key length. Available length is \(kCCKeySizeAES128) \(kCCKeySizeAES192) \(kCCKeySizeAES256)")
        guard let sealedBox = try? AES.GCM.seal(object, using: key, nonce:  nonce) else { return nil }
        guard let encode = sealedBox.combined else { return nil }
        return encode.dd.encodeString(encodeType: encodeType)
    }
    //AES GCM解密
    func aesGCMDecrypt(password: String) -> String? {
        assert(password.count == kCCKeySizeAES128 || password.count == kCCKeySizeAES192 || password.count == kCCKeySizeAES256, "Invalid key length. Available length is \(kCCKeySizeAES128) \(kCCKeySizeAES192) \(kCCKeySizeAES256)")
        let key = SymmetricKey.init(data: password.data(using:String.Encoding.utf8)!)
        return self.aesGCMDecrypt(key: key)
    }

    //AES GCM解密
    func aesGCMDecrypt(key: SymmetricKey) -> String? {
        assert(key.bitCount / 8 == kCCKeySizeAES128 || key.bitCount / 8 == kCCKeySizeAES192 || key.bitCount / 8 == kCCKeySizeAES256, "Invalid key length. Available length is \(kCCKeySizeAES128) \(kCCKeySizeAES192) \(kCCKeySizeAES256)")
        guard let sealedBox = try? AES.GCM.SealedBox.init(combined: object) else { return nil }
        guard let decry = try? AES.GCM.open(sealedBox, using: key) else { return nil }
        return String(decoding: decry, as: UTF8.self)
    }

    ///HMAC计算
    func hmac(hashType: DDUtilsHashType, password: String, encodeType: DDUtilsEncodeType = .base64) -> String? {
        let key = SymmetricKey.init(data: password.data(using:String.Encoding.utf8)!)
        return self.hmac(hashType: hashType, key: key, encodeType: encodeType)
    }

    ///HMAC计算
    func hmac(hashType: DDUtilsHashType, key: SymmetricKey, encodeType: DDUtilsEncodeType = .base64) -> String? {
        switch hashType {
            case .md5:
                let sign = HMAC<Insecure.MD5>.authenticationCode(for: object, using: key)
                return Data(sign).dd.encodeString(encodeType: encodeType)
            case .sha1:
                let sign = HMAC<Insecure.SHA1>.authenticationCode(for: object, using: key)
                return Data(sign).dd.encodeString(encodeType: encodeType)
            case .sha224:
                assert(false, "unsupported hash type")
                return nil
            case .sha256:
                let sign = HMAC<SHA256>.authenticationCode(for: object, using: key)
                return Data(sign).dd.encodeString(encodeType: encodeType)
            case .sha384:
                let sign = HMAC<SHA384>.authenticationCode(for: object, using: key)
                return Data(sign).dd.encodeString(encodeType: encodeType)
            case .sha512:
                let sign = HMAC<SHA512>.authenticationCode(for: object, using: key)
                return Data(sign).dd.encodeString(encodeType: encodeType)
        }
    }
}
#endif

private extension DDUtilsNameSpace where T == Data {
    func _crypt(data: Data, key: Data, iv: Data, option: CCOperation) -> Data? {
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


