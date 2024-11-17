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
            webView.evaluateJavaScript("document.body.scrollHeight") { result, error in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.contentHeight = height
                    }
                }
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
