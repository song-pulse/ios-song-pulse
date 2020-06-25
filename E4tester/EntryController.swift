//
//  EntryController.swift
//  E4tester
//
//  Created by Alina Marti on 23.06.20.
//  Copyright © 2020 Felipe Castro. All rights reserved.
//

import UIKit

class EntryController: UIViewController {
    
    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var participantId: String = "0"
    var recordingId: String = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldDidChange (field: UITextField){
        self.getParticipantId(sender: field)
    }
    
    @IBAction func getParticipantId (sender: UITextField) {
        
        if(field != nil){
            self.participantId = field.text!
            print("Participant ID", participantId)
        }
        else{
            print("No participant ID found.")
        }
    }
    
    @IBAction func startRun(sender: UIButton){

        let url = URL(string: "http://130.60.24.99:8080/participants/" + participantId + "/recordings/start/")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: [], options: [])
       
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
//            print(data)
            let stringData = String(data: data, encoding: .utf8)!
            let splitData = stringData.split(separator: ",")
            self.recordingId = String(splitData[2].split(separator: ":")[1])
            print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
}
