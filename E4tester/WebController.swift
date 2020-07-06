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
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        
        guard let url = navigationAction.request.url else {
            print("URL :", navigationAction.request.url)
            decisionHandler(.allow)
            return
        }
        
        if url.absoluteString.contains("/spotify/whoami") {
            // this means login successful
            
            let dataStore = WKWebsiteDataStore.default()
            if #available(iOS 13.0, *) {
                dataStore.httpCookieStore.getAllCookies({ (cookies) in
                    self.cookies = cookies
                    CookieStructOperation.globalVariable.cookie = self.cookies[0]
                })
                navigateToMainInterface()
                
                decisionHandler(.cancel)
            }
            else {
                // Fallback on earlier versions
                print("IOS 13 is needed.")
            }
        }
        else {
            decisionHandler(.allow)
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

