import Cocoa
import PlaygroundSupport




public class ServicePublish {
    deinit {
        print("deinit - ServicePublish")
    }
    
    let object: ServicePublishDelegate
    let browser: NetService
    
    public init() {
        object = ServicePublishDelegate()
        browser = NetService(domain: "", type: "_http._tcp", name: "vweb", port: 5444)
        print("init - ServicePublish")
    }
    
    public func start() {
        print("browser.publish")
        browser.delegate = object
        //
        browser.publish(options: [])
    }
    public func stop() {
        print("browser.stop()")
        browser.stop()
    }
}

class ServicePublishDelegate: NSObject, NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("netServiceWillPublish")
    }
    func netServiceDidPublish(_ sender: NetService) {
        print("netServiceDidPublish")
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print(errorDict)
        print("didNotPublish")
    }
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("didAcceptConnectionWith")
        
    }
}
//let browser = ServicePublish()
//browser.start()


class ServiceBrowser: NSObject {
    struct Service {
        //name 应该是唯一的
        var name: String?
        var type: String?
        var domain: String?
        //优先通过 hostname 和端口连接，不通再通过 address
        var hostname: String?
        var addresss: [String] = []
    }
    var browser: NetServiceBrowser = NetServiceBrowser()
    
    var services: [NetService] = []
    var isSearching: Bool = false
    var didUpdateUI: () -> Void
    init(didUpdateUI: @escaping () -> Void) {
        self.didUpdateUI = didUpdateUI
        super.init()
        browser.delegate = self
    }
    
    func startSearch() {
        browser.includesPeerToPeer = true
        //        To limit searches to the local network (for a chat program, for example), pass @"local" to search only the local LAN.
        //        For limited wide-area support, pass @"" to search the system’s default search domains. To avoid confusion, be sure to display each service’s domain in your user interface.
        //        browser.searchForServices(ofType: "_custom._tcp.", inDomain: "")
        browser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
        //        browser.searchForRegistrationDomains()
    }
}

extension ServiceBrowser: NetServiceBrowserDelegate {
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        self.isSearching = true
        print("netServiceBrowserWillSearch")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        self.isSearching = false
        self.didUpdateUI()
        print("netServiceBrowserDidStopSearch")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        //如果您的應用需要持久存儲對Bonjour服務的引用（例如在打印機選擇器中），請僅存儲服務名稱，類型和域。通過僅保留域，類型和名稱信息，即使應用程序的IP地址或端口號已更改，也可以確保您的應用程序可以找到相關的服務。
        //https://developer.apple.com/library/archive/documentation/Networking/Conceptual/NSNetServiceProgGuide/Articles/ResolvingServices.html#//apple_ref/doc/uid/20001078-SW8
        self.services.append(service)
//        if moreComing == true {
            service.delegate = self
            //別忘了取消您的Bonjour解決方案
            //https://developer.apple.com/library/archive/qa/qa1297/_index.html#//apple_ref/doc/uid/DTS10002343
            print("service.resolve")
            service.resolve(withTimeout: 10)
            
            self.didUpdateUI()
//        }
//        print("didFind service", service, moreComing)
//        print("\(service.addresses?.map({ $0.address })) - \(service.domain) - \(service.hostName) - \(service.name) - \(service.port)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.services.removeAll(where: { $0 == service })
        if moreComing == false {
            self.didUpdateUI()
        }
        print("didRemove service")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        if moreComing == false {
            self.didUpdateUI()
        }
        print("didFindDomain", domainString)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("didRemoveDomain domainString")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.isSearching = false
        self.didUpdateUI()
        print("didNotSearch errorDict")
        print(errorDict)
    }
}

extension ServiceBrowser: NetServiceDelegate {
    func netServiceWillResolve(_ sender: NetService) {
        print("netServiceWillResolve")
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        //假設您通過主機名進行連接，則可以netServiceDidResolveAddress:在首次調用代表的主機時立即請求該信息。但是請小心，因為可以多次調用此方法。
        print("netServiceDidResolveAddress")
        print("addresses:\(sender.addresses?.map({ $0.address })) - domain:\(sender.domain) - hostname:\(sender.hostName) - name:\(sender.name) - port:\(sender.port)")
        self.didUpdateUI()
    }
    func netServiceDidStop(_ sender: NetService) {
        print("netServiceDidStop")
    }
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        print("didUpdateTXTRecord")
    }
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve")
    }
}

fileprivate extension Data {
    var address: String {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        self.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
            let sockaddrPtr = pointer.bindMemory(to: sockaddr.self)
            guard let unsafePtr = sockaddrPtr.baseAddress else { return }
            guard getnameinfo(unsafePtr, socklen_t(self.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                return
            }
        }
        let ipAddress = String(cString:hostname)
        return ipAddress
    }
}

let browser = ServiceBrowser {
    print("-")
}
browser.startSearch()
PlaygroundPage.current.needsIndefiniteExecution = true
