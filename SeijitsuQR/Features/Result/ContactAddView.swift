import Contacts
import ContactsUI
import SwiftUI

extension ContactCard {
    /// Builds a new contact for the system "New Contact" screen. The note field is left out:
    /// writing it requires a restricted entitlement (com.apple.developer.contacts.notes).
    func makeContact() -> CNMutableContact {
        let contact = CNMutableContact()
        if let familyName { contact.familyName = familyName }
        if let givenName { contact.givenName = givenName }
        if familyName == nil, givenName == nil, let formattedName { contact.givenName = formattedName }
        if let phoneticName { contact.phoneticFamilyName = phoneticName }
        if let organization { contact.organizationName = organization }
        if let jobTitle { contact.jobTitle = jobTitle }
        contact.phoneNumbers = phoneNumbers.map { CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: $0)) }
        contact.emailAddresses = emails.map { CNLabeledValue(label: CNLabelOther, value: $0 as NSString) }
        contact.urlAddresses = urls.map { CNLabeledValue(label: CNLabelURLAddressHomePage, value: $0 as NSString) }
        contact.postalAddresses = addresses.map { line in
            let address = CNMutablePostalAddress()
            address.street = line
            return CNLabeledValue(label: CNLabelOther, value: address)
        }
        return contact
    }
}

/// A card waiting to be shown in the "New Contact" screen (sheet item).
struct ContactRequest: Identifiable {
    let id = UUID()
    let card: ContactCard
}

/// The system "New Contact" screen, prefilled from the scanned card. Saving is done by the user there.
struct ContactAddView: UIViewControllerRepresentable {
    let card: ContactCard
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = CNContactViewController(forNewContact: card.makeContact())
        controller.delegate = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ controller: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency CNContactViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onFinish()
        }
    }
}
