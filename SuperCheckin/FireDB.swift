//
//  FireDB.swift
//  SuperCheckin
//
//  Created by benson on 1/4/20.
//

import Foundation

protocol FireDBDelegate {
    func respondToData()
}

class FireDB {
    var delegate: FireDBDelegate?
    
    func startListening() {
        APICaller.addListener() { [weak self] (eventLocs, err) in
            if err != nil {
                return
            } else {
                if let eventLocs = eventLocs {
                    EventLocation.allEvents = eventLocs
                    if let self = self {
                        self.delegate?.respondToData()
                    }
                } else {
                    print("Something went wrong") // TODO: Fix this
                }
            }
        }
    }
    
    func refreshEvents(completion: @escaping (Error?) -> ()) {
        APICaller.makeGetRequest() { (eventLocs, error) in
            if error != nil {
                completion(error)
            } else {
                if let eventLocs = eventLocs {
                    EventLocation.allEvents = eventLocs
                    completion(nil)
                } else {
                    print("Something went wrong") // TODO: Fix this
                }
            }
        }
    }
    
    func addEvent(eventLocation: EventLocation, completion: @escaping (Error?) -> ()) {
        APICaller.makeAddRequest(eventLocation: eventLocation) { err in
            completion(err)
        }
    }
    
    func removeEvent(id: String, completion: @escaping (Error?) -> ()) {
        APICaller.makeDeleteRequest(id: id) { err in
            completion(err)
        }
    }
}
