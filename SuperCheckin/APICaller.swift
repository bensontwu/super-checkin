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
    static let ref = db.collection("eventLocations")
    
    static func makeGetRequest(completion: @escaping ([EventLocation]?, Error?) -> ()) {
        ref.getDocuments() { (querySnapshot, err) in
            if err != nil {
                completion(nil, err)
            } else {
                var eventLocs: [EventLocation] = []
                for document in querySnapshot!.documents {
                    if let eventLoc = getEvent(document: document) {
                        eventLocs.append(eventLoc)
                    } else {
                        continue
                    }
                }
                completion(eventLocs, nil)
            }
        }
    }
    
    static func makeAddRequest(eventLocation: EventLocation, completion: @escaping (Error?) -> ()) {
        ref.document(eventLocation.id).setData(eventLocation.getData()) { err in
            completion(err)
        }
    }
    
    static func makeDeleteRequest(id: String, completion: @escaping (Error?) -> ()) {
        ref.document(id).delete() { err in
            completion(err)
        }
    }
    
    static func getEvent(document: QueryDocumentSnapshot) -> EventLocation? {
        let data = document.data()
        guard let geo = data["coordinate"] as? GeoPoint,
            let radius = data["radius"] as? Double,
            let name = data["name"] as? String,
            let start = data["start"] as? Timestamp,
            let end = data["end"] as? Timestamp
        else {
            print("Something went wrong in getEvent")
            return nil
        }
        let coord = CLLocationCoordinate2D(latitude: geo.latitude, longitude: geo.longitude)
        let eventLoc = EventLocation(coordinate: coord, radius: radius, id: document.documentID, name: name, startTime: start.dateValue(), endTime: end.dateValue())
        return eventLoc
    }
}
