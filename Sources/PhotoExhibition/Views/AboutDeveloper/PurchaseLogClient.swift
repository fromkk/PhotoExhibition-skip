#if SKIP
import SkipFirebaseAuth
import SkipFirebaseFirestore
#else
import FirebaseAuth
import FirebaseFirestore
#endif
import Foundation

struct PurchaseLogClient: Sendable {
    var purchased: @Sendable (_ productId: String) -> Void
}

extension PurchaseLogClient {
    static let liveValue: PurchaseLogClient = Self(
        purchased: { productId in
            Task {
                guard let uid = Auth.auth().currentUser?.uid else {
                    return
                }
                let now = Date()
                Firestore.firestore().collection("members")
                    .document(uid)
                    .collection("purchase")
                    .addDocument(data: [
                      "result": true,
                      "userIdentity": uid,
                      "productIdentifier": productId,
                      "createdAt": now.timeIntervalSince1970,
                      "updatedAt": now.timeIntervalSince1970
                    ])
            }
        }
    )
}
