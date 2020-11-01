import Cocoa

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
let browser = ServicePublish()
browser.start()
