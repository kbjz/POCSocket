//
//  ViewController.swift
//  POCOrpheau
//
//  Created by Kevin Bernajuzan on 03/06/2017.
//  Copyright © 2017 Orpheau. All rights reserved.
//

import UIKit
import SwiftSocket

enum POCErrors : String {
    case emptyField = "Erreur : Un champs est vide"
    case requestNil = "Erreur : Request est a nil"
    case clientNil = "Erreur Socket : Client  non initialise - connectez vous avec une adresse ip et un port"
}

struct ConnectionStrings {
    static var host = "127.0.0.1"
    static var port = 1337
}

class ViewController: UIViewController {
    @IBOutlet weak var vinyleID: UITextField!
    @IBOutlet weak var vinyleFace: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var cmdTf: UITextField!
    @IBOutlet weak var ipTf: UITextField!
    @IBOutlet weak var portTf: UITextField!
    @IBOutlet weak var disdplayView: UITextView!
    var client: TCPClient?
    var request : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
    }
    
    func initialize() {
        self.vinyleID.layer.borderColor=UIColor.lightGray.cgColor
        self.vinyleFace.layer.borderColor=UIColor.lightGray.cgColor
        self.cmdTf.layer.borderColor=UIColor.lightGray.cgColor
        self.ipTf.layer.borderColor=UIColor.lightGray.cgColor
        self.portTf.layer.borderColor=UIColor.lightGray.cgColor
        self.disdplayView.layer.borderColor=UIColor.lightGray.cgColor
        self.connectButton.layer.borderWidth = 1.0
        self.connectButton.layer.borderColor = UIColor.lightGray.cgColor
        self.sendButton.layer.borderColor = UIColor.lightGray.cgColor
        self.connectButton.layer.cornerRadius = 6.0
        self.sendButton.layer.cornerRadius = 6.0
        self.disdplayView.layer.cornerRadius = 6.0
        self.sendButton.layer.borderWidth = 1.0
        self.ipTf.text = ConnectionStrings.host
        self.portTf.text = "8080"
    }
    
    @IBAction func connectTapped(_ sender: Any) {
        guard let ip = self.ipTf.text else {return}
        guard let p = self.portTf.text else {return}
        
        self.client = TCPClient(address: ip, port: Int32(p) ?? 8080)
        guard  let c = self.client else {return}
        switch c.connect(timeout: 10) {
        case .success:
            let bytes = readResponse(from: c)
            if let r = (String(bytes: bytes , encoding: .utf8)) {
                self.disdplayView.text = "Server says : \(r) - \(bytes)  )"
            }
      //      self.disdplayView.text = "Client : success Connection \(c.address) \(c.port)"
        case .failure(let e):
            self.disdplayView.text = "\(e.localizedDescription)"
        }
    }
    
    
    private func readResponse(from client: TCPClient) -> [Byte]{
        guard let response = client.read(1024*10) else { return [] }
        print(response.count)
        print(response.debugDescription)
        print(response.description)
        return response
    }
    
    private func sendRequestData(string: String, using client: TCPClient) -> [Byte] {
        let buf = [UInt8](string.utf8)
        switch client.send(data:buf) {
        case .success:
            self.disdplayView.text = "Client send : \(string) \(buf)"
            print("client sending \(string)")
            return readResponse(from: client)
        case .failure(let error):
            print(error)
            self.disdplayView.text = "\(error)"
            return []
        }
    }
    
    
   /* private func sendRequest(string: String, using client: TCPClient) -> String? {
        switch client.send(string: string) {
        case .success:
            let buf = [UInt8](string.utf8)
            self.disdplayView.text = "Client send : \(string) \(buf)"
            print("client sending \(string)")
            return readResponse(from: client)
        case .failure(let error):
            print(error)
            self.disdplayView.text = "\(error)"
            return nil
        }
    }
 */
    //[49, 84, 69, 83, 84, 73, 68, 65]
    @IBAction func sendTapped(_ sender: Any) {
        if (self.cmdTf.text == nil) || self.cmdTf.text == "" {
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        if (self.vinyleFace.text == nil) || self.vinyleFace.text == "" {
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        if (self.vinyleID.text == nil) || self.vinyleID.text == "" {
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        if let c = self.client {
            self.request = "\(self.cmdTf.text ?? "")\(self.vinyleID.text ?? "")\(self.vinyleFace.text ?? "")"
            print(self.request ?? "")
            if let str = self.request {
                let resp = self.sendRequestData(string: str , using: c)
                if let str = String(bytes: resp, encoding: .utf8) {
                    self.disdplayView.text = "\(self.disdplayView.text)\nServer: I received :\(str) \(resp)"
                }
            }
        } else {
            self.disdplayView.text = POCErrors.clientNil.rawValue
        }
    }
}
    
