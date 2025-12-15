//
//  WebView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 11/16/24.
//
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlString: String
    let bodyFontSize: CGFloat
    let bodyFontFamily: String
    let bodyFontWeight: String

    @Binding var contentHeight: CGFloat

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.offsetHeight") {  [weak self] result, error in
                guard let self = self else { return }

                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.contentHeight = height
                    }
                }
            }
        }
        
        // Prevent navigation when links are tapped
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow the initial load, but prevent link clicks
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlContent = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-size: \(bodyFontSize)px;
                    font-family: '\(bodyFontFamily)', sans-serif;
                    font-weight: \(bodyFontWeight);
                    margin: 0;
                    padding: 0;
                }
            </style>
        </head>
        <body>
            \(htmlString)
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlContent, baseURL: nil)

    }
}
