//
//  ViewController.swift
//  POCOrpheau
//
//  Created by Kevin Bernajuzan on 03/06/2017.
//  Copyright © 2017 Kevin Bernajuzan. All rights reserved.
//
import PKHUD
import UIKit
import SwiftSocket

enum POCErrors : String {
    case emptyField = "Erreur : Un champs est vide"
    case requestNil = "Erreur : Request est a nil"
    case clientNil = "Erreur Socket : Client non initialise - connectez vous avec une adresse ip et un port"
    case vinyleFace = "Erreur : la Face du vinyle doit etre A ou B"
}

enum POCSocketError : String, Error {
    case connection = "Erreur lors de la connexion"
}

struct ConnectionStrings {
    static var host = "127.0.0.1"
    static var port = 1337
}

class ViewController: UIViewController {
    
    @IBOutlet weak var chain: UITextField!
    @IBOutlet weak var position: UITextField!
    @IBOutlet weak var vinyleID: UITextField!
    @IBOutlet weak var vinyleFace: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var cmdTf: UITextField!
    @IBOutlet weak var ipTf: UITextField!
    @IBOutlet weak var portTf: UITextField!
    @IBOutlet weak var disdplayView: UITextView!
    @IBOutlet weak var infoBt: UIBarButtonItem!
    
    var client: TCPClient?
    var request : String? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = UIColor.darkGray
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white,NSFontAttributeName:UIFont(name:"HelveticaNeue-Light",size:25) as Any]
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.client?.close()
        self.client = nil
    }
    
    
    
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
        self.connectButton.layer.borderWidth = 1.0
        self.connectButton.layer.borderColor = UIColor.darkGray.cgColor
        self.sendButton.layer.borderColor = UIColor.darkGray.cgColor
        self.disdplayView.layer.borderColor = UIColor.darkGray.cgColor
        self.connectButton.layer.cornerRadius = 4.0
        self.sendButton.layer.cornerRadius = 4.0
        self.disdplayView.layer.cornerRadius = 4.0
        self.sendButton.layer.borderWidth = 1.0
        self.connectButton.layer.backgroundColor = UIColor.darkGray.cgColor
        self.sendButton.layer.backgroundColor = UIColor.darkGray.cgColor
        self.connectButton.tintColor = UIColor.white
        self.sendButton.tintColor = UIColor.white
        self.vinyleID.delegate = self
        self.vinyleFace.delegate = self
        self.cmdTf.delegate = self
        self.position.delegate = self
        self.chain.delegate = self
        
        /*
         self.ipTf.text = ConnectionStrings.host
         self.portTf.text = "8080"*/
    }
    
    func connectSocket(client : TCPClient,completion : @escaping (Result) -> Void) {
        let background = DispatchQueue.global(qos: .background)
        background.async {
            switch client.connect(timeout: 5) {
            case .success :
                return completion(.success)
            case .failure:
                return completion(.failure(POCSocketError.connection))
            }
        }
        
    }
    
    @IBAction func connectTapped(_ sender: Any) {
        self.view.endEditing(true)
        HUD.show(.progress)
        if (self.ipTf.text == nil) || self.ipTf.text == "" {
            HUD.flash(.error, delay: 0.8)
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        if (self.portTf.text == nil) || self.portTf.text == "" {
            HUD.flash(.error, delay: 0.8)
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        guard let ip = self.ipTf.text else {
            HUD.flash(.error, delay: 0.8)
            return
            
        }
        guard let p = self.portTf.text else {
            HUD.flash(.error, delay: 0.8)
            return
            
        }
        
        self.client = TCPClient(address: ip, port: Int32(p) ?? 8080)
        guard  let c = self.client else {return}
        self.connectSocket(client: c, completion: { (res) in
            DispatchQueue.main.async(execute: {
                switch res {
                case .success:
                    HUD.flash(.success, delay: 0.8)
                    let bytes = self.readResponse(from: c)
                    if let r = (String(bytes: bytes , encoding: .utf8)) {
                        self.disdplayView.text = "Server says : \(r) - \(bytes)  )"
                    }
                    self.disdplayView.text = "Client : success Connection \(c.address) \(c.port)"
                case .failure(let e as POCSocketError):
                    HUD.flash(.error, delay: 0.8)
                    self.disdplayView.text = "\(e.rawValue)"
                default:
                    break
                }
            })
            
        })
    }
    
    @IBAction func infoTapped(_ sender: Any) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        let messageText = NSMutableAttributedString(
            string: "\n FACE :  A ou B \n COMMANDE : \n     L pour Lecture , \n     R pour rangement , \n     E pour ejection \n ENCHAINEMENT : \n     1 pour la face demandée\n     2 pour enchainer avec la face suivante \n POSITION du vinyle : de 1 à 20 \n IDENTIFIANT : Identifiant du vinyle \n\n Ex: le vinyle qui a pour identifiant BOB en position 14 pour lancer la lecture de la face A  puis B on aura :  AL214BOB ",
            attributes: [
                NSParagraphStyleAttributeName: paragraphStyle,
                NSFontAttributeName : UIFont(name: "Helvetica-Neue", size: 12) ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.body),
                NSForegroundColorAttributeName : UIColor.black
            ]
        )
        
        
        let infoCtrl = UIAlertController(title:"Informations sur la trame ", message: "", preferredStyle: .alert)
        infoCtrl.setValue(messageText, forKey: "attributedMessage")
        let ok = UIAlertAction(title: "OK", style: .destructive, handler: nil)
        infoCtrl.addAction(ok)
        self.present(infoCtrl, animated: true, completion: nil)
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
            let s = "Client sent : \(string) \(buf)"
            self.disdplayView.text = s
            print("client sending \(string)")
            return readResponse(from: client)
        case .failure(let error):
            print(error)
            self.disdplayView.text = "\(error)"
            return []
        }
    }
    
    
    //[49, 84, 69, 83, 84, 73, 68, 65]
    @IBAction func sendTapped(_ sender: Any) {
        self.view.endEditing(true)
        if (self.cmdTf.text == nil) || self.cmdTf.text == "" {
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        if (self.vinyleFace.text == nil) || self.vinyleFace.text == "" {
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        if (self.vinyleFace.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "A") && self.vinyleFace.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "B" && self.vinyleFace.text?.trimmingCharacters(in: .whitespacesAndNewlines) != ("-") {
            self.disdplayView.text = POCErrors.vinyleFace.rawValue
            return
        }
        if (self.vinyleID.text == nil) || self.vinyleID.text == "" {
            self.disdplayView.text = POCErrors.emptyField.rawValue
            return
        }
        
        if let c = self.client {
            
            self.request = "\(self.vinyleFace.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")\(self.cmdTf.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")\(self.chain.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")\(self.position.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")\(self.vinyleID.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")"
            print(self.request ?? "")
            if let str = self.request {
                let resp = self.sendRequestData(string: str , using: c)
                if let str = String(bytes: resp, encoding: .utf8) {
                    self.disdplayView.text.append("\n\nServer: I received :\(str) \(resp)")
                }
            }
        } else {
            self.disdplayView.text = POCErrors.clientNil.rawValue
        }
    }
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

