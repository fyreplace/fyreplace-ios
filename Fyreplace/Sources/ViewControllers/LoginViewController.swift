import GRPC
import ReactiveCocoa
import ReactiveSwift
import UIKit

class LoginViewController: UIViewController {
    @IBOutlet
    var vm: LoginViewModel!
    @IBOutlet
    var email: UITextField!
    @IBOutlet
    var username: UITextField!
    @IBOutlet
    var button: UIButton!
    @IBOutlet
    var loader: UIActivityIndicatorView!
    @IBOutlet
    var privacyPolicy: UIButton!
    @IBOutlet
    var termsOfService: UIButton!

    var isRegistering = true

    override func viewDidLoad() {
        super.viewDidLoad()
        vm.isRegistering.value = isRegistering
        vm.email <~ email.reactive.continuousTextValues
        vm.username <~ username.reactive.continuousTextValues
        button.reactive.isEnabled <~ vm.canProceed
        button.reactive.isHidden <~ vm.isLoading
        loader.reactive.isAnimating <~ vm.isLoading
        privacyPolicy.isHidden = !isRegistering
        termsOfService.isHidden = !isRegistering
        navigationItem.title = .tr("Login." + (isRegistering ? "Register" : "Login"))
        username.isHidden = !isRegistering
        button.setTitle(navigationItem.title, for: .normal)
    }

    @IBAction
    func onEmailDidEndOnExit() {
        if isRegistering {
            username.becomeFirstResponder()
        } else {
            email.resignFirstResponder()
            onLoginPressed()
        }
    }

    @IBAction
    func onUsernameDidEndOnExit() {
        username.resignFirstResponder()
        onLoginPressed()
    }

    @IBAction
    func onLoginPressed() {
        if isRegistering {
            vm.register()
        } else {
            vm.login()
        }
    }

    @IBAction
    func onPrivacyPolicyPressed() {
        URL(string: .tr("Legal.PrivacyPolicy.Url"))?.browse()
    }

    @IBAction
    func onTermsOfServicePressed() {
        URL(string: .tr("Legal.TermsOfService.Url"))?.browse()
    }

    private func askPassword() {
        let alert = UIAlertController(
            title: .tr("Login.Password.Title"),
            message: nil,
            preferredStyle: .alert
        )
        var password = ""
        let ok = UIAlertAction(title: .tr("Ok"), style: .default) { _ in
            self.vm.login(with: password)
        }
        let cancel = UIAlertAction(title: .tr("Cancel"), style: .cancel)

        alert.addTextField {
            $0.textContentType = .password
            $0.returnKeyType = .done
            $0.isSecureTextEntry = true
            $0.reactive.continuousTextValues
                .take(during: $0.reactive.lifetime)
                .observeValues {
                    ok.isEnabled = $0.count > 0
                    password = $0
                }
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
}

extension LoginViewController: LoginViewModelDelegate {
    func onRegister() {
        NotificationCenter.default.post(
            name: FPUser.registrationEmailNotification,
            object: self
        )

        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func onLogin(withPassword: Bool) {
        NotificationCenter.default.post(
            name: withPassword
                ? FPUser.connectionNotification
                : FPUser.connectionEmailNotification,
            object: self
        )

        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func errorKey(for code: Int, with message: String?) -> String? {
        switch GRPCStatus.Code(rawValue: code)! {
        case .cancelled:
            DispatchQueue.main.async { self.askPassword() }
            return nil

        case .notFound:
            return "Login.Error.EmailNotFound"

        case .alreadyExists:
            return "Login.Error.\(message == "email_taken" ? "Email" : "Username")AlreadyExists"

        case .permissionDenied:
            return ["caller_pending", "caller_deleted", "caller_banned", "username_reserved"].contains(message)
                ? "Login.Error.\(message!.pascalized)"
                : "Error.Permission"

        case .invalidArgument:
            return ["invalid_credentials", "invalid_email", "invalid_username", "invalid_password"].contains(message)
                ? "Login.Error.\(message!.pascalized)"
                : "Error.Validation"

        default:
            return "Error"
        }
    }
}
