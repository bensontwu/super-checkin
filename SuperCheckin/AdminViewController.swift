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

struct PreferencesKeys {
  static let savedItems = "savedItems"
}

class AdminViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
  
  var eventLocations: [EventLocation] = []
  
  let locationManager = CLLocationManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    loadAllEvents()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "addEventLocationSegue" {
      let navigationController = segue.destination as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddEventLocationViewController
      vc.delegate = self
    }
  }
  
  // MARK: Loading and saving functions
  func loadAllEvents() {
    eventLocations.removeAll()
    let allEvents = EventLocation.allEvents()
    allEvents.forEach { add($0) }
  }
  
  func saveAllEvents() {
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(eventLocations)
      UserDefaults.standard.set(data, forKey: PreferencesKeys.savedItems)
    } catch {
      print("error encoding Events")
    }
  }
  
  // MARK: Functions that update the model/associated views with EventLocation changes
  func add(_ eventLocation: EventLocation) {
    eventLocations.append(eventLocation)
    mapView.addAnnotation(eventLocation)
    addRadiusOverlay(forEvent: eventLocation)
    updateEventsCount()
  }
  
  func remove(_ eventLocation: EventLocation) {
    guard let index = eventLocations.index(of: eventLocation) else { return }
    eventLocations.remove(at: index)
    mapView.removeAnnotation(eventLocation)
    removeRadiusOverlay(forEvent: eventLocation)
    updateEventsCount()
  }
  
  func updateEventsCount() {
    title = "Events: \(eventLocations.count)"
    navigationItem.rightBarButtonItem?.isEnabled = (eventLocations.count < 20)
  }
  
  func region(with eventLocation: EventLocation) -> CLCircularRegion {
    // 1
    let region = CLCircularRegion(center: eventLocation.coordinate,
                                  radius: eventLocation.radius,
                                  identifier: eventLocation.identifier)
    // 2
//    region.notifyOnEntry = (eventLocation.eventType == .onEntry)
//    region.notifyOnExit = !region.notifyOnEntry
    return region
  }
  
  func startMonitoring(eventLocation: EventLocation) {
    // 1
    if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
      showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
      return
    }
    // 2
    if CLLocationManager.authorizationStatus() != .authorizedAlways {
      let message = """
        Your EventLocation is saved but will only be activated once you grant
        Geotify permission to access the device location.
        """
      showAlert(withTitle:"Warning", message: message)
    }
    // 3
    let fenceRegion = region(with: eventLocation)
    // 4
    locationManager.startMonitoring(for: fenceRegion)
  }
  
  func stopMonitoring(eventLocation: EventLocation) {
    for region in locationManager.monitoredRegions {
      guard let circularRegion = region as? CLCircularRegion,
        circularRegion.identifier == eventLocation.identifier else { continue }
      locationManager.stopMonitoring(for: circularRegion)
    }
  }
  
  
  
  // MARK: Map overlay functions
  func addRadiusOverlay(forEvent eventLocation: EventLocation) {
    mapView?.add(MKCircle(center: eventLocation.coordinate, radius: eventLocation.radius))
  }
  
  func removeRadiusOverlay(forEvent eventLocation: EventLocation) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    guard let overlays = mapView?.overlays else { return }
    for overlay in overlays {
      guard let circleOverlay = overlay as? MKCircle else { continue }
      let coord = circleOverlay.coordinate
      if coord.latitude == eventLocation.coordinate.latitude && coord.longitude == eventLocation.coordinate.longitude && circleOverlay.radius == eventLocation.radius {
        mapView?.remove(circleOverlay)
        break
      }
    }
  }
  
  // MARK: - Button Actions
  
  @IBAction func zoomToCurrentLocation(sender: UIBarButtonItem) {
    mapView.zoomToUserLocation()
  }
  
  @IBAction func signOutButtonTapped(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true, completion: nil)
  }
  
  
}

// MARK: AddEventViewControllerDelegate
extension AdminViewController: AddEventLocationViewControllerDelegate {
  
  func addEventLocationViewController(
    _ controller: AddEventLocationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
    radius: Double, identifier: String, note: String, startTime: Date, endTime: Date
  ) {
    controller.dismiss(animated: true, completion: nil)
    // 1
    let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
    let eventLocation = EventLocation(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, startTime: startTime, endTime: endTime)
    add(eventLocation)
    // 2
    startMonitoring(eventLocation: eventLocation)
    saveAllEvents()
  }
  
}

// MARK: - Location Manager Delegate
extension AdminViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .authorizedAlways)
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?,
                       withError error: Error) {
    print("Monitoring failed for region with identifier: \(region!.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location Manager failed with the following error: \(error)")
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
    stopMonitoring(eventLocation: eventLocation)
    remove(eventLocation)
    saveAllEvents()
  }
  
}
