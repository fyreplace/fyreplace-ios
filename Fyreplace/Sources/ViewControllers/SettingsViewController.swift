import UIKit
import ReactiveSwift
import SwiftProtobuf
import GRPC
import SDWebImage

class SettingsViewController: UITableViewController {
    @IBOutlet
    var vm: SettingsViewModel!
    @IBOutlet
    var imageSelector: ImageSelector!
    @IBOutlet
    var avatar: UIImageView!
    @IBOutlet
    var username: UILabel!
    @IBOutlet
    var dateJoined: UILabel!
    @IBOutlet
    var email: UILabel!
    @IBOutlet
    var bio: UILabel!

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        avatar.sd_imageTransition = .fade
        avatar.reactive.isUserInteractionEnabled <~ vm.user.map { $0 != nil }
        username.reactive.text <~ vm.user.map { $0?.username ?? .tr("Settings.Username") }
        dateJoined.reactive.text <~ vm.user.map(\.?.dateJoined).map { [unowned self] in
            $0 != nil ? dateFormatter.string(from: $0!.date) : ""
        }
        email.reactive.text <~ vm.user.map(\.?.email)
        bio.reactive.text <~ vm.user.map { ($0?.bio.count ?? 0) > 0 ? $0!.bio : .tr("Settings.Bio") }
        vm.user.producer.startWithValues(onUserChanged(_:))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let loginViewController = segue.destination as? LoginViewController {
            loginViewController.isRegistering = segue.identifier == "Register"
        }
    }

    @IBAction
    func onAvatarPressed() {
        imageSelector.selectImage(canRemove: vm.user.value?.hasAvatar ?? false)
    }

    private func onUserChanged(_ user: FPUser?) {
        DispatchQueue.main.async { self.avatar.setAvatar(user?.avatar.url) }
        reloadTable()
    }

    private func reloadTable() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
}

extension SettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        let count = super.numberOfSections(in: tableView)
        return vm.user.value != nil ? count - 1 : count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shouldHide(section: section) ? 0 : super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return shouldHide(section: section) ? .leastNonzeroMagnitude : super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return shouldHide(section: section) ? .leastNonzeroMagnitude : super.tableView(tableView, heightForFooterInSection: section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return shouldHide(section: section) ? nil : super.tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return shouldHide(section: section) ? nil : super.tableView(tableView, titleForFooterInSection: section)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard vm.user.value != nil else { return }
        let cell = tableView.cellForRow(at: indexPath)

        switch cell?.tag {
        case 1:
            changePassword()

        case 2:
            changeEmail()

        case 3:
            vm.logout()

        case 4:
            deleteAccount()

        default:
            return
        }
    }

    private func shouldHide(section: Int) -> Bool {
        guard section >= 0, section < tableView.numberOfSections else { return false }
        return (vm.user.value == nil) && (section != tableView.numberOfSections - 1)
    }

    private func changePassword() {
        let alert = UIAlertController(
            title: .tr("Settings.PasswordChange.Title"),
            message: .tr("Settings.PasswordChange.Message"),
            preferredStyle: .alert
        )
        var newPassword: UITextField?
        let update = UIAlertAction(title: .tr("Ok"), style: .default) { [unowned self] _ in
            guard let password = newPassword?.text else { return }
            vm.updatePassword(password: password)
        }
        let cancel = UIAlertAction(title: .tr("Cancel"), style: .cancel)

        alert.addTextField {
            newPassword = $0
            $0.isSecureTextEntry = true
            $0.textContentType = .newPassword
            $0.returnKeyType = .done
            $0.reactive.continuousTextValues.observeValues { update.isEnabled = $0.count > 0 }
        }
        alert.addAction(update)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

    private func changeEmail() {
        let alert = UIAlertController(
            title: .tr("Settings.EmailChange.Title"),
            message: .tr("Settings.EmailChange.Message"),
            preferredStyle: .alert
        )
        var newEmail: UITextField?
        let update = UIAlertAction(title: .tr("Ok"), style: .default) { [unowned self] _ in
            guard let address = newEmail?.text else { return }
            vm.sendEmailUpdateEmail(address: address)
        }
        let cancel = UIAlertAction(title: .tr("Cancel"), style: .cancel)

        alert.addTextField {
            newEmail = $0
            $0.placeholder = .tr("Settings.EmailChange.TextField.Placeholder")
            $0.textContentType = .emailAddress
            $0.keyboardType = .emailAddress
            $0.returnKeyType = .done
            $0.reactive.continuousTextValues.observeValues { update.isEnabled = $0.count > 0 }
        }
        alert.addAction(update)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

    private func deleteAccount() {
        let alert = UIAlertController(title: .tr("Settings.AccountDeletion.Title"), message: .tr("Settings.AccountDeletion.Message"), preferredStyle: .actionSheet)
        let deleteText = String.tr("Settings.AccountDeletion.Action.Delete")
        let delete = UIAlertAction(title: deleteText, style: .destructive) { [unowned self] _ in
            vm.delete()
        }
        let cancel = UIAlertAction(title: .tr("Cancel"), style: .cancel)

        delete.isEnabled = false
        var secondsLeft = 3

        func count() {
            if secondsLeft > 0 {
                let text = String.tr("Settings.AccountDeletion.Action.Delete.Countdown")
                delete.setValue(String.localizedStringWithFormat(text, secondsLeft), forKey: "title")
                secondsLeft -= 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { count() }
            } else {
                delete.setValue(deleteText, forKey: "title")
                delete.isEnabled = true
            }
        }

        count()
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
}

extension SettingsViewController: SettingsViewModelDelegate {
    func onUpdateAvatar() {
    }

    func onUpdatePassword() {
        presentBasicAlert(text: "Settings.PasswordChange.Success")
    }

    func onSendEmailUpdateEmail() {
        presentBasicAlert(text: "Settings.EmailChange.Success")
    }

    func onLogout() {
        clearImageCache()
        reloadTable()
    }

    func onDelete() {
        clearImageCache()
        reloadTable()
        presentBasicAlert(text: "Settings.AccountDeletion.Success")
    }

    func onFailure(_ error: Error) {
        guard let status = error as? GRPCStatus else {
            return presentBasicAlert(text: "Error", feedback: .error)
        }

        let key: String

        switch status.code {
        case .alreadyExists:
            key = "Login.Error.ExistingEmail"

        case .invalidArgument:
            switch status.description {
            case "invalid_email":
                key = "Login.Error.InvalidEmail"

            case "invalid_password":
                key = "Login.Error.InvalidPassword"

            default:
                key = "Error.Validation"
            }

        default:
            key = "Error"
        }

        presentBasicAlert(text: key, feedback: .error)
    }

    private func clearImageCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)
    }
}

extension SettingsViewController: ImageSelectorDelegate {
    static let maxImageSize: Float = 0.5

    func onImageSelected(_ image: Data) {
        vm.updateAvatar(image: image)
    }

    func onImageRemoved() {
        vm.updateAvatar(image: nil)
    }
}
