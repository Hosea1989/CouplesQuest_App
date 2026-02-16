import SwiftUI
import SwiftData
import AVFoundation
import Supabase

/// Sheet for joining a party or inviting someone to your existing party.
/// Provides QR scanning and manual code entry, then waits for the other player to accept.
struct JoinPartySheet: View {
    /// Controls label variations:
    /// - `.create`: solo player creating a new party by inviting their first ally
    /// - `.invite`: existing party member inviting someone new
    enum Mode {
        case create
        case invite
    }
    
    var mode: Mode = .create
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    // Manual code entry
    @State private var manualCode: String = ""
    @State private var isSendingCode = false
    
    // QR scan confirmation
    @State private var scannedPairingData: PairingData?
    @State private var showJoinConfirmation = false
    @State private var isLinking = false
    
    // Scanner waiting state (after sending request, waiting for displayer to accept)
    @State private var waitingForAcceptance = false
    @State private var waitingPartnerName: String = ""
    
    // Realtime subscriptions + polling fallback
    @State private var pairingChannel: RealtimeChannelV2?
    @State private var pairingPollTimer: Timer?
    
    // Error handling
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showRequestSent = false
    
    // Paired partner info (for celebration)
    @State private var pairedPartnerName: String = ""
    @State private var pairedPartnerAvatar: String?
    @State private var pairedPartnerLevel: Int = 1
    @State private var pairedPartnerClass: String?
    
    // Celebration overlay
    @State private var showCelebration = false
    @State private var showCelebTitle = false
    @State private var showCelebAvatars = false
    @State private var showCelebInfo = false
    @State private var showCelebButton = false
    
    // Dot animation
    @State private var dotPhase: Int = 0
    
    private let supabase = SupabaseService.shared
    
    private var character: PlayerCharacter? { characters.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        if waitingForAcceptance {
                            scannerWaitingView
                        } else {
                            // QR Scanner
                            if AVCaptureDevice.default(for: .video) != nil {
                                Text("Scan Ally's QR Code")
                                    .font(.custom("Avenir-Medium", size: 16))
                                    .foregroundColor(.secondary)
                                    .padding(.top)
                                
                                QRScannerView { scannedString in
                                    handleScannedCode(scannedString)
                                }
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color("AccentGold").opacity(0.3), lineWidth: 2)
                                )
                                .padding(.horizontal)
                                
                                Text("Point your camera at your ally's QR code")
                                    .font(.custom("Avenir-Medium", size: 14))
                                    .foregroundColor(.secondary)
                                
                                // Divider
                                HStack {
                                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                                    Text("or")
                                        .font(.custom("Avenir-Medium", size: 13))
                                        .foregroundColor(.secondary)
                                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                                }
                                .padding(.horizontal, 32)
                            }
                            
                            // Manual code entry
                            manualCodeEntry
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                }
                .background(Color("BackgroundTop").ignoresSafeArea())
                .navigationTitle(mode == .invite ? "Invite to Party" : "Create a Party")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            Task { await cleanupSubscription() }
                            dismiss()
                        }
                        .foregroundColor(Color("AccentGold"))
                    }
                }
                .alert("Pairing Error", isPresented: $showError) {
                    Button("OK") { }
                } message: {
                    Text(errorMessage ?? "Something went wrong.")
                }
                .alert("Invite Sent!", isPresented: $showRequestSent) {
                    Button("OK") { }
                } message: {
                    Text("Your invite has been sent! They'll need to accept it to join the party.")
                }
                .alert("Invite to Party?", isPresented: $showJoinConfirmation) {
                    Button("Invite", role: nil) {
                        confirmJoinParty()
                    }
                    Button("Cancel", role: .cancel) {
                        scannedPairingData = nil
                    }
                } message: {
                    if let data = scannedPairingData {
                        Text("Invite \(data.name) to your party?\nLevel \(data.level) \(data.characterClass ?? "Adventurer")")
                    }
                }
                .onAppear {
                    startDotAnimation()
                }
                .onDisappear {
                    Task { await cleanupSubscription() }
                }
                
                if showCelebration {
                    pairingCelebrationOverlay
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
        }
    }
    
    // MARK: - Scanner Waiting View
    
    private var scannerWaitingView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            
            Image(systemName: "person.wave.2.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentGold"))
                .symbolEffect(.pulse, options: .repeating)
            
            Text("Invite Sent!")
                .font(.custom("Avenir-Heavy", size: 22))
                .foregroundColor(.primary)
            
            Text("Waiting for \(waitingPartnerName) to accept...")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color("AccentGold"))
                        .frame(width: 8, height: 8)
                        .opacity(dotPhase == index ? 1.0 : 0.3)
                }
            }
            
            Button {
                waitingForAcceptance = false
                scannedPairingData = nil
                Task { await cleanupSubscription() }
            } label: {
                Text("Cancel")
                    .font(.custom("Avenir-Medium", size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Manual Code Entry
    
    private var manualCodeEntry: some View {
        VStack(spacing: 16) {
            if AVCaptureDevice.default(for: .video) == nil {
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.4))
                    .padding(.top, 24)
                
                Text("No camera available")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(.secondary)
                
                Text("Enter your ally's code instead")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary.opacity(0.8))
            } else {
                Text("Enter Ally's Code")
                    .font(.custom("Avenir-Heavy", size: 15))
            }
            
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color("AccentGold"))
                    .frame(width: 20)
                
                TextField("e.g. ABC123", text: $manualCode)
                    .font(.custom("Avenir-Heavy", size: 18))
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: manualCode) { _, newValue in
                        manualCode = String(newValue.prefix(6)).uppercased()
                    }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
            )
            
            Button(action: linkManualCode) {
                HStack(spacing: 8) {
                    if isSendingCode {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "link.badge.plus")
                        Text("Send Invite")
                    }
                }
                .font(.custom("Avenir-Heavy", size: 15))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(manualCode.count < 6 || isSendingCode)
            .opacity(manualCode.count < 6 ? 0.5 : 1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Manual Code Send
    
    private func linkManualCode() {
        isSendingCode = true
        errorMessage = nil
        Task {
            do {
                try await supabase.sendPartnerRequest(toCode: manualCode)
                await MainActor.run {
                    character?.completeBreadcrumb("inviteFriend")
                    manualCode = ""
                    isSendingCode = false
                    showRequestSent = true
                }
            } catch {
                await MainActor.run {
                    isSendingCode = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Handle Scanned Code
    
    private func handleScannedCode(_ code: String) {
        guard let pairingData = PairingData.fromJSON(code) else {
            errorMessage = "Invalid QR code. Make sure you're scanning a Swords & Chores pairing code."
            showError = true
            return
        }
        guard let character = character else {
            errorMessage = "Please create a character first."
            showError = true
            return
        }
        if pairingData.characterID == character.id.uuidString {
            errorMessage = "You can't pair with yourself!"
            showError = true
            return
        }
        if character.partyMembers.count >= 3 {
            errorMessage = "Your party is full! (Max 4 members)"
            showError = true
            return
        }
        guard pairingData.supabaseUserID != nil else {
            errorMessage = "This QR code is missing pairing info. Ask your ally to regenerate it."
            showError = true
            return
        }
        scannedPairingData = pairingData
        showJoinConfirmation = true
    }
    
    // MARK: - Confirm Join (QR)
    
    private func confirmJoinParty() {
        guard let pairingData = scannedPairingData,
              let character = character,
              let partnerSupabaseID = pairingData.supabaseUserID,
              let partnerUUID = UUID(uuidString: partnerSupabaseID) else {
            scannedPairingData = nil
            return
        }
        
        isLinking = true
        
        Task {
            do {
                try await supabase.sendPartnerRequest(toUserID: partnerUUID)
                
                await MainActor.run {
                    character.completeBreadcrumb("inviteFriend")
                    isLinking = false
                    waitingForAcceptance = true
                    waitingPartnerName = pairingData.name
                    subscribeForAcceptance()
                }
            } catch {
                await MainActor.run {
                    isLinking = false
                    scannedPairingData = nil
                    errorMessage = "Failed to send request: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Wait for Acceptance
    
    private func subscribeForAcceptance() {
        if pairingChannel == nil {
            Task {
                pairingChannel = await supabase.subscribeForPairingDetection { profile in
                    Task { @MainActor in
                        await handlePartnerDetected(profile: profile)
                    }
                }
            }
        }
        startAcceptancePoll()
    }
    
    private func startAcceptancePoll() {
        pairingPollTimer?.invalidate()
        pairingPollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                guard !showCelebration else {
                    stopPoll()
                    return
                }
                await pollForAcceptance()
            }
        }
    }
    
    private func stopPoll() {
        pairingPollTimer?.invalidate()
        pairingPollTimer = nil
    }
    
    @MainActor
    private func pollForAcceptance() async {
        guard waitingForAcceptance else { return }
        await supabase.fetchProfile()
        if let profile = supabase.currentProfile, profile.partnerID != nil {
            await handlePartnerDetected(profile: profile)
        }
    }
    
    @MainActor
    private func handlePartnerDetected(profile: Profile) async {
        guard let partnerID = profile.partnerID else { return }
        
        if let character = character {
            do {
                if let partnerProfile = try await supabase.fetchPartnerProfile() {
                    let pairingData = PairingData(
                        characterID: partnerProfile.id.uuidString,
                        name: partnerProfile.characterName ?? "Partner",
                        level: partnerProfile.level ?? 1,
                        characterClass: partnerProfile.characterClass,
                        avatarName: partnerProfile.avatarName
                    )
                    character.linkPartner(data: pairingData)
                    
                    if let existingBond = bonds.first {
                        existingBond.addMember(partnerID)
                    } else {
                        let newBond = Bond(memberIDs: [character.id, partnerID])
                        newBond.leaderID = character.id
                        modelContext.insert(newBond)
                    }
                    
                    pairedPartnerName = partnerProfile.characterName ?? "Partner"
                    pairedPartnerAvatar = partnerProfile.avatarName
                    pairedPartnerLevel = partnerProfile.level ?? 1
                    pairedPartnerClass = partnerProfile.characterClass
                }
            } catch {
                pairedPartnerName = "Partner"
            }
        }
        
        waitingForAcceptance = false
        triggerCelebration()
    }
    
    // MARK: - Cleanup
    
    private func cleanupSubscription() async {
        await supabase.unsubscribeChannel(pairingChannel)
        pairingChannel = nil
        stopPoll()
        waitingForAcceptance = false
    }
    
    // MARK: - Dot Animation
    
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
    
    // MARK: - Celebration
    
    private func triggerCelebration() {
        AudioManager.shared.play(.partnerPaired)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.3)) { showCelebration = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { showCelebTitle = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) { showCelebAvatars = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) { showCelebInfo = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) { showCelebButton = true }
        }
    }
    
    private var pairingCelebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { }
            
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 10...24)))
                    .foregroundColor(Color("AccentGold").opacity(showCelebTitle ? Double.random(in: 0.3...0.8) : 0))
                    .offset(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -250...250))
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.5...2.5))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...0.8)),
                        value: showCelebTitle
                    )
            }
            
            VStack(spacing: 28) {
                Spacer()
                
                if showCelebTitle {
                    Text(mode == .invite ? "ALLY JOINED!" : "PARTY FORMED!")
                        .font(.custom("Avenir-Heavy", size: 40))
                        .foregroundStyle(
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        )
                        .scaleEffect(showCelebTitle ? 1.0 : 0.3)
                        .shadow(color: Color("AccentGold").opacity(0.5), radius: 12)
                }
                
                if showCelebAvatars {
                    HStack(spacing: 20) {
                        VStack(spacing: 6) {
                            avatarCircle(icon: character?.avatarIcon ?? "person.fill", color: Color("AccentGold"))
                            Text(character?.name ?? "You")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                        Image(systemName: "link")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("AccentGold"))
                            .shadow(color: Color("AccentGold").opacity(0.5), radius: 6)
                        VStack(spacing: 6) {
                            avatarCircle(icon: pairedPartnerAvatar ?? "person.fill", color: Color("AccentPink"))
                            Text(pairedPartnerName)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                if showCelebInfo {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Label("Lv.\(pairedPartnerLevel)", systemImage: "star.fill")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(Color("AccentGold"))
                            if let cls = pairedPartnerClass {
                                Label(cls.capitalized, systemImage: "shield.fill")
                                    .font(.custom("Avenir-Heavy", size: 14))
                                    .foregroundColor(Color("AccentPurple"))
                            }
                        }
                        Text("Start sharing tasks and questing together!")
                            .font(.custom("Avenir-Medium", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                if showCelebButton {
                    Button {
                        Task { await cleanupSubscription() }
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                            Text("Let's Quest!")
                        }
                        .font(.custom("Avenir-Heavy", size: 18))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 48)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
            }
        }
    }
    
    private func avatarCircle(icon: String, color: Color) -> some View {
        ZStack {
            Circle().fill(color.opacity(0.2)).frame(width: 72, height: 72)
            Circle().stroke(color, lineWidth: 3).frame(width: 72, height: 72)
            if UIImage(named: icon) != nil {
                Image(icon).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle())
            } else {
                Image(systemName: icon).font(.system(size: 30)).foregroundColor(color)
            }
        }
    }
}
