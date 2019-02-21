//
//  RxMoyaService.swift
//  Pods
//
//  Created by HuaShengiOS on 2019/2/21.
//

import Foundation
import Moya
import RxSwift
//public protocol RxMoyaTargetType: TargetType {
//    associatedtype Response: Decodable
//}
open class RxMoyaService<API: TargetType> {
    public let provider: MoyaProvider<API>
    public init(_ provider: MoyaProvider<API>) {
        self.provider = provider
    }
   public func request(_ token: API, callbackQueue: DispatchQueue? = nil) -> Single<Response> {
        return Single.create { [weak self] single in
            let cancellableToken = self?.provider.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    single(.success(response))
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

