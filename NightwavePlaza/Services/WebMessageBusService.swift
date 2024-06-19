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
                jsonData["error"] = "'\(error)'"
            } else {
                jsonData["result"] = result
            }

            self.sendMessage(name: "iosCallback", data: jsonData)
        });
        
    }
    
    func sendMessage(name: String, data: Any?) {
        let dataString = self.jsObjectStringFromObject(object: data)
        var jsMessage: String
        if dataString == "undefined" {
            jsMessage = "window['emitter'].emit('\(name)', \(data!)); 'ok'; "
        } else {
            jsMessage = "window['emitter'].emit('\(name)', '\(dataString)'); 'ok'; "
        }
        
        print("Sending message: \(jsMessage)")

        webView?.evaluateJavaScript(jsMessage, completionHandler: { (res, err) in
            print("Send Message Result: \(String(describing: res)), error = \(String(describing: err))")
        })
    }
    
    func jsObjectStringFromObject(object: Any?) -> String {
        do {
            guard let object = object else {
                return "undefined";
            }

            if let str = object as? String {
                return str
            }

            if(JSONSerialization.isValidJSONObject(object))
            {
                let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
                return String(data: jsonData, encoding: .utf8)!
            } else {
                return "undefined"
            }
        } catch {
            return "undefined"
        }
    }
}
