//
//  APICaller.swift
//  SuperCheckin
//
//  Created by benson on 1/3/20.
//  Copyright © 2020 Ken Toh. All rights reserved.
//

import Firebase
import CoreLocation

class APICaller {
    static let db = Firestore.firestore()
    
    static func getEvents(completion: @escaping ([EventLocation]?, Error?) -> ()) {
        let ref = db.collection("eventLocations")
        ref.getDocuments() { (querySnapshot, err) in
            if let err = err {
                completion(nil, err)
            } else {
                var eventLocs: [EventLocation] = []
                for document in querySnapshot!.documents {
                    if let eventLoc = getEvent(data: document.data()) {
                        eventLocs.append(eventLoc)
                    } else {
                        continue
                    }
                }
                completion(eventLocs, nil)
            }
        }
    }
    
    static func getEvent(data: [String:Any]) -> EventLocation? {
        guard let geo = data["coordinate"] as? GeoPoint,
            let radius = data["radius"] as? Double,
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let start = data["startTime"] as? Timestamp,
            let end = data["endTime"] as? Timestamp
        else {
            return nil
        }
        let coord = CLLocationCoordinate2D(latitude: geo.latitude, longitude: geo.longitude)
        let eventLoc = EventLocation(coordinate: coord, radius: radius, identifier: id, name: name, startTime: start.dateValue(), endTime: end.dateValue())
        return eventLoc
    }
}
