//
//  ViewController.swift
//  PrayTime
//
//  Created by Atif on 05/09/2018.
//  Copyright © 2018 atif.gcucs@gmail.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var prayTimeList: NSMutableArray?
    var prayTime: PrayTime?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        
        let today = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let date = calendar.dateComponents([.year, .month, .day], from: today) as NSDateComponents
        let latitude:Double = 40.730610
        let longitude:Double = -73.935242
        let timeZone:Double = -4
        
        prayTime = PrayTime()
        prayTime?.calcMethod = .Karachi
        prayTime?.asrJuristic = .Shafii
        prayTime?.timeFormat = .Time12
        prayTimeList = prayTime?.getPrayerTimes(date: date, latitude: latitude, longitude: longitude, tZone: timeZone)
        
//        // Print date and time
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        for i in 0..<prayTimeList!.count {
//            print("\(formatter.string(from: today))", prayTimeList!.object(at: i))
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayTimeList!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text =  prayTime?.timeNames.object(at: indexPath.row) as? String
        cell.detailTextLabel?.text =  prayTimeList!.object(at: indexPath.row) as? String
        return cell
    }
}


