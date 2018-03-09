import UIKit
import Alamofire
import SwiftyJSON
import GoogleMaps

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var mapView: GMSMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var routeCollectionView: UICollectionView!
    
    var routeArr: [JSON] = []
    var maxCount: Int = 0
    
    var lat: CLLocationDegrees = CLLocationDegrees()
    var lon: CLLocationDegrees = CLLocationDegrees()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.callFirstRouteWebservice()
    }

    // MARK: - Custom Methods
    
    func callRouteWebservice(urlStr: String) {
        WebserviceHandler.shared.callWebservice(self, method: .get, url: urlStr, parameter: nil) { (statusCode, json, error) in
            if json != nil {
                if json?["Message"].stringValue == "OK" {
                    if self.maxCount == 0 {
                        self.maxCount = json!["MaxCount"].intValue
                        self.callRemainingRouteWebservice()
                        self.drawPolyline(ifFirst: true, shapesArr: json!["ShapeList"].arrayValue)
                    }else{
                        self.drawPolyline(ifFirst: false, shapesArr: json!["ShapeList"].arrayValue)
                    }
                }
            }else{
                Utility.shared.showAlertMessageWithTitle(controller: self, message: "Could not get response. Please try again later", title: "Error")
            }
        }
    }
    
    func callFirstRouteWebservice() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.activityIndicator.isHidden = true
            self.routeCollectionView.reloadData()
        }
        self.callRouteWebservice(urlStr: "http://107.180.68.111:84/ZIGAPICleveland/api/Trip/GetAllShapes?Page=0")
    }
    
    func callRemainingRouteWebservice() {
        for index in 1...maxCount - 1 {
            DispatchQueue.main.async {
                self.callRouteWebservice(urlStr: "http://107.180.68.111:84/ZIGAPICleveland/api/Trip/GetAllShapes?Page=\(index)")
            }
        }
    }
    
    func drawPolyline(ifFirst: Bool, shapesArr: [JSON]) {
        for shape in shapesArr {
            let path = GMSMutablePath()
            for newShape in shape["Newshapes"].arrayValue {
                path.add(CLLocationCoordinate2D(latitude: newShape["Lat"].doubleValue, longitude: newShape["Long"].doubleValue))
            }
            let route: GMSPolyline = GMSPolyline(path: path)
            route.strokeColor = shape["RouteColor"].stringValue.characters.count != 0 ? UIColor.hexStringToUIColor(hex: shape["RouteColor"].stringValue) : UIColor.random()
            route.strokeWidth = 4
            route.geodesic = true
            route.title = shape["ShapeID"].stringValue
            route.map = self.mapView
            
            self.routeArr.append(shape)
        }
        if ifFirst {
            let camera = GMSCameraPosition.camera(withLatitude: shapesArr[0]["Newshapes"][0]["Lat"].doubleValue, longitude: shapesArr[0]["Newshapes"][0]["Long"].doubleValue, zoom:10)
            self.mapView.animate(to: camera)
            self.routeCollectionView.reloadData()
        }
    }
    
    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        self.routeCollectionView.reloadData()
    }
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return routeArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: RouteCell = collectionView.dequeueReusableCell(withReuseIdentifier: "RouteCell", for: indexPath) as! RouteCell
        cell.routeNameLabel.text = "Route : \(indexPath.row + 1)"
        cell.routeNameLabel.font = cell.routeNameLabel.font.withSize(15)
        cell.routeColorLabel.backgroundColor = routeArr[indexPath.row]["RouteColor"].stringValue.characters.count != 0 ? UIColor.hexStringToUIColor(hex: routeArr[indexPath.row]["RouteColor"].stringValue) : UIColor.random()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell: RouteCell = collectionView.cellForItem(at: indexPath) as? RouteCell {
            cell.routeNameLabel.font = cell.routeNameLabel.font.withSize(15)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell: RouteCell = collectionView.cellForItem(at: indexPath) as! RouteCell
        cell.routeNameLabel.font = cell.routeNameLabel.font.withSize(20)
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        let latitude: CLLocationDegrees = CLLocationDegrees(exactly: routeArr[indexPath.row]["Newshapes"][0]["Lat"].doubleValue)!
        let longitude: CLLocationDegrees = CLLocationDegrees(exactly: routeArr[indexPath.row]["Newshapes"][0]["Long"].doubleValue)!
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom:10)
        self.mapView.animate(to: camera)
    }
    
}

