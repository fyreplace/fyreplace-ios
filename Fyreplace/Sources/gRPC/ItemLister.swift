import Foundation
import GRPC

@objc
protocol ItemListerProtocol {
    var pageSize: UInt32 { get }

    var itemCount: Int { get }

    func startListing()

    func stopListing()

    func reset()

    func fetchMore()

    func remove(at index: Int)
}

class ItemLister<Item, Items, Service>: ItemListerProtocol
    where Items: ItemBundle, Item == Items.Item,
          Service: ItemListerService, Item == Service.Item,
          Items == Service.Items {
    let pageSize: UInt32 = 12
    var itemCount: Int { items.count }
    private(set) var items: [Item] = []
    private let delegate: ItemListerDelegate
    private let service: Service
    private var stream: BidirectionalStreamingCall<FPPage, Items>?
    private var nextCursor = FPCursor.with { $0.isNext = true }
    private var fetching = false
    private var endReached = false

    init(delegatingTo delegate: ItemListerDelegate, using service: Service) {
        self.delegate = delegate
        self.service = service
    }

    deinit {
        stopListing()
    }

    func startListing() {
        stream = service.listItems(handler: onFetch(items:))
        let header = FPHeader.with {
            $0.forward = false
            $0.size = pageSize
        }
        _ = stream?.sendMessage(.with { $0.header = header })
    }

    func stopListing() {
        _ = stream?.sendEnd()
    }

    func reset() {
        items.removeAll()
        nextCursor = .with { $0.isNext = true }
        fetching = false
        endReached = false
    }

    func fetchMore() {
        guard !endReached, !fetching, let stream = stream else { return }
        fetching = true
        _ = stream.sendMessage(.with { $0.cursor = nextCursor })
    }

    func remove(at index: Int) {
        items.remove(at: index)
    }

    private func onFetch(items: Items) {
        self.items.append(contentsOf: items.items)
        self.nextCursor = items.next

        DispatchQueue.main.async { [self] in
            if !items.hasNext {
                endReached = true
            }

            delegate.onFetch(count: items.items.count)
            fetching = false
        }
    }
}

protocol ItemBundle {
    associatedtype Item

    var items: [Item] { get }
    var previous: FPCursor { get }
    var hasPrevious: Bool { get }
    var next: FPCursor { get }
    var hasNext: Bool { get }
}

protocol ItemListerService {
    associatedtype Item
    associatedtype Items

    func listItems(handler: @escaping (Items) -> Void) -> BidirectionalStreamingCall<FPPage, Items>
}

@objc
protocol ItemListerDelegate {
    func onFetch(count: Int)
}
