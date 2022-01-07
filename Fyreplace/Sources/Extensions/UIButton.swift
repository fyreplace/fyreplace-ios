import UIKit
import SDWebImage

extension UIButton {
    func setUsername(_ profile: FPProfile) {
        guard !profile.isAvailable, let font = titleLabel?.font else {
            return setTitle(profile.username, for: .normal)
        }

        setAttributedTitle(profile.getNormalizedUsername(with: font), for: .normal)
    }

    func setAvatar(_ url: String?) {
        let defaultImage = UIImage(called: "person.crop.circle.fill")

        if let url = url {
            sd_setImage(with: URL(string: url), for: .normal, placeholderImage: defaultImage)
        } else {
            setImage(defaultImage, for: .normal)
        }
    }
}
