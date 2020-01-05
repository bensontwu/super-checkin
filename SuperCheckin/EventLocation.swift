/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import MapKit
import CoreLocation
import Firebase

class EventLocation: NSObject, /*Codable,*/ MKAnnotation {
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, radius, id, name, startTime, endTime
    }
    
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var id: String
    var name: String
    var startTime: Date
    var endTime: Date
    
    var title: String? {
        if name.isEmpty {
            return "No Note"
        }
        return name
    }
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, id: String, name: String, startTime: Date, endTime: Date) {
        self.coordinate = coordinate
        self.radius = radius
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
    }
    
//    // MARK: Codable
//    required init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        let latitude = try values.decode(Double.self, forKey: .latitude)
//        let longitude = try values.decode(Double.self, forKey: .longitude)
//        coordinate = CLLocationCoordinate2DMake(latitude, longitude)
//        radius = try values.decode(Double.self, forKey: .radius)
//        id = try values.decode(String.self, forKey: .id)
//        name = try values.decode(String.self, forKey: .name)
//        startTime = try values.decode(Date.self, forKey: .startTime)
//        endTime = try values.decode(Date.self, forKey: .endTime)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(coordinate.latitude, forKey: .latitude)
//        try container.encode(coordinate.longitude, forKey: .longitude)
//        try container.encode(radius, forKey: .radius)
//        try container.encode(id, forKey: .id)
//        try container.encode(name, forKey: .name)
//        try container.encode(startTime, forKey: .startTime)
//        try container.encode(endTime, forKey: .endTime)
//    }
    
    func getData() -> [String:Any] {
        var data: [String:Any] = [:]
        data["coordinate"] = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        data["radius"] = radius
        data["name"] = name
        data["start"] = Timestamp(date: startTime)
        data["end"] = Timestamp(date: endTime)
        return data
    }
}

extension EventLocation {
    static var allEvents: [EventLocation] = []
    static var activeEvents: [EventLocation] {
        return allEvents.filter {
            $0.startTime < Date() && Date() < $0.endTime
        }
    }
    
    static func startListening() {
        APICaller.addListener() { (eventLocs, err) in
            if let eventLocs = eventLocs {
                allEvents = eventLocs
            }
        }
    }
    
    static func refreshEvents(completion: @escaping (Error?) -> ()) {
        APICaller.makeGetRequest() { (eventLocs, error) in
            if error != nil {
                completion(error)
            } else {
                if let eventLocs = eventLocs {
                    allEvents = eventLocs
                    completion(nil)
                } else {
                    print("Something went wrong") // TODO: Fix this
                }
            }
        }
    }
    
    static func addEvent(eventLocation: EventLocation, completion: @escaping (Error?) -> ()) {
        APICaller.makeAddRequest(eventLocation: eventLocation) { err in
            completion(err)
        }
    }
    
    static func removeEvent(id: String, completion: @escaping (Error?) -> ()) {
        APICaller.makeDeleteRequest(id: id) { err in
            completion(err)
        }
    }
}

//extension EventLocation {
//  public class func allEvents() -> [EventLocation] {
//    guard let savedData = UserDefaults.standard.data(forKey: PreferencesKeys.savedItems) else { return [] }
//    let decoder = JSONDecoder()
//    if let savedEvents = try? decoder.decode(Array.self, from: savedData) as [EventLocation] {
//      return savedEvents
//    }
//    return []
//  }
//}
