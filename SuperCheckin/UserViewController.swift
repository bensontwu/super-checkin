//
//  UserViewController.swift
//  Geotify
//
//  Created by benson on 1/2/20.
//  Copyright © 2020 Ken Toh. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class UserViewController: UIViewController {
  
  let locationManager = CLLocationManager()
  
  // MARK: - Properties
  
  @IBOutlet var mapView: MKMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    // Do any additional setup after loading the view.
  }
  
  
  // MARK: - Button Actions
  
  @IBAction func zoomToCurrentLocation(_ sender: Any) {
    mapView.zoomToUserLocation()
  }
  
  @IBAction func signOutButtonTapped(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true, completion: nil)
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
}

// MARK: - Location Manager Delegate
extension UserViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .authorizedAlways)
  }
}
