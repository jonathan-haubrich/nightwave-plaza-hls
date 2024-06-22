//
//  WebBridgeService.swift
//  NightwavePlaza
//
//  Created by Aleksey Garbarev on 02.08.2020.
//  Copyright © 2020 Aleksey Garbarev. All rights reserved.
//

import Foundation
import WebKit

class WebMessage: NSObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case args
        case callbackId
    }
    
    var name: String
    var args: [String]
    var callbackId: String

}

@objc protocol WebBusDelegate: NSObjectProtocol {
    func webBusDidReceiveMessage(message: WebMessage, completion: @escaping (Any?, String?) -> Void);
}


class WebMessageBus: NSObject, WKScriptMessageHandler {
    
    weak var webView: WKWebView? {
        didSet {
            self.webView?.configuration.userContentController.add(self, name: "plaza")
        }
    }
    weak var delegate: WebBusDelegate?
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                
        guard let decoded = try? decoder.decode(WebMessage.self, from: JSONSerialization.data(withJSONObject: message.body, options: .fragmentsAllowed)) else {
            print("Unable to decode a message from Web: \(message.body)")
            return;
        }
        
        self.delegate?.webBusDidReceiveMessage(message: decoded, completion: {[weak self] (result, error) in
            // TODO: Cleanup this method
            guard let self = self else { return };
            print("Message.name: \(message.name)")
            var jsonData: [String: Any?] = [
                "id": decoded.callbackId
            ]

            if let error = error {
                jsonData["error"] = "\(error)"
            } else {
                jsonData["result"] = result
            }

            self.sendMessage(name: "iosCallback", data: jsonData)
        });
        
    }
    
    func sendMessage(name: String, data: Any?, raw: Bool = false) {
        // iosCallback messages get JSON.parse'd so data is emitted as a string
        // others like isPlaying and isBuffering don't JSON.parse, so we send raw values
        var jsonString = self.jsObjectStringFromObject(object: data)

        if(!raw) {
            jsonString = "'\(jsonString)'"
        }

        let jsMessage = "window['emitter'].emit('\(name)', \(jsonString)); 'ok'; "

        print("Sending message: \(jsMessage)")

        webView?.evaluateJavaScript(jsMessage, completionHandler: { (res, err) in
            print("Send Message Result: \(String(describing: res)), error = \(String(describing: err))")
        })
    }
    
    func jsObjectStringFromObject(object: Any?) -> String {

        switch  object {
        case is String:
            return "\"\(object as! String)\""
        case is Bool:
            return "\(object as! Bool)"
        case .none:
            return "null"
        default:
            break
        }

        if let data = try? JSONSerialization.data(withJSONObject: object!, options: []) {
            if let string = String(data: data, encoding: .utf8) {
                // song title's with single quotes break the JSON string when emitting
                return string.replacingOccurrences(of: "'", with: "\\'")
            }
        }

        return "undefined"
    }
}
