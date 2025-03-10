import SwiftUI
import ContactsManagerBinary

// Basic Information Section
private struct BasicInfoSection: View {
    let contact: Contact
    
    var body: some View {
        Section("Basic Information") {
            if let displayName = contact.displayName {
                LabeledContent("Name", value: displayName)
            }
            Text(contact.contactType == 1 ? "Organization" : "Person")
                .foregroundStyle(.secondary)
        }
    }
}

// Name Details Section
private struct NameDetailsSection: View {
    let contact: Contact
    
    var body: some View {
        Section("Name Details") {
            if let prefix = contact.namePrefix {
                LabeledContent("Prefix", value: prefix)
            }
            if let givenName = contact.givenName {
                LabeledContent("Given Name", value: givenName)
            }
            if let middleName = contact.middleName {
                LabeledContent("Middle Name", value: middleName)
            }
            if let familyName = contact.familyName {
                LabeledContent("Family Name", value: familyName)
            }
            if let suffix = contact.nameSuffix {
                LabeledContent("Suffix", value: suffix)
            }
            if let nickname = contact.nickname {
                LabeledContent("Nickname", value: nickname)
            }
        }
    }
}

// Organization Section
private struct OrganizationSection: View {
    let contact: Contact
    
    var body: some View {
        if contact.contactType == 1 || contact.organizationName != nil {
            Section("Organization") {
                if let org = contact.organizationName {
                    LabeledContent("Organization", value: org)
                }
                if let dept = contact.departmentName {
                    LabeledContent("Department", value: dept)
                }
                if let title = contact.jobTitle {
                    LabeledContent("Job Title", value: title)
                }
            }
        }
    }
}

// Phone Numbers Section
private struct PhoneNumbersSection: View {
    let contact: Contact
    
    var body: some View {
        if !contact.phoneNumbers.isEmpty {
            Section("Phone Numbers") {
                ForEach(contact.phoneNumbers, id: \.id) { phone in
                    LabeledContent(
                        phone.value ?? "Phone",
                        value: phone.value ?? "Phone Number Not Available"
                    )
                }
            }
        }
    }
}

// Email Addresses Section
private struct EmailAddressesSection: View {
    let contact: Contact
    
    var body: some View {
        if !contact.emailAddresses.isEmpty {
            Section("Email Addresses") {
                ForEach(contact.emailAddresses, id: \.id) { email in
                    LabeledContent(
                        email.value ?? "Email",
                        value: email.value ?? "Email Address Not Available"
                    )
                }
            }
        }
    }
}

// URL Addresses Section
private struct URLAddressesSection: View {
    let contact: Contact
    
    var body: some View {
        if !contact.urlAddresses.isEmpty {
            Section("URLs") {
                ForEach(contact.urlAddresses, id: \.id) { url in
                    LabeledContent(url.value ?? "URL", value: url.value ?? "")
                }
            }
        }
    }
}

// Contact Information Sections
private struct ContactInfoSections: View {
    let contact: Contact
    
    var body: some View {
        Group {
            PhoneNumbersSection(contact: contact)
            EmailAddressesSection(contact: contact)
            URLAddressesSection(contact: contact)
        }
    }
}

// Address Section
private struct AddressSection: View {
    let contact: Contact
    
    var body: some View {
        if !contact.addresses.isEmpty {
            Section("Addresses") {
                ForEach(contact.addresses, id: \.id) { address in
                    VStack(alignment: .leading) {
                        Text(address.display() ?? "Address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(address.display())
                    }
                }
            }
        }
    }
}

// Social Profiles Section
private struct SocialProfilesSection: View {
    let contact: Contact
    
    var body: some View {
        if !contact.socialProfiles.isEmpty {
            Section("Social Profiles") {
                ForEach(contact.socialProfiles, id: \.id) { profile in
                    VStack(alignment: .leading) {
                        Text(profile.service ?? "Social")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(profile.username ?? "")
                    }
                }
            }
        }
    }
}

// Additional Information Section
private struct AdditionalInfoSection: View {
    let contact: Contact
    
    var body: some View {
        if contact.notes != nil || contact.bio != nil {
            Section("Additional Information") {
                if let notes = contact.notes {
                    LabeledContent("Notes", value: notes)
                }
                if let bio = contact.bio {
                    LabeledContent("Bio", value: bio)
                }
            }
        }
    }
}

// Education and Interests Sections
private struct EducationAndInterestsSection: View {
    let contact: Contact
    
    var body: some View {
        Group {
            if !contact.education.isEmpty {
                Section("Education") {
                    ForEach(contact.education, id: \.id) { edu in
                        Text(edu.display())
                    }
                }
            }
            
            if !contact.interests.isEmpty {
                Section("Interests") {
                    ForEach(contact.interests, id: \.self) { interest in
                        Text(interest)
                    }
                }
            }
        }
    }
}

// Main Contact Detail View
struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @State private var showingJSON = false
    
    var body: some View {
        NavigationStack {
            List {
                BasicInfoSection(contact: contact)
                NameDetailsSection(contact: contact)
                OrganizationSection(contact: contact)
                ContactInfoSections(contact: contact)
                AddressSection(contact: contact)
                SocialProfilesSection(contact: contact)
                AdditionalInfoSection(contact: contact)
                EducationAndInterestsSection(contact: contact)
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Show JSON") {
                        showingJSON = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingJSON) {
                ContactJSONView(contact: contact)
            }
        }
    }
}

struct ContactJSONView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(formatJSON())
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Contact JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: formatJSON(),
                        subject: Text("Contact Data - \(contact.displayName ?? "Unknown")"),
                        message: Text("Contact information in JSON format"),
                        preview: SharePreview("Contact JSON")
                    )
                }
            }
        }
    }
    
    private func formatJSON() -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(contact)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "Error encoding JSON: \(error.localizedDescription)"
        }
    }
} 
