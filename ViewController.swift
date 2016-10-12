//
//  ViewController.swift
//  Swift_CFSocket_Client
//
//  Created by ImJeonghwan on 10/13/16.
//  Copyright © 2016 ImJeonghwan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var isConnected:Bool = false
    var socketRef:CFSocketRef?
    var serverPort:UInt16 = UInt16(4444)
    var serverSocketAddrPointer:UnsafeMutablePointer<sockaddr_in> = UnsafeMutablePointer<sockaddr_in>.alloc(1)

    @IBOutlet weak var hostField: UITextField!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var serverConnectButton: UIButton!
    @IBOutlet weak var dataField: UITextField!
    @IBOutlet weak var responseLabel: UITextView!
    
    @IBAction func handleConnect(sender: AnyObject) {
        if false == isConnected {
            
            socketRef = CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil)
            
            if (socketRef != nil) {
                
                let serverIP:String = hostField.text!
                
                if serverIP.characters.count > 0 {
                    
                    let serverIPCString = serverIP.cStringUsingEncoding(NSASCIIStringEncoding)
                    
                    let binaryAddress:UnsafeMutablePointer<in_addr_t> = UnsafeMutablePointer<in_addr_t>.alloc(1)
                    
                    inet_pton(AF_INET, serverIPCString!, binaryAddress)
                    
                    serverSocketAddrPointer.memory.sin_len = __uint8_t(sizeof(sockaddr_in))
                    
                    serverSocketAddrPointer.memory.sin_family = sa_family_t(AF_INET)
                    
                    serverSocketAddrPointer.memory.sin_port = in_port_t(serverPort.bigEndian)
                    
                    serverSocketAddrPointer.memory.sin_zero = (0,0,0,0,0,0,0,0)
                    
                    serverSocketAddrPointer.memory.sin_addr = in_addr(s_addr: binaryAddress.memory)
                    
                    let connectServerAddrPointer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>(serverSocketAddrPointer)
                    
                    let connectAddr = CFDataCreate(kCFAllocatorDefault, connectServerAddrPointer, sizeof(sockaddr_in))!
                    
                    let connectionResult = CFSocketConnectToAddress(socketRef, connectAddr, CFTimeInterval(30.0))
                    
                    if connectionResult == CFSocketError.Success {
                        
                        connectionStatusLabel.text = "socket is connected"
                        
                        serverConnectButton.setTitle("Disconnect", forState: UIControlState.Normal)
                        
                        isConnected = true
                        
                    } else {
                        
                        connectionStatusLabel.text = "unable to connect socket"
                        
                    }
                    
                } else {
                    
                    connectionStatusLabel.text = "invalid host IP address"
                    
                }
                
            } else {
                
                connectionStatusLabel.text = "error creating socket"
                
            }
            
        } else {
            
            if (socketRef != nil) {
                
                CFSocketInvalidate(socketRef)
                
            }
            
            socketRef = nil
            
            serverConnectButton.setTitle( "Connect", forState:UIControlState.Normal)
            
            connectionStatusLabel.text = "socket is disconnected"
            
            isConnected = false
            
        }

    }
    
    @IBAction func handleSendData(sender: AnyObject) {
        if dataField.text?.characters.count > 0 {
            
            if (nil != socketRef && isConnected == true) {
                
                let dataCString = dataField.text!.cStringUsingEncoding(NSASCIIStringEncoding)
                
                let dataLength = dataField.text!.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)
                
                let nsData:NSData = NSData(bytes:dataCString!, length:dataLength)
                
                let timeout:CFTimeInterval = CFTimeInterval(30.0)
                
                CFSocketSendData(socketRef, nil, nsData, timeout)
                
                launchThreadToReceiveResponse()
                
            }
            
        }
    }
    
    func launchThreadToReceiveResponse() {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {() -> Void in
            
            let responseBuffer:[CChar] = [CChar](count:4097, repeatedValue:0)
            
            let nativeSocket = CFSocketGetNative(self.socketRef)
            
            let dataBuffer = UnsafeMutablePointer<Void>(responseBuffer)
            
            let result = Darwin.recv(nativeSocket, dataBuffer, 4096, 0)
            
            if result >= 0 {
                
                let responseString = String.fromCString(responseBuffer)
                
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    
                    self.responseLabel.text = responseString
                    
                })
                
            }
            
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

