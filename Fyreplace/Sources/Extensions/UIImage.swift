import UIKit

extension UIImage {
    convenience init?(called: String) {
        if #available(iOS 13, *) {
            self.init(systemName: called)
        } else {
            self.init(named: called)
        }
    }
}
