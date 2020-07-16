//
//  WebController.swift
//  E4tester
//
//  Created by Alina Marti on 29.06.20.
//  Copyright © 2020 Felipe Castro. All rights reserved.
//

import UIKit
import WebKit
class WebController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    public var cookies: [HTTPCookie] = []
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    // Open the authorization to spotify as soon as the view was loaded.
    override func viewDidLoad(){
        
        let spotifyURLAuthorization = URL(string:"http://130.60.24.99:8080/spotify/authorize")!
        webView.load(URLRequest(url: spotifyURLAuthorization))
        webView.allowsBackForwardNavigationGestures = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url!.absoluteString.hasSuffix("/spotify/whoami") {
            // this means login successful
            
            let dataStore = WKWebsiteDataStore.default()
            if #available(iOS 13.0, *) {
                dataStore.httpCookieStore.getAllCookies({ (cookies) in
                    for cookie in cookies {
                        if cookie.name == "username" {
                            print(cookie)
                            CookieStructOperation.globalVariable.cookie = cookie
                            self.navigateToMainInterface()
                        }
                    }
                })
            }
            else {
                // Fallback on earlier versions
                print("IOS 13 is needed.")
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func navigateToMainInterface(){
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        guard let mainNavigationVC = mainStoryboard.instantiateViewController(identifier: "MainNavigationController") as? MainNavigationController else{
            return
        }
        
        present(mainNavigationVC, animated: true, completion: nil)
    }
    
}

