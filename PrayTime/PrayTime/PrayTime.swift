//
//  PrayTime.swift
//  PrayTime
//
//  Created by Atif on 05/09/2018.
//  Copyright © 2018 atif.gcucs@gmail.com. All rights reserved.
//

import UIKit

class PrayTime {
    // Calculation Methods
    enum CalculationMethod: NSInteger {
        case Jafari     = 0    // Ithna Ashari
        case Karachi    = 1    // University of Islamic Sciences, Karachi
        case ISNA       = 2    // Islamic Society of North America (ISNA)
        case MWL        = 3    // Muslim World League (MWL)
        case Makkah     = 4    // Umm al-Qura, Makkah
        case Egypt      = 5    // Egyptian General Authority of Survey
        case Tehran     = 6    // Institute of Geophysics, University of Tehran
        case Custom     = 7    // Custom Setting
    }
    
    // Juristic Methods
    enum JuristicMethod: NSInteger {
        case Shafii     = 0    // Shafii (standard)
        case Hanafi     = 1    // Hanafi
    }
    
    // Adjusting Methods for Higher Latitudes
    enum CoordinateAdjustment: NSInteger {
        case None       = 0     // No adjustment
        case MidNight   = 1     // middle of night
        case OneSeventh = 2     // 1/7th of night
        case AngleBased = 3     // angle/60th of night
    }
    
    // Time Formats
    enum TimeFormat: NSInteger {
        case Time24     = 0     // 24-hour format
        case Time12     = 1     // 12-hour format
        case Time12NS   = 2     // 12-hour format with no suffix
        case Float      = 3     // floating point number
    }
    
    // Time Names
    var timeNames = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha"]
    
    var invalidTime: String? = "-----"   // The string used for invalid times
    
    
    //--------------------- Technical Settings --------------------
    var numIterations: NSInteger = 1        // number of iterations needed to compute times
    
    //------------------- Calc Method Parameters --------------------
    /*  this.methodParams[methodNum] = new Array(fa, ms, mv, is, iv)
     
     fa : fajr angle
     ms : maghrib selector (0 = angle 1 = minutes after sunset)
     mv : maghrib parameter value (in angle or minutes)
     is : isha selector (0 = angle 1 = minutes after maghrib)
     iv : isha parameter value (in angle or minutes)
     */
    var methodParams: [CalculationMethod : [Any]] = [.Jafari  : [16, 0, 4, 0, 14],
                                                     .Karachi : [18, 1, 0, 0, 18],
                                                     .ISNA    : [15, 1, 0, 0, 15],
                                                     .MWL     : [18, 1, 0, 0, 17],
                                                     .Makkah  : [18.5, 1, 0, 1, 90],
                                                     .Egypt   : [19.5, 1, 0, 0, 17.5],
                                                     .Tehran  : [17.7, 0, 4.5, 0, 14],
                                                     .Custom  : [18, 1, 0, 0, 17]]
    
    var prayerTimesCurrent: NSMutableArray? = nil
    
    //Tuning offsets
    //fajr, sunrise, dhuhr, asr, sunset, magrib, isha
    var offsets: NSMutableArray? = [0, 0, 0, 0, 0, 0, 0]
    
    //---------------------- Global Variables --------------------
    var calcMethod: CalculationMethod   = .Jafari   // calcuation method
    var asrJuristic: JuristicMethod     = .Shafii   // Juristic method for Asr
    var dhuhrMinutes: Int               = 0         // minutes after mid-day for Dhuhr
    var adjustHighLats: Int             = 0         // adjusting method for higher latitudes
    var timeFormat: TimeFormat          = .Time24   // time format
    var lat: Double                     = 0         // latitude
    var lng: Double                     = 0         // longitude
    var timeZone: Double                = 0         // time-zone
    var JDate: Double                   = 0         // Julian date
    
    //---------------------- Trigonometric Functions -----------------------
    // range reduce angle in degrees.
    func fixangle(a:Double) -> Double {
        var a = a - (360 * (floor(a / 360.0)))
        a = a < 0 ? (a + 360) : a
        return a
    }
    
    func fixhour(a:Double) -> Double {
        var a = a - 24.0 * floor(a / 24.0)
        a = a < 0 ? (a + 24) : a
        return a
    }
    
    // radian to degree
    func radiansToDegrees(alpha:Double) -> Double {
        return ((alpha * 180.0) / Double.pi)
    }
    
    //deree to radian
    func DegreesToRadians(alpha:Double) -> Double {
        return ((alpha * Double.pi) / 180.0)
    }
    
    // degree sin
    func dsin(d:Double) -> Double {
        return (sin(DegreesToRadians(alpha: d)))
    }
    
    // degree cos
    func dcos(d:Double) -> Double {
        return (cos(DegreesToRadians(alpha: d)))
    }
    
    // degree tan
    func dtan(d:Double) -> Double {
        return (tan(DegreesToRadians(alpha: d)))
    }
    
    // degree arcsin
    func darcsin(x:Double) -> Double {
        let val = asin(x)
        return radiansToDegrees(alpha:val)
    }
    
    // degree arccos
    func darccos(x:Double) -> Double {
        let val = acos(x)
        return radiansToDegrees(alpha:val)
    }
    
    // degree arctan
    func darctan(x:Double) -> Double {
        let val = atan(x)
        return radiansToDegrees(alpha:val)
    }
    
    // degree arctan2
    func darctan2(y:Double, x:Double) -> Double {
        let val = atan2(y, x)
        return radiansToDegrees(alpha:val)
    }
    
    // degree arccot
    func darccot(x:Double) -> Double {
        let val = atan2(1.0, x)
        return radiansToDegrees(alpha:val)
    }
    
    //---------------------- Time-Zone Functions -----------------------
    // compute local time-zone for a specific date
    func getTimeZone() -> Double {
        let timeZone = NSTimeZone.local
        let hoursDiff = timeZone.secondsFromGMT() / 3600
        return Double(hoursDiff)
    }
    
    // compute base time-zone of the system
    func getBaseTimeZone() -> Double {
        let timeZone = NSTimeZone.default
        let hoursDiff = timeZone.secondsFromGMT() / 3600
        return Double(hoursDiff)
    }
    
    // detect daylight saving in a given date
    func detectDaylightSaving() -> Double {
        let timeZone = NSTimeZone.local
        let hoursDiff = timeZone.daylightSavingTimeOffset(for: Date())
        return hoursDiff
    }
    
    //---------------------- Julian Date Functions -----------------------
    // calculate julian date from a calendar date
    func julianDate(year:Int, month:Int, day:Int) -> Double {
        var year = year
        var month = month
        let day = day
        if (month <= 2) {
            year -= 1
            month += 12
        }
        let A = floor(Double(year)/100.0)
        let B = 2 - A + floor(Double(A)/4.0)
        let JD = floor(365.25 * (Double(year) + 4716)) + floor(30.6001 * (Double(month) + 1)) + Double(day) + B - 1524.5
        return JD
    }
    
    // convert a calendar date to julian date (second method)
    func calcJD(year:Int, month:Int, day:Int) -> Double {
        let J1970 = 2440588
        let components = NSDateComponents()
        components.weekday = day // Monday
        //[components setWeekdayOrdinal:1]; // The first day in the month
        components.month = month
        components.year = year // May
        
        let gregorian = NSCalendar.init(identifier: .gregorian)
        let date1 = gregorian?.date(from: components as DateComponents)
        
        let ms = date1?.timeIntervalSince1970 // # of milliseconds since midnight Jan 1, 1970
        let days = floor(ms!/(1000.0 * 60.0 * 60.0 * 24.0))
        return Double(J1970) + Double(days) - 0.5
    }
    
    //---------------------- Calculation Functions -----------------------
    // References:
    // http://www.ummah.net/astronomy/saltime
    // http://aa.usno.navy.mil/faq/docs/SunApprox.html
    
    // compute declination angle of sun and equation of time
    func sunPosition(jd:Double) -> NSMutableArray {
        
        let D = jd - 2451545
        let g = fixangle(a: 357.529 + 0.98560028 * D)
        let q = fixangle(a: 280.459 + 0.98564736 * D)
        let L = fixangle(a: q + (1.915 * dsin(d: g)) + (0.020 * dsin(d:(2 * g))))
        
        let e = 23.439 - (0.00000036 * D)
        let d = darcsin(x:dsin(d:e) * dsin(d:L))
        var RA = darctan2(y: (dcos(d: e) * dsin(d: L)), x: dcos(d: L)) / Double(15.0)
        
        //let RA = ([self darctan2: ([self dcos: e] * [self dsin: L]) andX: [self dcos:L]])/ 15.0;
        RA = fixhour(a: RA)
        let EqT = q/15.0 - RA
        
        let sPosition = NSMutableArray.init(array: [d, EqT])
        return sPosition
    }
    
    // compute equation of time
    func equationOfTime(jd:Double) -> Double {
        let eq = sunPosition(jd: jd).object(at: 1) as! Double
        return eq
    }
    
    // compute declination angle of sun
    func sunDeclination(jd:Double) -> Double {
        let d = sunPosition(jd: jd).object(at: 0) as! Double
        return d
    }
    
    // compute mid-day (Dhuhr, Zawal) time
    func computeMidDay(t:Double) -> Double {
        let T = equationOfTime(jd: JDate + t)
        let Z = fixhour(a: 12 - T)
        return Z
    }
    
    // compute time for a given angle G
    func computeTime(G:Double, t:Double) -> Double {
        let D = sunDeclination(jd: JDate + t)
        let Z = computeMidDay(t: t)
        let I = -dsin(d: G) - (dsin(d: D) * dsin(d: lat))
        let J = dcos(d: D) * dcos(d: lat)
        let V = (darccos(x: I / J)) / 15.0
        return Z + (G > 90 ? -V : V)
    }
    
    // compute the time of Asr
    // Shafii: step=1, Hanafi: step=2
    func computeAsr(step:Double, t:Double) -> Double {
        let D = sunDeclination(jd: JDate + t)
        let X = step + (dtan(d: abs(lat-D)))
        let G = -darccot(x: X)
        return computeTime(G:G, t:t)
    }
    
    //---------------------- Misc Functions -----------------------
    // compute the difference between two times
    func timeDiff(time1:Double, time2:Double) -> Double {
        return fixhour(a: time2 - time1)
    }
    
    //-------------------- Interface Functions --------------------
    // return prayer times for a given date
    func getDatePrayerTimes(year:Int, month:Int, day:Int, latitude:Double, longitude:Double, tZone:Double) -> NSMutableArray {
        lat = latitude
        lng = longitude
        timeZone = tZone
        JDate = julianDate(year: year, month: month, day: day)
        let lonDiff = longitude / (15.0 * 24.0)
        JDate = JDate - lonDiff
        return computeDayTimes()
    }
    
    // return prayer times for a given date
    func getPrayerTimes(date:NSDateComponents, latitude:Double, longitude:Double, tZone:Double) -> NSMutableArray {
        let year = date.year
        let month = date.month
        let day = date.day
        return getDatePrayerTimes(year: year, month: month, day: day, latitude: latitude, longitude: longitude, tZone: tZone)
    }
    
    // set the calculation method
    func setCalcMethod(methodID:CalculationMethod) {
        calcMethod = methodID
    }
    
    // set the juristic method for Asr
    func setAsrMethod(methodID:Int) {
        if (methodID < 0 || methodID > 1) {return}
        asrJuristic = PrayTime.JuristicMethod(rawValue: methodID)!
    }
    
    // set custom values for calculation parameters
    func setCustomParams(params:NSMutableArray) {
        let dic = methodParams as! NSMutableDictionary
        let cust = dic.object(forKey: CalculationMethod.Custom.rawValue) as! NSMutableArray
        let cal = dic.object(forKey: calcMethod) as! NSMutableArray
        for i in 0..<5 {
            let j = params.object(at: i) as! NSNumber
            cust.replaceObject(at: i, with: (j == -1 ? cal : params).object(at: i))
        }
        calcMethod = .Custom
    }
    
    // set the angle for calculating Fajr
    func setFajrAngle(angle:Double) {
        let params = [angle, -1, -1, -1, -1]
        setCustomParams(params: params as! NSMutableArray)
    }
    
    // set the angle for calculating Maghrib
    func setMaghribAngle(angle:Double) {
        let params = [-1, 0, angle, -1, -1]
        setCustomParams(params: params as! NSMutableArray)
    }
    
    // set the angle for calculating Isha
    func setIshaAngle(angle:Double) {
        let params = [-1, -1, -1, 0, angle]
        setCustomParams(params: params as! NSMutableArray)
    }
    
    // set the minutes after mid-day for calculating Dhuhr
    func setDhuhrMinutes(minutes:Double) {
        dhuhrMinutes = Int(minutes)
    }
    
    // set the minutes after Sunset for calculating Maghrib
    func setMaghribMinutes(minutes:Double) {
        let params = [-1, 1, minutes, -1, -1]
        setCustomParams(params: params as! NSMutableArray)
    }
    
    // set the minutes after Maghrib for calculating Isha
    func setIshaMinutes(minutes:Double) {
        let params = [-1, 1, -1, -1, minutes]
        setCustomParams(params: params as! NSMutableArray)
    }
    
    // set adjusting method for higher latitudes
    func setHighLatsMethod(methodID:Int) {
        adjustHighLats = methodID
    }
    
    // set the time format
    func setTimeFormat(tFormat:Int) {
        timeFormat = PrayTime.TimeFormat(rawValue: tFormat)!
    }
    
    // convert double hours to 24h format
    func floatToTime24(time:Double) -> String {
        var result:String? = nil
        if (time.isNaN) { return invalidTime!}
        
        let time = fixhour(a: time + 0.5 / 60.0) // add 0.5 minutes to round
        let hours = floor(time)
        let minutes = floor((time - hours) * 60.0)
        
        if((hours >= 0 && hours <= 9) && (minutes >= 0 && minutes <= 9)) {
            result = String(format: "0%d:0%.0f", hours, minutes)
        }
        else if((hours >= 0 && hours <= 9)) {
            result = String(format:"0%d:%.0f", hours, minutes)
        }
        else if((minutes >= 0 && minutes <= 9)) {
            result = String(format:"%d:0%.0f", hours, minutes)
        }
        else {
            result = String(format:"%d:%.0f", hours, minutes)
        }
        return result!
    }
    
    // convert double hours to 12h format
    func floatToTime12(time:Double, noSuffix:Bool) -> String {
        if (time.isNaN) {return invalidTime!}
        
        let time = fixhour(a: time + 0.5 / 60)  // add 0.5 minutes to round
        var hours = floor(time)
        let minutes = floor((time - hours) * 60)
        var suffix: String? = nil, result: String? = nil
        
        suffix = (hours >= 12 ? "pm" : "am")
        hours = (hours + 12) - 1
        var hrs = hours.truncatingRemainder(dividingBy: 12)
        hrs += 1
        if(noSuffix == false) {
            if((hrs >= 0 && hrs <= 9) && (minutes >= 0 && minutes <= 9)) {
                result = String(format:"0%d:0%.0f %@", hrs, minutes, suffix!)
            }
            else if((hrs >= 0 && hrs <= 9)) {
                result = String(format:"%d:%.0f %@", hrs, minutes, suffix!)
            }
            else if((minutes >= 0 && minutes <= 9)) {
                result = String(format:"%d:0%.0f %@", hrs, minutes, suffix!)
            }
            else {
                result = String(format:"%d:%.0f %@", hrs, minutes, suffix!)
            }
        }
        else {
            if((hrs >= 0 && hrs <= 9) && (minutes >= 0 && minutes <= 9)) {
                result = String(format:"0%d:0%.0f", hrs, minutes)
            }
            else if((hrs >= 0 && hrs <= 9)) {
                result = String(format:"0%d:%.0f", hrs, minutes)
            }
            else if((minutes >= 0 && minutes <= 9)) {
                result = String(format:"%d:0%.0f", hrs, minutes)
            }
            else {
                result = String(format:"%d:%.0f", hrs, minutes)
            }
        }
        return result!
    }
    
    // convert double hours to 12h format with no suffix
    func floatToTime12NS(time:Double ) -> String {
        return floatToTime12(time: time, noSuffix: true)
    }
    
    //---------------------- Compute Prayer Times -----------------------
    // compute prayer times at given julian date
    func computeTimes(times:NSMutableArray) -> NSMutableArray {
        let t = dayPortion(times: times)
        let dic = NSMutableDictionary.init(dictionary: methodParams)
        var a: NSMutableArray? = nil
        if let v = dic.object(forKey: calcMethod) as? NSArray {
            a = v.mutableCopy() as? NSMutableArray
        }
        let idk = a?.object(at: 0) as! Double
        let fajr = computeTime(G:(180 - idk), t: t.object(at:0) as! Double)
        let sunrise = computeTime(G: (180 - 0.833), t: t.object(at: 1) as! Double)
        let dhuhr = computeMidDay(t: t.object(at: 2) as! Double)
        let asr = computeAsr(step: Double(1 + asrJuristic.rawValue), t: t.object(at: 3) as! Double)
        let sunset = computeTime(G: 0.833, t: t.object(at: 4) as! Double)
        let maghrib = computeTime(G: a?.object(at: 2) as! Double, t: t.object(at: 5) as! Double)
        let isha = computeTime(G: a?.object(at: 4) as! Double, t: t.object(at: 6) as! Double)
        
        let Ctimes = NSMutableArray.init(array: [fajr, sunrise, dhuhr, asr, sunset, maghrib, isha])
        //Tune times here
        //Ctimes = [self tuneTimes:Ctimes];
        return Ctimes
    }
    
    // compute prayer times at given julian date
    func computeDayTimes() -> NSMutableArray {
        var t1:NSMutableArray? = nil, t2:NSMutableArray? = nil, t3:NSMutableArray? = nil
        let times = NSMutableArray.init(array: [5.0, 6.0, 12.0, 13.0, 18.0, 18.0, 18.0]) //default times
        
        for _ in 1...numIterations {
            t1 = computeTimes(times: times)
            t2 = adjustTimes(times: t1!)
            t3 = tuneTimes(times: t2!)
        }
        
        //Set prayerTimesCurrent here!!
        prayerTimesCurrent = NSMutableArray.init(array: t2!)
        t3 = adjustTimesFormat(times: t2!)
        return t3!
    }
    
    //Tune timings for adjustments
    //Set time offsets
    func tune(offsetTimes:NSMutableDictionary) {
        offsets?.replaceObject(at: 0, with: offsetTimes.object(forKey: "fajr")!)
        offsets?.replaceObject(at: 1, with: offsetTimes.object(forKey: "sunrise")!)
        offsets?.replaceObject(at: 2, with: offsetTimes.object(forKey: "dhuhr")!)
        offsets?.replaceObject(at: 3, with: offsetTimes.object(forKey: "asr")!)
        offsets?.replaceObject(at: 4, with: offsetTimes.object(forKey: "sunset")!)
        offsets?.replaceObject(at: 5, with: offsetTimes.object(forKey: "maghrib")!)
        offsets?.replaceObject(at: 6, with: offsetTimes.object(forKey: "isha")!)
    }
    
    func tuneTimes(times:NSMutableArray) -> NSMutableArray {
        var off: Double = 0, time: Double = 0
        for i in 0..<times.count {
            off = (offsets?.object(at: i) as! Double) / 60.0
            time = (times.object(at: i) as! Double) + off
            times.replaceObject(at: i, with: time)
        }
        return times
    }
    
    // adjust times in a prayer time array
    func adjustTimes(times:NSMutableArray) -> NSMutableArray {
        let dic = NSMutableDictionary.init(dictionary: methodParams)
        var a: NSMutableArray? = nil
        if let v = dic.object(forKey: calcMethod) as? NSArray {
            a = v.mutableCopy() as? NSMutableArray  //test variable
        }
        
        var time:Double = 0, Dtime:Double = 0, Dtime1:Double = 0, Dtime2:Double = 0
        var times = times
        
        for i in 0..<7 {
            time = (times.object(at: i) as! Double) + (timeZone - lng / 15.0)
            times.replaceObject(at: i, with: time)
        }
        
        Dtime = (times.object(at: 2) as! Double) + (Double(dhuhrMinutes) / 60.0) //Dhuhr
        times.replaceObject(at: 2, with: Dtime)
        
        let val = a?.object(at: 1) as! Double
        
        if (val == 1) { // Maghrib
            Dtime1 = (times.object(at: 4) as! Double) + ((a?.object(at:2) as! Double) / 60.0)
            times.replaceObject(at: 5, with: Dtime1)
        }
        
        let val1 = a?.object(at: 3) as! Double
        if (val1 == 1) { // Isha
            Dtime2 = (times.object(at: 5) as! Double) + ((a?.object(at: 4) as! Double) / 60.0)
            times.replaceObject(at: 6, with: Dtime2)
        }
        
        if (adjustHighLats != CoordinateAdjustment.None.rawValue) {
            times = adjustHighLatTimes(times: times)
        }
        return times
    }
    
    
    // convert times array to given time format
    func adjustTimesFormat(times: NSMutableArray) -> NSMutableArray {
        if (timeFormat.rawValue == TimeFormat.Float.rawValue) {
            return times
        }
        for i in 0..<7 {
            if (timeFormat.rawValue == TimeFormat.Time12.rawValue) {
                times.replaceObject(at: i, with: floatToTime12(time: times.object(at: i) as! Double, noSuffix: false))
            }
            else if (timeFormat.rawValue == TimeFormat.Time12NS.rawValue){
                times.replaceObject(at: i, with: floatToTime12(time: times.object(at: i) as! Double, noSuffix: true))
            }
            else{
                times.replaceObject(at: i, with: floatToTime24(time: times.object(at: i) as! Double))
            }
        }
        return times
    }
    
    
    
    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    func adjustHighLatTimes(times:NSMutableArray) -> NSMutableArray {
        let time0 = times.object(at: 0) as! Double
        let time1 = times.object(at: 1) as! Double
        //let time2 = times.object(at: 2) as! Double
        //let time3 = times.object(at: 3) as! Double
        let time4 = times.object(at: 4) as! Double
        let time5 = times.object(at: 5) as! Double
        let time6 = times.object(at: 6) as! Double
        
        let nightTime = timeDiff(time1: time4, time2: time1) // sunset to sunrise
        let dic = methodParams as! NSMutableDictionary
        let a = dic.object(forKey: calcMethod) as! NSMutableArray
        
        // Adjust Fajr
        let obj0 = a.object(at: 0) as! Double
        let obj1 = a.object(at: 1) as! Double
        let obj2 = a.object(at: 2) as! Double
        let obj3 = a.object(at: 3) as! Double
        let obj4 = a.object(at: 4) as! Double
        
        let FajrDiff = nightPortion(angle: obj0) * nightTime
        
        if ((time0.isNaN) || (timeDiff(time1: time0, time2: time1) > FajrDiff)) {
            times.replaceObject(at: 0, with: time1 - FajrDiff)
        }
        
        // Adjust Isha
        let IshaAngle = (obj3 == 0 ? obj4 : 18)
        let IshaDiff = nightPortion(angle: IshaAngle) * nightTime
        if (time6.isNaN || timeDiff(time1: time4, time2: time6) > IshaDiff) {
            times.replaceObject(at: 6, with: time4 + IshaDiff)
        }
        
        // Adjust Maghrib
        let MaghribAngle = (obj1 == 0 ? obj2 : 4)
        let MaghribDiff = nightPortion(angle: MaghribAngle) * nightTime
        if (time5.isNaN || timeDiff(time1: time4, time2: time5) > MaghribDiff) {
            times.replaceObject(at: 5, with: time4 + MaghribDiff)
        }
        return times
    }
    
    
    // the night portion used for adjusting times in higher latitudes
    func nightPortion(angle:Double) -> Double {
        var calc:Double = 0
        if (adjustHighLats == CoordinateAdjustment.AngleBased.rawValue) {
            calc = (angle) / 60.0
        }
        else if (adjustHighLats == CoordinateAdjustment.MidNight.rawValue) {
            calc = 0.5
        }
        else if (adjustHighLats == CoordinateAdjustment.OneSeventh.rawValue) {
            calc = 0.14286
        }
        return calc
    }
    
    // convert hours to day portions
    func dayPortion(times:NSMutableArray) -> NSMutableArray {
        var time: Double = 0
        for i in 0..<7 {
            time = times.object(at: i) as! Double
            time = time / 24.0
            times.replaceObject(at: i, with: time)
        }
        return times
    }
}
