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

protocol AddEventLocationViewControllerDelegate {
    func addEventLocationViewController(_ controller: AddEventLocationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
                                        radius: Double, id: String, name: String, startTime: Date, endTime: Date)
}

class AddEventLocationViewController: UITableViewController {
    
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var radiusTextField: UITextField!
    @IBOutlet var startTimeTextField: UITextField!
    @IBOutlet var endTimeTextField: UITextField!
    @IBOutlet var mapView: MKMapView!
    
    var delegate: AddEventLocationViewControllerDelegate?
    
    
    // MARK: - View Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = addButton
        addButton.isEnabled = false
        
        // Set up radius picker
        radiusTextField.keyboardType = .numberPad
        
        // Set up time pickers for time text fields
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        startTimeTextField.inputView = datePicker
//        startTimeTextField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEnd)
        endTimeTextField.inputView = datePicker
        
        // Allow for tap to exit keyboard
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        if startTimeTextField.isFirstResponder {
            startTimeTextField.text = dateFormatter.string(from: datePicker.date)
        } else if endTimeTextField.isFirstResponder {
            endTimeTextField.text = dateFormatter.string(from: datePicker.date)
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        addButton.isEnabled = !nameTextField.text!.isEmpty && !radiusTextField.text!.isEmpty && !startTimeTextField.text!.isEmpty && !endTimeTextField.text!.isEmpty
    }
    
    @IBAction func textFieldReturn(sender: UITextField) {
        print("textFieldReturn")
        switch sender {
        case nameTextField:
            radiusTextField.becomeFirstResponder()
        case radiusTextField:
            startTimeTextField.becomeFirstResponder()
        case startTimeTextField:
            endTimeTextField.becomeFirstResponder()
        default:
            sender.resignFirstResponder()
        }
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func onCancel(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onAdd(sender: AnyObject) {
        let coordinate = mapView.centerCoordinate
        let radius = Double(radiusTextField.text!) ?? 0
        let identifier = NSUUID().uuidString
        let name = nameTextField.text ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        guard let startTime = dateFormatter.date(from: startTimeTextField.text ?? ""),
            let endTime = dateFormatter.date(from: endTimeTextField.text ?? "")
        else {
            showAlert(withTitle: "Error", message: "Unable to create event. Please make sure all fields are filled.")
            return
        }
        delegate?.addEventLocationViewController(self, didAddCoordinate: coordinate, radius: radius, id: identifier, name: name, startTime: startTime, endTime: endTime)
    }
    
    @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
        mapView.zoomToUserLocation()
    }
    

}
