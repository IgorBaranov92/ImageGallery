import UIKit

class DocumentTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField! { didSet {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        textField.delegate = self
        }}
        
    var completionHandler: ( () -> Void )?
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.isUserInteractionEnabled = false
        textField.borderStyle = .none
        completionHandler?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @objc private func doubleTap(_ recognizer:UITapGestureRecognizer) {
        if recognizer.state == .ended {
            textField.isUserInteractionEnabled = true
            textField.becomeFirstResponder()
            textField.borderStyle = .roundedRect
        }
    }
    
}
