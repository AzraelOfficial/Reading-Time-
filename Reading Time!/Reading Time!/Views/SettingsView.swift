import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyGoal") private var dailyGoal: Double = 30
    @AppStorage("notifications") private var notificationsEnabled = true
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "timer.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("Daily Reading Goal")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(dailyGoal)) min")
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    
                    // Quick selection buttons in a grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        QuickGoalButton(title: "15m", value: 15, currentGoal: $dailyGoal)
                        QuickGoalButton(title: "30m", value: 30, currentGoal: $dailyGoal)
                        QuickGoalButton(title: "45m", value: 45, currentGoal: $dailyGoal)
                        QuickGoalButton(title: "1h", value: 60, currentGoal: $dailyGoal)
                        QuickGoalButton(title: "1.5h", value: 90, currentGoal: $dailyGoal)
                        QuickGoalButton(title: "2h", value: 120, currentGoal: $dailyGoal)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Reading Goals")
            } footer: {
                Text("Choose a daily reading goal that fits your schedule.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                
                if notificationsEnabled {
                    NavigationLink("Configure Notifications") {
                        NotificationSettingsView()
                    }
                }
            }
            
            Section("About") {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                NavigationLink("Terms of Service") {
                    TermsOfServiceView()
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct QuickGoalButton: View {
    let title: String
    let value: Double
    @Binding var currentGoal: Double
    
    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                currentGoal = value
            }
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private var isSelected: Bool {
        abs(currentGoal - value) < 0.01
    }
}

struct NotificationSettingsView: View {
    @AppStorage("reminderTime") private var reminderTime = Date()
    @AppStorage("weeklyReport") private var weeklyReport = true
    
    var body: some View {
        Form {
            Section("Daily Reminder") {
                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
            
            Section("Reports") {
                Toggle("Weekly Progress Report", isOn: $weeklyReport)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Privacy Policy")
                        .font(.title.bold())
                    
                    Text("Last Updated: \(formattedDate)")
                        .foregroundColor(.secondary)
                    
                    Text("Information We Collect")
                        .font(.headline)
                    Text("Reading Time collects minimal personal information to provide you with the best reading tracking experience. This includes:\n• Reading statistics and goals\n• Book information you input\n• Reading session data\n• Device preferences")
                    
                    Text("How We Use Your Information")
                        .font(.headline)
                    Text("We use your information to:\n• Track your reading progress\n• Provide personalized reading statistics\n• Save your books and notes\n• Maintain your daily reading goals")
                    
                    Text("Data Storage")
                        .font(.headline)
                    Text("All your data is stored locally on your device. If you enable iCloud sync, your data will be stored in your personal iCloud account.")
                }
                
                Group {
                    Text("Third-Party Services")
                        .font(.headline)
                    Text("We use Apple's Sign in with Apple service for authentication. No password information is stored by our app.")
                    
                    Text("Data Protection")
                        .font(.headline)
                    Text("We implement security measures to protect your personal information and reading data. Your data remains on your device unless you explicitly enable cloud sync.")
                    
                    Text("Your Rights")
                        .font(.headline)
                    Text("You can:\n• Access all your data within the app\n• Delete your data at any time\n• Export your reading data\n• Opt out of optional features")
                    
                    Text("Contact Us")
                        .font(.headline)
                    Text("If you have questions about this Privacy Policy, please contact us at support@readingtime.app")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Terms of Service")
                        .font(.title.bold())
                    
                    Text("Last Updated: \(formattedDate)")
                        .foregroundColor(.secondary)
                    
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By using Reading Time, you agree to these Terms of Service. If you disagree with any part of the terms, you may not use our app.")
                    
                    Text("2. User Account")
                        .font(.headline)
                    Text("You are responsible for maintaining the confidentiality of your account and for all activities under your account.")
                    
                    Text("3. User Content")
                        .font(.headline)
                    Text("You retain all rights to the content you add to the app, including book lists, notes, and reading logs.")
                }
                
                Group {
                    Text("4. Acceptable Use")
                        .font(.headline)
                    Text("You agree not to:\n• Misuse the app's services\n• Interfere with the app's functionality\n• Attempt to access data not intended for you\n• Use the app for any illegal purposes")
                    
                    Text("5. Intellectual Property")
                        .font(.headline)
                    Text("Reading Time and its original content, features, and functionality are owned by Reading Time and are protected by international copyright, trademark, and other intellectual property laws.")
                    
                    Text("6. Termination")
                        .font(.headline)
                    Text("We may terminate or suspend your access to the app immediately, without prior notice, for conduct that we believe violates these Terms of Service.")
                    
                    Text("7. Changes to Terms")
                        .font(.headline)
                    Text("We reserve the right to modify these terms at any time. We will notify you of any changes by posting the new Terms of Service on this page.")
                    
                    Text("8. Contact")
                        .font(.headline)
                    Text("For any questions about these Terms of Service, please contact us at support@readingtime.app")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}