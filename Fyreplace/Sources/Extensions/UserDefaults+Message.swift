import Foundation
import SwiftProtobuf

extension UserDefaults {
    func setValue<M: Message>(_ value: M, forKey key: String) {
        guard let data = try? value.serializedData(partial: false) else { return }
        UserDefaults.standard.setValue(data, forKey: key)
    }

    func message<M: Message>(forKey defaultName: String) -> M? {
        guard let data = UserDefaults.standard.data(forKey: defaultName) else { return nil }
        return try? M(serializedData: data)
    }
}

