
import SwiftUI
import WebKit

struct VeryChatWebView: View {
    @StateObject private var manager = VeryChatManager() // Ideally passed or shared, but for now new instance or singleton usage might be needed if state persists. 
    // Actually, passing the token derived from the manager in ConnectionView is better.
    var accessToken: String?
    
    var body: some View {
        VeryChatWebViewWrapper(url: URL(string: "https://www.verychat.io")!, accessToken: accessToken)
            .navigationBarTitle("VeryChat", displayMode: .inline)
    }
}

struct VeryChatWebViewWrapper: UIViewRepresentable {
    let url: URL
    let accessToken: String?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        var request = URLRequest(url: url)
        
        // Strategy: Append token to URL if supported, or inject via headers/JS.
        // Since we don't know if verychat.io supports query param auth, we'll try to set a header or cookie.
        // Assuming common pattern: If we have a token, we might want to attach it.
        // However, a pure webview load of a main page often relies on cookies.
        // Let's try injecting a script to set localStorage if we have a token (common for SPAs).
        
        if let token = accessToken {
           // Inject token into localStorage before loading or after loading? 
           // Usually better to load, then inject. But let's try to construct a request with header first.
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: VeryChatWebViewWrapper

        init(_ parent: VeryChatWebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Injection logic if needed
            if let token = parent.accessToken {
                let js = "localStorage.setItem('accessToken', '\(token)');"
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
}
