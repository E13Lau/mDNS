//
//  ViewController.swift
//  mDNS
//
//  Created by lau on 2020/10/31.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    let service = ServicePublish()
    var browser: ServiceBrowser!

    override func viewDidLoad() {
        super.viewDidLoad()
        let tableView = UITableView(frame: .zero)
        self.view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        ])
        browser = ServiceBrowser.init {
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        }
        browser.startSearch()
        service.start()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return browser.services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = browser.services[indexPath.row]
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "hostname:\(item.hostName ?? "")/address:\(item.addresses?.map({ $0.address }) ?? [])"
        return cell
    }
}

class ServicePublish: NSObject {
    //https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/NetServices/Articles/programming.html#//apple_ref/doc/uid/TP40002459-SW3
    var service: NetService
    
    override init() {
        //port 随机端口，在 -netServiceDidPublish: 回调方法中获得端口port
        //您必須傳遞形式為的字符串"_applicationprotocol._transportprotocol"。目前"_transportprotocol"必須為"_tcp"或"_udp"。您的字符數"applicationprotocol"必須少於或等於15個
        //domain 如果傳遞一個空字符串（""），則將使用本地鏈接多播和用戶選擇的單播DNS域（如果適用）註冊服務。
        //domain 如果您傳入"local."，則您的服務僅使用本地鏈接多播註冊，而不在任何用戶選擇的單播DNS域中註冊。
        //domain 除"local."域外，只有在出於某些特殊原因想要在特定的遠程域中註冊服務時，才需要傳遞特定的字符串。
        //type 請注意，字符串末尾的句點字符是必需的，表明域名是絕對名稱
        service = NetService(domain: "local.", type: "_http._tcp.", name: "eeweb", port: 6668)
        super.init()
        service.includesPeerToPeer = true
        service.delegate = self
        let data = NetService.data(fromTXTRecord: ["vendor": "Web".data(using: .utf8)!,
                                                   "port": "6668".data(using: .utf8)!])
        service.setTXTRecord(data)
    }
    
    func start() {
        // listenForConnections 發布服務時，如果在服務選項中設置了標誌，則服務對象代表您的應用接受連接。稍後，當客戶端連接到該服務時，服務對象將調用此方法，以為應用提供一對與該客戶端進行通信的流。
        // noAutoRename 如果名称不可用时，不自动改名
        service.publish(options: [])
    }
}
extension ServicePublish: NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("netServiceWillPublish")
    }
    func netServiceDidPublish(_ sender: NetService) {
        print("netServiceDidPublish")
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("didNotPublish")
    }
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("didAcceptConnectionWith")
    }
}


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
        browser.searchForServices(ofType: "_http._tcp.", inDomain: "")
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
        if moreComing == false {
            service.delegate = self
            //別忘了取消您的Bonjour解決方案
            //https://developer.apple.com/library/archive/qa/qa1297/_index.html#//apple_ref/doc/uid/DTS10002343
            service.resolve(withTimeout: 5)
            
            self.didUpdateUI()
        }
        print("didFind service", service, moreComing)
        print("\(service.addresses?.map({ $0.address })) - \(service.domain) - \(service.hostName) - \(service.name) - \(service.port)")
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
        print("\(sender.addresses?.map({ $0.address })) - \(sender.domain) - \(sender.hostName) - \(sender.name) - \(sender.port)")
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
