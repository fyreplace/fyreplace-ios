import GRPC
import ReactiveSwift
import UIKit

class BioViewController: TextInputViewController {
    override var textInputViewModel: TextInputViewModel! { vm }
    override var maxContentLength: Int { 3000 }

    @IBOutlet
    var vm: BioViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        content.text = vm.bio.value
        vm.bio <~ content.reactive.continuousTextValues
    }

    override func onDonePressed() {
        vm.updateBio()
    }
}

extension BioViewController: BioViewModelDelegate {
    func onUpdateBio() {
        DispatchQueue.main.async { self.dismiss(animated: true) }
    }

    func onFailure(_ error: Error) {
        guard let status = error as? GRPCStatus else {
            return presentBasicAlert(text: "Error", feedback: .error)
        }

        let key: String

        switch status.code {
        case .invalidArgument:
            key = content.text.count > maxContentLength
                ? "Bio.Error.TooLong"
                : "Error.Validation"

        default:
            key = "Error"
        }

        presentBasicAlert(text: key, feedback: .error)
    }
}
