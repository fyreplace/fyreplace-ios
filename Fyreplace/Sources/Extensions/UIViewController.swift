import UIKit

extension UIViewController {
    func presentBasicAlert(text: String, feedback: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        let alert = UIAlertController(title: .tr("\(text).Title"), message: .tr("\(text).Message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: .tr("Ok"), style: .default))
        DispatchQueue.main.async {
            feedbackGenerator.notificationOccurred(feedback)
            self.present(alert, animated: true)
        }
    }

    func presentChoiceAlert(text: String, dangerous: Bool, handler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: .tr("\(text).Title"), message: .tr("\(text).Message"), preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: .tr("Yes"),
                style: dangerous ? .destructive : .default
            ) { _ in handler(true) }
        )
        alert.addAction(
            UIAlertAction(
                title: .tr("No"),
                style: .cancel
            ) { _ in handler(false) }
        )
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }
}
