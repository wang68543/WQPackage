//
//  Service.swift
//  WQPackage_Example
//
//  Created by HuaShengiOS on 2019/2/21.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import Moya
final class Plugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var mRequest = request
        mRequest.timeoutInterval = 10///超时
        return mRequest
    }
}
private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data //fallback to original data if it cant be serialized
    }
}
fileprivate func defaultRequestMapping(for endpoint: Endpoint, closure: MoyaProvider<HandMetro>.RequestResultClosure) {
    do {
        var urlRequest = try endpoint.urlRequest()
        // 加密参数
        urlRequest.httpBody = Data()
        //设置超时时间
        closure(.success(urlRequest))
    } catch MoyaError.requestMapping(let url) {
        closure(.failure(MoyaError.requestMapping(url)))
    } catch MoyaError.parameterEncoding(let error) {
        closure(.failure(MoyaError.parameterEncoding(error)))
    } catch {
        closure(.failure(MoyaError.underlying(error, nil)))
    }
}

//let metroProvider = MoyaProvider<HandMetro>()//
let metroProvider = MoyaProvider<HandMetro>(requestClosure: defaultRequestMapping,plugins: [NetworkLoggerPlugin(verbose: false),Plugin()])//

// MARK: - Provider support
public enum HandMetro {
    case spList(ptype:Int)
    case metroCitylist
    case metroCityListByType(ctype: Int)
    case metroCityInfo(cityId: Int)
    case metroCityInfoByCityCode(cityCode: String)
    case metroInfo(cityId: Int,datatime: Int,mapid: Int)
    case nearByStation(longitude: Double,latitude: Double,cityId: Int)
    case metroStationInfo(stationId: Int)
    case metroStationPath(bstatid: Int,estatid: Int, datatime: Int, startPoi: [String: Any]?, endPoi: [String: Any]?)
    case metroCrowd(lineid: Int,statid: Int,destname:String)
    case citymaplist
    case sendCode(uphone: String)
    case smsLogin(uphone: String,smscode: String)
    case exitsnearby(parmas: [String: Any])
}
extension HandMetro: TargetType {
    
    public var path: String {
        var relativePath : String
        switch self {
        case .spList:
            relativePath = "spshow/splist"
        case .metroCitylist:
            relativePath = "metro/citylist"
        case .metroCityListByType:
            relativePath = "metro/citymetrolist"
        case .metroCityInfo:
            relativePath = "metro/cityinfo"
        case .metroCityInfoByCityCode:
            relativePath = "metro/cityinfobycode"
        case .metroInfo:
            relativePath = "metro/metroinfo"
        case .nearByStation:
            relativePath = "metro/nearbystat"
        case .metroStationInfo:
            relativePath = "metro/statinfo"
        case .metroStationPath:
            relativePath = "metro/statpath"
        case .metroCrowd:
            relativePath = "metro/getcrowd"
        case .citymaplist:
            relativePath = "metro/citymaplist"
        case .sendCode:
            relativePath = "account/sendcode"
        case .smsLogin:
            relativePath = "account/smslogin"
        case .exitsnearby:
            relativePath = "metro/exitsnearby"
        }
        return "/api/" + relativePath
    }
    
    public var task: Task {
        var dData: [String: Any] = [:]
        switch self {
        case .metroCitylist:
            break;
        case .spList(let ptype):
            dData["ptype"] = ptype
        case .metroCityInfo(let cityId):
            dData["cityid"] = cityId
        case .metroCityListByType(let ctype):
            dData["ctype"] = ctype
        case .metroCityInfoByCityCode(let cityCode):
            dData["citycode"] = cityCode
        case .metroInfo(let cityId, let datatime, let mapid):
            dData["cityid"] = cityId
            dData["datatime"] = datatime
            dData["mapid"] = mapid
        case .nearByStation(let longitude, let latitude, let cityId):
            dData["longitude"] = longitude
            dData["latitude"] = latitude
            dData["cityid"] = cityId
        case .metroStationInfo(let stationId):
            dData["statid"] = stationId
        case .metroStationPath(let bstatid, let estatid, let datatime, let startPoi, let endPoi):
            dData["bstatid"] = bstatid
            dData["estatid"] = estatid
            dData["datatime"] = datatime
            if let end = endPoi {
                dData["epoi"] = end
            }
            if let start = startPoi {
                dData["bpoi"] = start
            }
        case .metroCrowd(let lineid, let statid, let destname):
            dData["lineid"] = lineid
            dData["statid"] = statid
            dData["destname"] = destname
        case .sendCode(let uphone):
            dData["uphone"] = uphone
        case .smsLogin(let uphone,let smscode):
            dData["uphone"] = uphone
            dData["smscode"] = smscode
        case .exitsnearby(let parmas):
            dData.merge(parmas){ (_, new) in new }
        default:
            break;
        }
        return .requestData(formatRequestData(dData) ?? Data())
    }
    
    
    public var baseURL: URL { return URL(string: "http://metro.wifi8.com")! }
    
    public var method: Moya.Method {
        //        switch self {
        
        return .post
    }
    public var validationType: ValidationType {
        switch self {
        case .spList:
            return .successCodes
        default:
            return .none
        }
    }
    public var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
    public var headers: [String: String]? {
        var headerParam:[String:String] = [:]
        headerParam = ["Content-Type":"application/json"]
        //        switch self {
        //        case .uploadFile:
        //            headerParam = ["Content-Type":"multipart/form-data"]
        //        default:
        //            headerParam = ["Content-Type":"application/json"]
        //        }
        headerParam["vcode"] = "HMUtils.appVersion()"                   // string    Yes    APP版本号
        headerParam["bcode"] = "HMUtils.appBuildVersion()"              // int    Yes    APP编译号
        headerParam["ucode"] = "HMUtils.deviceId()"                     // string    Yes    设备值 终端唯一标识
        headerParam["ptype"] = "\(2)"                               // int    Yes    操作系统 1=安卓、2=苹果
        headerParam["timestamp"] = "\(Date().timeIntervalSince1970)"                // 时间
        return headerParam
    }
    
}
extension HandMetro {
    static func encrypted(_ data: Data) throws -> Data {
        return Data()
        //        do {
        //            let aes = try AES(key: HMConst.aesKey.bytes, blockMode:ECB())
        //            let encryptData = try aes.encrypt(data.bytes).toBase64()?.data(using: .utf8)
        //            if let encrypt = encryptData {
        //                return encrypt
        //            } else {
        //                throw NSError(domain: "HMMPI", code: -200, userInfo: [NSLocalizedDescriptionKey: "数据加密失败"]) as Error
        //            }
        //        } catch let error {
        //            throw error
        //        }
    }
    
    
    public func formatRequestData(_ dData: [String : Any]) -> Data? {
        // 加入baseInfo参数
        var sendParam:[String:Any] = [:]
        var _hdata = self.hData
        var _ddata = dData
        let servid = _ddata["servid"]
        if (servid != nil) {
            _ddata["servid"] = nil
            _hdata["servid"] = servid
        }
        
        sendParam["_hdata"] = _hdata
        sendParam["_ddata"] = _ddata
        var sendData: Data?
        do {
            sendData = try JSONSerialization.data(withJSONObject: sendParam, options: [])
            if let data = sendData {
                sendData = try HandMetro.encrypted(data)
            }
        } catch let error {
            debugPrint("参数s序列化失败\(error)")
        }
        return sendData
    }
    
    public var hData:[String: Any]{
        var param = ["mfrs":"apple"]                                            // string    No    手机厂商
        param["channo"] = "AppStore"                                                 // string    No    渠道号
        param["pushid"] = ""                                                  // string    NO    push token
        param["utoken"] = "UserDefaults.uToken"                                                    // string    No    用户Token
        param["citycode"] =  ""                                                 // string    No    城市编码
        param["idfa"] = "HMConst.idfa"                                          // string    No    IOS idfa
        param["idfv"] = "HMConst.idfv"                                           // string    No    IOS idfv
        param["mac"] = ""                                                       // string    No    设备MAC 格式为00:00:00:00:00:00 小写
        param["imei"] = ""                                                      // string    No    国际移动设备标识
        param["imsi"] = ""                                                      // string    No    国际移动用户识别码
        param["model"] = UIDevice.current.model                                       // string    No    手机型号
        param["noncestr"] = "HMUtils.randomString()"                               // string    No    随机字符串
        param["servid"] = "0"                                                   // int    Yes    API 版本号
        
        param["mapid"] = "0" //地图id
        param["cityid"] = "0" //城市id
        
        
        return param
    }
}

fileprivate let networkQueue: DispatchQueue = DispatchQueue(label: "HMAPI.network")

