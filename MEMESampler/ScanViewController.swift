//
//  ScanViewController.swift
//  MEMESampler
//
//  Created by tanaka.takaaki on 2016/12/08.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import MEMELib
import UIKit

class ScanViewController: UITableViewController {

    private static let centralManagerEnabled = "centralManagerEnabled"
    var memes: [CBPeripheral] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var presenter: MEMEPresenter = MEMEPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        MEMELib.sharedInstance().addObserver(self, forKeyPath: ScanViewController.centralManagerEnabled, options: NSKeyValueObservingOptions.new, context: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Scan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScanViewController.tapScanButton(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MemeViewControllerSegue" {
            //guard let nvc: UINavigationController = segue.destination as? UINavigationController else { return }
            if let vc = segue.destination as? MemeViewController {
                vc.presenter = presenter
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == ScanViewController.centralManagerEnabled {
            MEMELib.sharedInstance().setAutoConnect(false)
            MEMELib.sharedInstance().delegate = self
            navigationItem.rightBarButtonItem?.isEnabled = true;
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Configure the cell...
        let peripheral = memes[indexPath.row]
        cell.textLabel?.text = peripheral.identifier.uuidString
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = memes[indexPath.row]
        let status: MEMEStatus = MEMELib.sharedInstance().connect(peripheral)
        checkMEME(status: status)
        print("Start connecting to JINS MEME")
    }

    internal func tapScanButton(sender : Any) {
        let status: MEMEStatus = MEMELib.sharedInstance().startScanningPeripherals()
        checkMEME(status: status)
    }
    
    internal func checkMEME(status: MEMEStatus) {
        switch  status {
        case MEME_ERROR_APP_AUTH:
            let alert : UIAlertController = UIAlertController(title: "App Auth Failed", message: "Invalid Application ID or Client Secret", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ action in
                
            })
            present(alert, animated: true, completion: nil)
        case MEME_ERROR_SDK_AUTH:
            let alert : UIAlertController = UIAlertController(title: "SDK Auth Failed", message: "Invalid SDK. Please update to the latest SDK.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ action in
                
            })
            present(alert, animated: true, completion: nil)
        case MEME_OK:
            print("Status: MEME_OK")
        default:
            ()
        }
    }
}

// MARK: - MEMELibDelegate
extension ScanViewController: MEMELibDelegate {
    func memePeripheralFound(_ peripheral: CBPeripheral!, withDeviceAddress address: String!) {
        print("peripheral found \(peripheral.identifier.uuidString)")
        
        if !memes.contains(peripheral) {
            memes.append(peripheral)
        }
        
        tableView.reloadData()
    }

    func memeAppAuthorized(_ status: MEMEStatus) {
        checkMEME(status: status)
    }
    
    func memePeripheralConnected(_ peripheral: CBPeripheral!) {
        print("JINS MEME connected")
        navigationItem.rightBarButtonItem?.isEnabled = false;
        tableView.isUserInteractionEnabled = false;
        
        let status : MEMEStatus = MEMELib.sharedInstance().startDataReport()
        checkMEME(status: status)
        
        performSegue(withIdentifier: "MemeViewControllerSegue", sender: self)
    }
    
    func memePeripheralDisconnected(_ peripheral: CBPeripheral!) {
        
        navigationItem.rightBarButtonItem?.isEnabled = true;
        tableView.isUserInteractionEnabled = true;
        presenter.disconnected(peripheral: peripheral)
    }
    
    func memeRealTimeModeDataReceived(_ data: MEMERealTimeData!) {
        presenter.memeRealTimeDataReceived(data)
    }
}
