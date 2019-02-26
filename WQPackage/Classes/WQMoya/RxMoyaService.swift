//
//  RxMoyaService.swift
//  Pods
//
//  Created by HuaShengiOS on 2019/2/21.
//

import Foundation
//import UIKit
import Moya
import RxSwift
//public protocol RxMoyaTargetType: TargetType {
//    associatedtype Response: Decodable
//}
open class MoyaDecoder<Element> {
    public init() {
        // using default init 
    }
    /// 响应模型
    open func responseSerialization(for request: URLRequest?, response: Moya.Response) throws -> Element {
        fatalError("必须子类实现")
    }
}
open class RxMoyaService<API: TargetType> {
    public let provider: MoyaProvider<API>
    public init(_ provider: MoyaProvider<API>) {
        self.provider = provider
    }
    /// 自定义模型解析 解决对象里面包含Any 无法使用Codable 自动转换
    public func request<Element>(_ token: API, decoder: MoyaDecoder<Element>, callbackQueue: DispatchQueue? = nil) -> Single<Element> {
        return Single.create { [weak self] single in
            let cancellableToken = self?.provider.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    do {
                        let model: Element = try decoder.responseSerialization(for: response.request, response: response)
                        single(.success(model))
                    } catch let error {
                        debugPrint("转换失败\(error.localizedDescription)")
                        single(.error(MoyaError.objectMapping(error, response)))
                    }
                case let .failure(error):
                    single(.error(error))
                }
            }
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }
    /// 整个对象都是支持Codable
    public func request<T: Decodable>(_ token: API, callbackQueue: DispatchQueue? = nil, atKeyPath keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder(), failsOnEmptyData: Bool = true) -> Single<T> {
        return Single.create { [weak self] single in
            let cancellableToken = self?.provider.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                do {
                    let model = try response.map(T.self, atKeyPath: keyPath, using: decoder, failsOnEmptyData: failsOnEmptyData)
                    single(.success(model))
                }catch let DecodingError.dataCorrupted(context) {
                    debugPrint(context)
                    let error = DecodingError.dataCorrupted(context)
                    single(.error(MoyaError.objectMapping(error, response)))
                } catch let DecodingError.keyNotFound(key, context) {
                    debugPrint("Key '\(key)' not found:", context.debugDescription)
                    debugPrint("codingPath:", context.codingPath)
                    let error = DecodingError.keyNotFound(key, context)
                    single(.error(MoyaError.objectMapping(error, response)))
                } catch let DecodingError.valueNotFound(value, context) {
                    debugPrint("Value '\(value)' not found:", context.debugDescription)
                    debugPrint("codingPath:", context.codingPath)
                    let error = DecodingError.valueNotFound(value, context)
                    single(.error(MoyaError.objectMapping(error, response)))
                } catch let DecodingError.typeMismatch(type, context)  {
                    debugPrint("Type '\(type)' mismatch:", context.debugDescription)
                    debugPrint("codingPath:", context.codingPath)
                    let error = DecodingError.typeMismatch(type, context)
                    single(.error(MoyaError.objectMapping(error, response)))
                }  catch let error {
                    debugPrint("转换失败\(error.localizedDescription)")
                    single(.error(MoyaError.objectMapping(error, response)))
                }
                case let .failure(error):
                    single(.error(error))
                }
            }
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }
    /// 直接响应为Json
    public func requestJSON(_ token: API, callbackQueue: DispatchQueue? = nil) -> Single<Any> {
        return Single.create { [weak self] single in
            let cancellableToken = self?.provider.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    do {
                        let json = try response.mapJSON()
                        single(.success(json))
                    } catch let error {
                        debugPrint("转换失败\(error.localizedDescription)")
                        single(.error(MoyaError.jsonMapping(response)))
                    }
                case let .failure(error):
                    single(.error(error))
                }
            }
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }
    /// Designated request-making method with progress.
    public func requestWithProgress(_ token: API, callbackQueue: DispatchQueue? = nil) -> Observable<ProgressResponse> {
        let progressBlock: (AnyObserver) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.onNext(progress)
            }
        }
        
        let response: Observable<ProgressResponse> = Observable.create { [weak self] observer in
            let cancellableToken = self?.provider.request(token, callbackQueue: callbackQueue, progress: progressBlock(observer)) { result in
                switch result {
                case .success:
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
        
        // Accumulate all progress and combine them when the result comes
        return response.scan(ProgressResponse()) { last, progress in
            let progressObject = progress.progressObject ?? last.progressObject
            let response = progress.response ?? last.response
            return ProgressResponse(progress: progressObject, response: response)
        }
    }
}
//public extension Data {
//    public func mapObject<D: Decoder>(_ type: D.Type, atKeyPath keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder(), failsOnEmptyData: Bool = true) {
//        do {
//            let model = try response.map(T.self, atKeyPath: keyPath, using: decoder, failsOnEmptyData: failsOnEmptyData)
//            single(.success(model))
//        }catch let DecodingError.dataCorrupted(context) {
//            debugPrint(context)
//            let error = DecodingError.dataCorrupted(context)
//            single(.error(MoyaError.objectMapping(error, response)))
//        } catch let DecodingError.keyNotFound(key, context) {
//            debugPrint("Key '\(key)' not found:", context.debugDescription)
//            debugPrint("codingPath:", context.codingPath)
//            let error = DecodingError.keyNotFound(key, context)
//            single(.error(MoyaError.objectMapping(error, response)))
//        } catch let DecodingError.valueNotFound(value, context) {
//            debugPrint("Value '\(value)' not found:", context.debugDescription)
//            debugPrint("codingPath:", context.codingPath)
//            let error = DecodingError.valueNotFound(value, context)
//            single(.error(MoyaError.objectMapping(error, response)))
//        } catch let DecodingError.typeMismatch(type, context)  {
//            debugPrint("Type '\(type)' mismatch:", context.debugDescription)
//            debugPrint("codingPath:", context.codingPath)
//            let error = DecodingError.typeMismatch(type, context)
//            single(.error(MoyaError.objectMapping(error, response)))
//        }  catch let error {
//            debugPrint("转换失败\(error.localizedDescription)")
//            single(.error(MoyaError.objectMapping(error, response)))
//        }
//    }
//}
extension ObservableType where E == Response {
    /// Maps data received from the signal into a JSON object. If the conversion fails, the signal errors.
    public func mapJSON(failsOnEmptyData: Bool = true) -> Observable<Any> {
        return flatMap { Observable.just(try $0.mapJSON(failsOnEmptyData: failsOnEmptyData)) }
    }
    
    /// Maps received data at key path into a String. If the conversion fails, the signal errors.
    public func mapString(atKeyPath keyPath: String? = nil) -> Observable<String> {
        return flatMap { Observable.just(try $0.mapString(atKeyPath: keyPath)) }
    }
    
    /// Maps received data at key path into a Decodable object. If the conversion fails, the signal errors.
    public func map<D: Decodable>(_ type: D.Type, atKeyPath keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder(), failsOnEmptyData: Bool = true) -> Observable<D> {
        return flatMap { Observable.just(try $0.map(type, atKeyPath: keyPath, using: decoder, failsOnEmptyData: failsOnEmptyData)) }
    }
}
