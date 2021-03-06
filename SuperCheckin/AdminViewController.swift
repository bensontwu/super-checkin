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
import SVProgressHUD

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

class AdminViewController: UIViewController, FireDBDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var addLocationButton: UIButton!
    @IBOutlet var checkInButton: UIButton!
    @IBOutlet var checkOutButton: UIButton!
    let fireDB = FireDB()
    
    var insideRegions: [String] = [] {
        didSet {
            if insideRegions.isEmpty {
                checkInButton.isEnabled = false
                checkOutButton.isEnabled = false
            } else {
                checkInButton.isEnabled = true
                checkOutButton.isEnabled = true
            }
        }
    }
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        //    loadAllEvents()
        
        checkInButton.isEnabled = false
        checkOutButton.isEnabled = false
        
        for region in locationManager.monitoredRegions {
            locationManager.requestState(for: region)
        }
        
        // Setup buttons
        checkInButton.setBackgroundColor(color: .white, forState: .disabled)
        checkInButton.setBackgroundColor(color: AppColors.green, forState: .normal)
        checkOutButton.setBackgroundColor(color: .white, forState: .disabled)
        checkOutButton.setBackgroundColor(color: AppColors.red, forState: .normal)
        checkInButton.setTitleColor(.white, for: .normal)
        checkInButton.setTitleColor(.gray, for: .disabled)
        checkOutButton.setTitleColor(.white, for: .normal)
        checkOutButton.setTitleColor(.gray, for: .disabled)
        checkInButton.layer.cornerRadius = 8
        checkOutButton.layer.cornerRadius = 8
        
//        SVProgressHUD.show()
//        EventLocation.refreshEvents { [weak self] err in
//            SVProgressHUD.dismiss()
//            if let self = self {
//                if err != nil {
//                    self.showAlert(withTitle: "Error", message: "Failed to refresh events.")
//                } else {
//                    self.refreshMap()
//                }
//            }
//        }
        
        fireDB.delegate = self
        fireDB.startListening()
        
        SVProgressHUD.show()
        fireDB.refreshEvents { [weak self] err in
            SVProgressHUD.dismiss()
            if let self = self {
                if err != nil {
                    self.showAlert(withTitle: "Error", message: "Failed to refresh events.")
                } else {
                    self.refreshMap()
                }
            }
        }
        // TODO: create delegate or something in EventLocation to inform this VC of refresh
    }
    
    
    // MARK: - FireDBDelegate
    
    func respondToData() {
        refreshMap()
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addEventLocationSegue" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! AddEventLocationViewController
            vc.delegate = self
        }
    }
    
    
    // MARK: - Location Monitoring
    
    func updateEventsCount() {
        title = "Events: \(EventLocation.allEvents.count)"
        addLocationButton.isEnabled = (EventLocation.allEvents.count < 20)
    }
    
    func region(with eventLocation: EventLocation) -> CLCircularRegion {
        // 1
        let region = CLCircularRegion(center: eventLocation.coordinate,
                                      radius: eventLocation.radius,
                                      identifier: eventLocation.id)
        // 2
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    func startMonitoring(eventLocation: EventLocation) {
//        // 1
//        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
//            return
//        }
//        // 2
//        if CLLocationManager.authorizationStatus() != .authorizedAlways {
//            let message = """
//        Your EventLocation is saved but will only be activated once you grant
//        SuperCheckin permission to access the device location.
//        """
//            showAlert(withTitle:"Warning", message: message)
//        }
        // 3
        let fenceRegion = region(with: eventLocation)
        // 4
        locationManager.startMonitoring(for: fenceRegion)
    }
    
    func stopMonitoring(eventLocation: EventLocation) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == eventLocation.id else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forEvent eventLocation: EventLocation) {
        mapView?.add(MKCircle(center: eventLocation.coordinate, radius: eventLocation.radius))
    }
    
    func refreshMap() {
        // Reset insideRegions
        insideRegions.removeAll()
        
        // Remove
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Add
        for eventLocation in EventLocation.allEvents {
            self.mapView.addAnnotation(eventLocation)
            self.addRadiusOverlay(forEvent: eventLocation)
            
            self.startMonitoring(eventLocation: eventLocation)
        }
        self.updateEventsCount()
    }
    
    // MARK: - Button Actions
    
    @IBAction func zoomToCurrentLocation(sender: UIBarButtonItem) {
        mapView.zoomToUserLocation()
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func checkInButtonTapped(_ sender: UIButton) {
        showAlert(withTitle: "Check In", message: "insideRegions: \(insideRegions) eventLocations: \(EventLocation.allEvents)")
    }
    
    @IBAction func checkOutButtonTapped(_ sender: UIButton) {
        showAlert(withTitle: "Check Out", message: "insideRegions: \(insideRegions) eventLocations: \(EventLocation.allEvents)")
    }
    
}

// MARK: AddEventViewControllerDelegate
extension AdminViewController: AddEventLocationViewControllerDelegate {
    
    func addEventLocationViewController(
        _ controller: AddEventLocationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
        radius: Double, id: String, name: String, startTime: Date, endTime: Date
    ) {
        controller.dismiss(animated: true, completion: nil)
        // 1
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let eventLocation = EventLocation(coordinate: coordinate, radius: clampedRadius, id: id, name: name, startTime: startTime, endTime: endTime)
        
        // Add event
        SVProgressHUD.show()
        fireDB.addEvent(eventLocation: eventLocation) { [weak self] err in
            SVProgressHUD.dismiss()
            if let self = self {
                if err != nil {
                    self.showAlert(withTitle: "Error", message: "Failed to add event, please try again.")
                } else {
                }
            }
        }
    }
}

// MARK: - Location Manager Delegate
extension AdminViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .authorizedAlways || status == .authorizedWhenInUse)
        print("User location: \(mapView.showsUserLocation)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?,
                         withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            insideRegions.append(region.identifier)
        case .outside:
            if let index = insideRegions.index(of: region.identifier) {
                insideRegions.remove(at: index)
            }
        default:
            return
        }
    }
    
}

// MARK: - MapView Delegate
extension AdminViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myEvent"
        if annotation is EventLocation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteEvent")!, for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete EventLocation
        let eventLocation = view.annotation as! EventLocation
        
        // Remove event
        SVProgressHUD.show()
        fireDB.removeEvent(id: eventLocation.id) { [weak self] err in
            SVProgressHUD.dismiss()
            if let self = self {
                if err != nil {
                    self.showAlert(withTitle: "Error", message: "Failed to delete event, please try again.")
                } else {
                    // Remove from insideRegions as well
                    if let index = self.insideRegions.index(of: eventLocation.id) {
                        self.insideRegions.remove(at: index)
                    }
                }
            }
        }
    }
    
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        self.clipsToBounds = true  // add this to maintain corner radius
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.setBackgroundImage(colorImage, for: forState)
        }
    }
}
