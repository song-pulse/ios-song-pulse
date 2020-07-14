//
//  ViewController.swift
//  E4 tester
//

import UIKit

class ViewController: UITableViewController {
    
    // Save data from E4
    var globalTimestamp: Int = 0
    var counter: Int = 0
    var globalTemp: Float = 0
    var globalAccx: Float = 0
    var globalAccy: Float = 0
    var globalAccz: Float = 0
    var globalBvp: Float = 0
    var globalIbi: Float = 0
    var globalEda: Float = 0
    
    var cookie: HTTPCookie = CookieStructOperation.globalVariable.cookie

    static let EMPATICA_API_KEY = "d77fdbf4efb64e4fba058e8a16624a0a"
    var myEntryController: EntryController = EntryController()
    
    var pId = StructOperation.glovalVariable.pId
    
    private var devices: [EmpaticaDeviceManager] = []
    
    private var allDisconnected : Bool {
        
        return self.devices.reduce(true) { (value, device) -> Bool in
        
            value && device.deviceStatus == kDeviceStatusDisconnected
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        
        self.tableView.dataSource = self
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            EmpaticaAPI.authenticate(withAPIKey: ViewController.EMPATICA_API_KEY) { (status, message) in
                
                if status {
                    
                    // "Authenticated"
                    
                    DispatchQueue.main.async {
                        
                        self.discover()
                    }
                }
            }
        }
    }
    
    private func discover() {
        
        EmpaticaAPI.discoverDevices(with: self)
    }
    
    private func disconnect(device: EmpaticaDeviceManager) {
        
        if device.deviceStatus == kDeviceStatusConnected {
            
            device.disconnect()
        }
        else if device.deviceStatus == kDeviceStatusConnecting {
            
            device.cancelConnection()
        }
    }
    
    private func connect(device: EmpaticaDeviceManager) {
        
        device.connect(with: self)
    }
    
    private func updateValue(device : EmpaticaDeviceManager, string : String = "") {
        
        if let row = self.devices.index(of: device) {
            
            DispatchQueue.main.async {
                
                for cell in self.tableView.visibleCells {
                    
                    if let cell = cell as? DeviceTableViewCell {
                        
                        if cell.device == device {
                            
                            let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0))
                            
                            if !device.allowed {
                                
                                cell?.detailTextLabel?.text = "NOT ALLOWED"
                                
                                cell?.detailTextLabel?.textColor = UIColor.orange
                            }
                            else if string.count > 0 {
                                
                                cell?.detailTextLabel?.text = "\(self.deviceStatusDisplay(status: device.deviceStatus)) • \(string)"
                                
                                cell?.detailTextLabel?.textColor = UIColor.gray
                            }
                            else {
                                
                                cell?.detailTextLabel?.text = "\(self.deviceStatusDisplay(status: device.deviceStatus))"
                                
                                cell?.detailTextLabel?.textColor = UIColor.gray
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deviceStatusDisplay(status : DeviceStatus) -> String {
        switch status {
            
        case kDeviceStatusDisconnected:
            return "Disconnected"
        case kDeviceStatusConnecting:
            return "Connecting..."
        case kDeviceStatusConnected:
            return "Connected"
        case kDeviceStatusFailedToConnect:
            return "Failed to connect"
        case kDeviceStatusDisconnecting:
            return "Disconnecting..."
        default:
            return "Unknown"
        }
    }
    
    private func restartDiscovery() {
        
        print("restartDiscovery")
        
        guard EmpaticaAPI.status() == kBLEStatusReady else { return }
        
        if self.allDisconnected {
            
            print("restartDiscovery • allDisconnected")
            
            self.discover()
        }
    }
    
    // This function sends the E4 data (POST request)
    func sendE4Data(){
        print("Cookie", self.cookie)
        // Construct the URL with the participant ID that was entered by the user and the recording ID.
        let url = URL(string: "http://130.60.24.99:8080/participants/" + self.pId + "/recordings/" + StructOperation.glovalVariable.rId + "/values/timestamps")!
        
        // Create the Json object
        let json: [String: Any] = ["timestamp": self.globalTimestamp, "eda": self.globalEda, "ibi": self.globalIbi, "temp": self.globalTemp, "acc_x": self.globalAccx, "acc_y": self.globalAccy, "acc_z": self.globalAccz]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Set cookie.
        let jar = HTTPCookieStorage.shared
        jar.setCookie(cookie)
        
        // Post request.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        //request.httpBody = try! JSONSerialization.data(withJSONObject: [], options: [])
        // insert json data to the request
        request.httpBody = jsonData

        // Get the recording ID out of the response.
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            print("Data: ", data)
        }
        task.resume()
    }
    
    // This function stops a recording.
    @IBAction func stopRecording(sender: UIButton){
        
        for device in devices{
            self.disconnect(device: device)
        }
    }
}


extension ViewController: EmpaticaDelegate {
    
    func didDiscoverDevices(_ devices: [Any]!) {
        
        print("didDiscoverDevices")
        
        if self.allDisconnected {
            
            print("didDiscoverDevices • allDisconnected")
            
            self.devices.removeAll()
            
            self.devices.append(contentsOf: devices as! [EmpaticaDeviceManager])
            
            DispatchQueue.main.async {
                
                self.tableView.reloadData()
                
                if self.allDisconnected {
                
                    EmpaticaAPI.discoverDevices(with: self)
                }
            }
        }
    }
    
    func didUpdate(_ status: BLEStatus) {
        
        switch status {
        case kBLEStatusReady:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusReady")
            break
        case kBLEStatusScanning:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusScanning")
            break
        case kBLEStatusNotAvailable:
            print("[didUpdate] status \(status.rawValue) • kBLEStatusNotAvailable")
            break
        default:
            print("[didUpdate] status \(status.rawValue)")
        }
    }
}

extension ViewController: EmpaticaDeviceDelegate {
    
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        // Save the value in the global variable.
        self.globalTemp = temp
        print("\(device.serialNumber!) TEMP { \(temp) }")
        
        self.counter = self.counter + 1 // huge hack, temp is measured 4 x per second so with modulo 40 == 0 we can reach a send frequency of about 10 seconds
        if self.counter % 40 == 0 {
            sendE4Data()
        }
    }
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        // Save the values in the global variable.
        self.globalAccx = Float(x)
        self.globalAccy = Float(y)
        self.globalAccz = Float(z)
        print("\(device.serialNumber!) ACC > {x: \(x), y: \(y), z: \(z)}")
    }
    
    func didReceiveTag(atTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        //Save the value in the global variable.
        self.globalTimestamp = Int(timestamp)
        print("\(device.serialNumber!) TAG received { \(timestamp) }")
    }
    
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        print("\(device.serialNumber!) GSR { \(abs(gsr)) }")
        //Save the value in the gobal variable.
        self.globalEda = Float(gsr)
        self.updateValue(device: device, string: "\(String(format: "%.2f", abs(gsr))) µS")
    }
    
    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        
        print("\(device.serialNumber!) IBI { \(abs(ibi)) }")
        //Save the value in the gobal variable.
        self.globalIbi = Float(ibi)
    }
    
    func didReceiveBVP(_ bvp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!){
        
        print("\(device.serialNumber!) BVP { \(abs(bvp)) }")
        //Save the value in the gobal variable.
        self.globalBvp = Float(bvp)
    }
    
    func didUpdate( _ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        
        self.updateValue(device: device)
        
        switch status {
            
        case kDeviceStatusDisconnected:
            
            print("[didUpdate] Disconnected \(device.serialNumber!).")
            
            self.restartDiscovery()
            
            break
            
        case kDeviceStatusConnecting:
            
            print("[didUpdate] Connecting \(device.serialNumber!).")
            break
            
        case kDeviceStatusConnected:
            print("[didUpdate] Connected \(device.serialNumber!).")
            break
            
        case kDeviceStatusFailedToConnect:
            
            print("[didUpdate] Failed to connect \(device.serialNumber!).")
            
            self.restartDiscovery()
            
            break
            
        case kDeviceStatusDisconnecting:
            
            print("[didUpdate] Disconnecting \(device.serialNumber!).")
            
            break
            
        default:
            break
            
        }
    }
}

extension ViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        EmpaticaAPI.cancelDiscovery()
        
        let device = self.devices[indexPath.row]
        
        if device.deviceStatus == kDeviceStatusConnected || device.deviceStatus == kDeviceStatusConnecting {
            
            self.disconnect(device: device)
        }
        else if !device.isFaulty && device.allowed {
            
            self.connect(device: device)
        }
        
        self.updateValue(device: device)
    }
}

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let device = self.devices[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "device") as? DeviceTableViewCell ?? DeviceTableViewCell(device: device)
        
        cell.device = device
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        cell.textLabel?.text = "E4 \(device.serialNumber!)"
        
        cell.alpha = device.isFaulty || !device.allowed ? 0.2 : 1.0
        
        return cell
    }
}

class DeviceTableViewCell : UITableViewCell {
    
    
    var device : EmpaticaDeviceManager
    
    
    init(device: EmpaticaDeviceManager) {
        
        self.device = device
        
        super.init(style: UITableViewCellStyle.value1, reuseIdentifier: "device")
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
}
