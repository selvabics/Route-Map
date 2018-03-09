import UIKit
import Alamofire
import SwiftyJSON

@objc open class WebserviceHandler: NSObject {
    
    static let shared: WebserviceHandler = WebserviceHandler()
    
    private override init() {
        
    }

    func callWebservice(_ controller: UIViewController?, method: HTTPMethod, url : String, parameter :  [String : AnyObject]?, Completion responseHandler : @escaping (Int?, JSON?, Error?) -> Void)
    {
        // Check intenet connection
        if !Utility.shared.connectedToNetwork() {
            
            // Show error message
            Utility.shared.showAlertMessageWithTitle(controller: controller, message: "Information", title: "Internet connection is required")
            responseHandler(nil, nil,nil)
        }else{
            URLCache.shared.removeAllCachedResponses()

            Alamofire.request(url, method: method, parameters: parameter, encoding: JSONEncoding.default, headers: nil).responseJSON() {
                response in
                
                print(url)
                
                switch response.result {
                case .success:
                    var json: JSON!
                    do {
                        json = try JSON(data: response.data!)
                        if (json.null == nil) {
                            responseHandler(response.response?.statusCode, json , response.result.error)
                        } else {
                            responseHandler(response.response?.statusCode, nil, response.result.error)
                        }
                    } catch {
                        print("Error \(error)")
                    }
                    break
                case .failure(_):
                    if response.response?.statusCode == 500 || response.response?.statusCode == 501 {
                        Utility.shared.showAlertMessageWithTitle(controller: controller, message: "Server error. Please contact support team.", title: "Error")
                    }else{
                        responseHandler(response.response?.statusCode, nil,response.result.error)
                    }
                    break
                }
            }
        }
    }
    
}

