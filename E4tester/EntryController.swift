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
    
    public var participantId: String = "0"
    public var recordingId: String = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldDidChange (field: UITextField){
        self.getParticipantId(sender: field)
    }
    
    // Get the participant ID from the user input.
    @IBAction func getParticipantId (sender: UITextField) {
        
        if(field != nil){
            self.participantId = field.text!
            StructOperation.glovalVariable.pId = self.participantId
        }
        else{
            print("No participant ID found.")
        }
    }
    
    // This function starts a new run (POST request)
    // and saves the recording ID we get in the response.
    @IBAction func startRun(sender: UIButton){

        // Construct the URL with the participant ID that was entered by the user.
        let url = URL(string: "http://130.60.24.99:8080/participants/" + participantId + "/recordings/start/")!
        
        // Post request.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: [], options: [])
       
        // Get the recording ID out of the response.
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            let stringData = String(data: data, encoding: .utf8)!
            let splitData = stringData.split(separator: ",")
            self.recordingId = String(splitData[2].split(separator: ":")[1])
            print(String(data: data, encoding: .utf8)!)
            print("Recording ID", self.recordingId)
            StructOperation.glovalVariable.rId = self.recordingId
            print("RID in Struct: ", StructOperation.glovalVariable.rId)
        }
        task.resume()
    }
}
