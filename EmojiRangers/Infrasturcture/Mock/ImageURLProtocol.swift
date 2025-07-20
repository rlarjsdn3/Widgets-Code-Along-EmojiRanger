//
//  ImageURLProtocol.swift
//  EmojiRangers
//
//  Created by 김건우 on 7/18/25.
//

import Foundation

final class ImageURLProtocol: URLProtocol {

    var cancellOrCompleted: Bool = false
    var block: DispatchWorkItem!

    private static let queue = DispatchQueue(label: "com.apple.imageLoderURLProtoocl")

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return false
    }

    override func startLoading() {
        guard let requestUrl = request.url,
              let urlClient = client
        else { return }

        block = DispatchWorkItem(block: {
            if !self.cancellOrCompleted {
                let fileURL = URL(filePath: requestUrl.path())

                if let data = try? Data(contentsOf: fileURL) {
                    urlClient.urlProtocol(self, didLoad: data)
                    urlClient.urlProtocolDidFinishLoading(self)
                }
                self.cancellOrCompleted = true
            }
        })

        ImageURLProtocol.queue.asyncAfter(
            deadline: .now() + 0.5,
            execute: block
        )
    }

    override func stopLoading() {
        ImageURLProtocol.queue.async {
            if !self.cancellOrCompleted, let cancelBlock = self.block {
                cancelBlock.cancel()

                self.cancellOrCompleted = true
            }
        }
    }

    static func urlSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ImageURLProtocol.classForCoder()]
        return URLSession(configuration: config)
    }
}
