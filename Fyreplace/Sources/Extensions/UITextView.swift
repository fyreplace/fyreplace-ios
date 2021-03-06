import UIKit

extension UITextView {
    func setComment(_ comment: FPComment, font: UIFont?) {
        attributedText = comment.getNormalizedText(with: font)
        textColor = comment.isDeleted ? .secondaryLabelCompat : .labelCompat
        isSelectable = !comment.isDeleted
    }
}
