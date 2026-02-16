import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import AVFoundation
import Supabase

struct QRPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var selectedTab: PairingTab = .showQR
    @State private var pairedPartnerName: String = ""
    @State private var pairedPartnerAvatar: String?
    @State private var pairedPartnerLevel: Int = 1
    @State private var pairedPartnerClass: String?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var manualCode: String = ""
    @State private var isSendingCode = false
    @State private var waitingForPartner = false
    @State private var showRequestSent = false
    @State private var requestSentPartnerName: String?
    
    // QR scan confirmation
    @State private var scannedPairingData: PairingData?
    @State private var showJoinConfirmation = false
    @State private var isLinking = false
    
    // Scanner waiting state (after sending request, waiting for displayer to accept)
    @State private var waitingForAcceptance = false
    @State private var waitingPartnerName: String = ""
    
    // Displayer: incoming request detection
    @State private var incomingRequest: PartnerRequest?
    @State private var incomingRequestProfile: Profile?
    @State private var showIncomingRequestDialog = false
    
    // Realtime subscriptions + polling fallback
    @State private var pairingChannel: RealtimeChannelV2?
    @State private var requestChannel: RealtimeChannelV2?
    @State private var pairingPollTimer: Timer?
    
    // Celebration overlay
    @State private var showCelebration = false
    @State private var showCelebTitle = false
    @State private var showCelebAvatars = false
    @State private var showCelebInfo = false
    @State private var showCelebButton = false
    
    // QR animation states
    @State private var qrGlowPulse = false
    @State private var scanLineOffset: CGFloat = -110
    @State private var dotPhase: Int = 0
    
    private let supabase = SupabaseService.shared
    
    private var character: PlayerCharacter? { characters.first }
    
    enum PairingTab {
        case showQR
        case scanQR
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        tabButton("Show My Code", tab: .showQR, icon: "qrcode")
                        tabButton("Scan Ally", tab: .scanQR, icon: "camera.fill")
                    }
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                    
                    if selectedTab == .showQR {
                        showQRTab
                    } else {
                        scanQRTab
                    }
                }
                .background(Color("BackgroundTop").ignoresSafeArea())
                .navigationTitle("Party Pairing")
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
                .alert("Request Sent!", isPresented: $showRequestSent) {
                    Button("OK") { }
                } message: {
                    Text("Your party request has been sent! They'll need to accept it before you're linked up.")
                }
                .alert("Join Party?", isPresented: $showJoinConfirmation) {
                    Button("Join", role: nil) {
                        confirmJoinParty()
                    }
                    Button("Cancel", role: .cancel) {
                        scannedPairingData = nil
                    }
                } message: {
                    if let data = scannedPairingData {
                        Text("Join \(data.name)'s party?\nLevel \(data.level) \(data.characterClass ?? "Adventurer")")
                    }
                }
                .alert("Party Request", isPresented: $showIncomingRequestDialog) {
                    Button("Accept") {
                        acceptIncomingRequest()
                    }
                    Button("Decline", role: .destructive) {
                        declineIncomingRequest()
                    }
                } message: {
                    if let profile = incomingRequestProfile {
                        Text("\(profile.characterName ?? "Someone") wants to join your party!\nLevel \(profile.level ?? 1) \(profile.characterClass ?? "Adventurer")")
                    } else {
                        Text("Someone wants to join your party!")
                    }
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .showQR {
                        subscribeForPairing()
                    } else {
                        Task { await cleanupSubscription() }
                    }
                }
                .onAppear {
                    if selectedTab == .showQR {
                        subscribeForPairing()
                    }
                    startQRAnimations()
                }
                .onDisappear {
                    Task { await cleanupSubscription() }
                }
                
                // Celebration overlay
                if showCelebration {
                    pairingCelebrationOverlay
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
        }
    }
    
    // MARK: - Tab Button
    
    private func tabButton(_ title: String, tab: PairingTab, icon: String) -> some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.custom("Avenir-Heavy", size: 14))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedTab == tab ? Color("AccentGold").opacity(0.2) : Color.clear)
            .foregroundColor(selectedTab == tab ? Color("AccentGold") : .secondary)
        }
    }
    
    // MARK: - Show QR Tab
    
    private var showQRTab: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Pairing QR Code")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
            
            if let character = character, let qrImage = generateQRCode(for: character) {
                ZStack {
                    // QR code with animated container
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white)
                        )
                        .overlay(
                            // Pulsing gold border
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Color("AccentGold").opacity(qrGlowPulse ? 0.8 : 0.2),
                                    lineWidth: 3
                                )
                        )
                        .shadow(
                            color: Color("AccentGold").opacity(qrGlowPulse ? 0.4 : 0.05),
                            radius: qrGlowPulse ? 20 : 8,
                            x: 0, y: 0
                        )
                    
                    // Scan-line sweep
                    if waitingForPartner {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .frame(width: 260, height: 260)
                            .overlay(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("AccentGold").opacity(0),
                                                Color("AccentGold").opacity(0.3),
                                                Color("AccentGold").opacity(0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 40)
                                    .offset(y: scanLineOffset)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardBackground"))
                    .frame(width: 260, height: 260)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Create a character first")
                                .font(.custom("Avenir-Medium", size: 14))
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            Text("Have your ally scan this code to join")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
            
            // Character info
            if let character = character {
                VStack(spacing: 4) {
                    Text("Character: \(character.name)")
                        .font(.custom("Avenir-Heavy", size: 16))
                        .foregroundColor(.primary)
                    
                    Text("Lv.\(character.level) \(character.title)")
                        .font(.custom("Avenir-Medium", size: 14))
                        .foregroundColor(Color("AccentGold"))
                }
            }
            
            // Party code for manual sharing
            if let myCode = supabase.currentProfile?.partnerCode {
                HStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.title3)
                        .foregroundColor(Color("AccentGold"))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My Party Code")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                        Text(myCode)
                            .font(.custom("Avenir-Heavy", size: 20))
                            .tracking(4)
                            .foregroundColor(Color("AccentGold"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = myCode
                        ToastManager.shared.showSuccess("Copied!", subtitle: "Party code copied to clipboard")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                            Text("Copy")
                                .font(.custom("Avenir-Heavy", size: 13))
                        }
                        .foregroundColor(Color("AccentGold"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color("AccentGold").opacity(0.12))
                        )
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color("CardBackground"))
                )
                .padding(.horizontal, 24)
            }
            
            // Animated waiting indicator
            if waitingForPartner {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color("AccentGold"))
                            .frame(width: 8, height: 8)
                            .opacity(dotPhase == index ? 1.0 : 0.3)
                    }
                    Text("Waiting for ally to scan")
                        .font(.custom("Avenir-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Scan QR Tab
    
    private var scanQRTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if waitingForAcceptance {
                    // Scanner is waiting for the displayer to accept the request
                    scannerWaitingView
                } else {
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
                    
                    // Manual code entry (always visible, primary option when no camera)
                    manualCodeEntry
                        .padding(.horizontal)
                        .padding(.bottom)
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
            
            Text("Request Sent!")
                .font(.custom("Avenir-Heavy", size: 22))
                .foregroundColor(.primary)
            
            Text("Waiting for \(waitingPartnerName) to accept...")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Animated dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color("AccentGold"))
                        .frame(width: 8, height: 8)
                        .opacity(dotPhase == index ? 1.0 : 0.3)
                }
            }
            
            Button {
                // Cancel waiting and go back to camera
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
                        Capsule()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
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
                
                Text("Enter your ally's partner code instead")
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
            )
            
            Button(action: linkManualCode) {
                HStack(spacing: 8) {
                    if isSendingCode {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "link.badge.plus")
                        Text("Send Party Request")
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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Manual Code Partner Request
    
    private func linkManualCode() {
        isSendingCode = true
        errorMessage = nil
        Task {
            do {
                // Send a partner request using the existing code-based flow
                try await supabase.sendPartnerRequest(toCode: manualCode)
                
                await MainActor.run {
                    character?.completeBreadcrumb("inviteFriend")
                    requestSentPartnerName = nil // we don't have their name from a code lookup
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
    
    // MARK: - Subscriptions + Polling
    
    /// Start listening for pairing events. On the QR display tab this listens for incoming
    /// partner_requests. On the scanner side (after sending a request) this polls for
    /// partner_id to be set on our profile (meaning the displayer accepted).
    /// Works for both initial pairing (solo → 2) and adding new members (2 → 3 → 4).
    private func subscribeForPairing() {
        // Allow existing party members to invite — only block if party is full (4 members)
        if let character = character, character.partyMembers.count >= 3 {
            return // Party is full (self + 3 allies = 4)
        }
        
        waitingForPartner = true
        
        // Subscribe to incoming partner_requests (for QR displayer)
        if requestChannel == nil {
            Task {
                requestChannel = await supabase.subscribeToIncomingRequests { request in
                    Task { @MainActor in
                        await handleIncomingRequest(request)
                    }
                }
            }
        }
        
        // Subscribe to own profile changes (for scanner waiting for acceptance)
        if pairingChannel == nil {
            Task {
                pairingChannel = await supabase.subscribeForPairingDetection { profile in
                    Task { @MainActor in
                        await handlePartnerDetected(profile: profile)
                    }
                }
            }
        }
        
        // Polling fallback every 3 seconds
        startPairingPoll()
    }
    
    private func startPairingPoll() {
        pairingPollTimer?.invalidate()
        pairingPollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                // Stop polling only if we've already completed a pairing in this session
                // (celebration is showing) — don't stop for existing party members inviting
                guard !showCelebration else {
                    stopPairingPoll()
                    return
                }
                await pollForPairingEvents()
            }
        }
    }
    
    private func stopPairingPoll() {
        pairingPollTimer?.invalidate()
        pairingPollTimer = nil
    }
    
    @MainActor
    private func pollForPairingEvents() async {
        // If scanner is waiting for acceptance, check if partner_id was set
        if waitingForAcceptance {
            await supabase.fetchProfile()
            if let profile = supabase.currentProfile, profile.partnerID != nil {
                print("✅ Scanner poll: partner_id detected (request was accepted)")
                await handlePartnerDetected(profile: profile)
                return
            }
        }
        
        // If displayer is waiting, check for incoming requests
        if !waitingForAcceptance && incomingRequest == nil && !showIncomingRequestDialog {
            do {
                let requests = try await supabase.fetchIncomingRequests()
                if let request = requests.first {
                    print("✅ Displayer poll: incoming request detected")
                    await handleIncomingRequest(request)
                }
            } catch {
                print("⚠️ Poll for incoming requests failed: \(error)")
            }
        }
    }
    
    /// Called when an incoming partner_request is detected (via realtime or polling).
    /// Shows the accept/decline dialog on the QR displayer's screen.
    @MainActor
    private func handleIncomingRequest(_ request: PartnerRequest) async {
        guard incomingRequest == nil, !showIncomingRequestDialog else { return }
        
        incomingRequest = request
        
        // Fetch the sender's profile to show their name/class/level
        do {
            let profiles: [Profile] = try await supabase.client
                .from("profiles")
                .select()
                .eq("id", value: request.fromUserID.uuidString)
                .execute()
                .value
            incomingRequestProfile = profiles.first
        } catch {
            print("⚠️ Failed to fetch requester profile: \(error)")
        }
        
        showIncomingRequestDialog = true
    }
    
    /// Called when the scanner detects that partner_id has been set (displayer accepted).
    /// Handles both initial pairing (solo → 2) and adding to existing party (2 → 3 → 4).
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
                        // Add new member to existing party Bond
                        existingBond.addMember(partnerID)
                    } else {
                        // Create new Bond — scanner is the leader
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
                print("⚠️ Partner detected but failed to fetch details: \(error)")
            }
        }
        
        waitingForPartner = false
        waitingForAcceptance = false
        triggerCelebration()
    }
    
    private func cleanupSubscription() async {
        await supabase.unsubscribeChannel(pairingChannel)
        await supabase.unsubscribeChannel(requestChannel)
        pairingChannel = nil
        requestChannel = nil
        stopPairingPoll()
        waitingForPartner = false
        waitingForAcceptance = false
    }
    
    // MARK: - QR Animations
    
    private func startQRAnimations() {
        // Pulsing glow
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            qrGlowPulse = true
        }
        
        // Scan line sweep
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            scanLineOffset = 110
        }
        
        // Dot phase cycling
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
    
    // MARK: - QR Code Generation
    
    private func generateQRCode(for character: PlayerCharacter) -> UIImage? {
        let pairingData = PairingData(character: character, partyID: character.partyID)
        guard let jsonString = pairingData.toJSON() else { return nil }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = 10.0
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
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
        
        // Don't pair with yourself
        if pairingData.characterID == character.id.uuidString {
            errorMessage = "You can't pair with yourself!"
            showError = true
            return
        }
        
        // Check party size limit (max 3 allies = 4 total)
        if character.partyMembers.count >= 3 {
            errorMessage = "Your party is full! (Max 4 members)"
            showError = true
            return
        }
        
        guard pairingData.supabaseUserID != nil else {
            errorMessage = "This QR code is missing pairing info. Ask your partner to regenerate it."
            showError = true
            return
        }
        
        // Show confirmation dialog before linking
        scannedPairingData = pairingData
        showJoinConfirmation = true
    }
    
    /// Called when user confirms "Join Party" from the QR scan confirmation dialog.
    /// Sends a partner_request to the displayer and waits for acceptance.
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
                // 1. Send a partner request (the displayer must accept)
                try await supabase.sendPartnerRequest(toUserID: partnerUUID)
                print("✅ QR scan: partner request sent, waiting for acceptance")
                
                await MainActor.run {
                    character.completeBreadcrumb("inviteFriend")
                    isLinking = false
                    waitingForAcceptance = true
                    waitingPartnerName = pairingData.name
                    
                    // Start polling for partner_id to be set (happens after displayer accepts)
                    subscribeForPairing()
                }
            } catch {
                print("⚠️ QR scan: failed to send request: \(error)")
                await MainActor.run {
                    isLinking = false
                    scannedPairingData = nil
                    errorMessage = "Failed to send request: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Displayer: Accept / Decline Incoming Request
    
    /// Called when the QR displayer taps "Accept" on the incoming request dialog.
    /// Handles both initial pairing (solo → 2) and adding new members to existing party (2 → 3 → 4).
    private func acceptIncomingRequest() {
        guard let request = incomingRequest, let character = character else { return }
        
        Task {
            do {
                // Accept the request (uses link_partners RPC to set partner_id on both)
                try await supabase.acceptPartnerRequest(request.id)
                print("✅ QR displayer: accepted partner request")
                
                // Fetch the requester's profile for local linking
                if let requesterProfile = try? await supabase.fetchProfile(byID: request.fromUserID) {
                    await MainActor.run {
                        let pairingData = PairingData(
                            characterID: request.fromUserID.uuidString,
                            name: requesterProfile.characterName ?? "Adventurer",
                            level: requesterProfile.level ?? 1,
                            characterClass: requesterProfile.characterClass,
                            avatarName: requesterProfile.avatarName
                        )
                        character.linkPartner(data: pairingData)
                        
                        if let existingBond = bonds.first {
                            // Add new member to existing party Bond
                            existingBond.addMember(request.fromUserID)
                        } else {
                            // Create new Bond — the requester (scanner) is the leader
                            let newBond = Bond(memberIDs: [character.id, request.fromUserID])
                            newBond.leaderID = request.fromUserID
                            modelContext.insert(newBond)
                        }
                        
                        // Sync the updated party to Supabase
                        if let bond = bonds.first {
                            Task {
                                try? await SupabaseService.shared.syncBondToParty(bond, playerID: character.id)
                            }
                        }
                        
                        pairedPartnerName = requesterProfile.characterName ?? "Adventurer"
                        pairedPartnerAvatar = requesterProfile.avatarName
                        pairedPartnerLevel = requesterProfile.level ?? 1
                        pairedPartnerClass = requesterProfile.characterClass
                        
                        incomingRequest = nil
                        incomingRequestProfile = nil
                        waitingForPartner = false
                        
                        triggerCelebration()
                    }
                }
            } catch {
                print("⚠️ QR displayer: failed to accept request: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to accept: \(error.localizedDescription)"
                    showError = true
                    incomingRequest = nil
                    incomingRequestProfile = nil
                }
            }
        }
    }
    
    /// Called when the QR displayer taps "Decline" on the incoming request dialog.
    private func declineIncomingRequest() {
        guard let request = incomingRequest else { return }
        
        Task {
            try? await supabase.rejectPartnerRequest(request.id)
            await MainActor.run {
                incomingRequest = nil
                incomingRequestProfile = nil
            }
        }
    }
    
    // MARK: - Celebration Trigger
    
    private func triggerCelebration() {
        AudioManager.shared.play(.partnerPaired)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showCelebration = true
        }
        
        // Staggered animation sequence
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showCelebTitle = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showCelebAvatars = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                showCelebInfo = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCelebButton = true
            }
        }
    }
    
    // MARK: - Pairing Celebration Overlay
    
    private var pairingCelebrationOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { } // block tap-through
            
            // Sparkle particles
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 10...24)))
                    .foregroundColor(Color("AccentGold").opacity(showCelebTitle ? Double.random(in: 0.3...0.8) : 0))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -250...250)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.5...2.5))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...0.8)),
                        value: showCelebTitle
                    )
            }
            
            VStack(spacing: 28) {
                Spacer()
                
                // Title
                if showCelebTitle {
                    Text("PARTY FORMED!")
                        .font(.custom("Avenir-Heavy", size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(showCelebTitle ? 1.0 : 0.3)
                        .shadow(color: Color("AccentGold").opacity(0.5), radius: 12, x: 0, y: 0)
                }
                
                // Avatars side by side
                if showCelebAvatars {
                    HStack(spacing: 20) {
                        // My avatar
                        VStack(spacing: 6) {
                            avatarCircle(
                                icon: character?.avatarIcon ?? "person.fill",
                                color: Color("AccentGold")
                            )
                            Text(character?.name ?? "You")
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                        
                        // Link icon
                        Image(systemName: "link")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("AccentGold"))
                            .shadow(color: Color("AccentGold").opacity(0.5), radius: 6)
                        
                        // Partner avatar
                        VStack(spacing: 6) {
                            avatarCircle(
                                icon: pairedPartnerAvatar ?? "person.fill",
                                color: Color("AccentPink")
                            )
                            Text(pairedPartnerName)
                                .font(.custom("Avenir-Heavy", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Partner info card
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
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Button
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
                            LinearGradient(
                                colors: [Color("AccentGold"), Color("AccentOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
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
    
    // MARK: - Avatar Circle Helper
    
    private func avatarCircle(icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 72, height: 72)
            
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 72, height: 72)
            
            // Try asset image first, fall back to SF Symbol
            if UIImage(named: icon) != nil {
                Image(icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - QR Scanner View (Camera)

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showNoCameraUI()
            return
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            showNoCameraUI()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            showNoCameraUI()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showNoCameraUI()
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
        self.captureSession = session
        
        addScanOverlay()
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    private func addScanOverlay() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        
        let scanFrame = UIView()
        scanFrame.translatesAutoresizingMaskIntoConstraints = false
        scanFrame.layer.borderColor = UIColor(named: "AccentGold")?.cgColor ?? UIColor.systemYellow.cgColor
        scanFrame.layer.borderWidth = 3
        scanFrame.layer.cornerRadius = 16
        scanFrame.backgroundColor = .clear
        overlayView.addSubview(scanFrame)
        
        NSLayoutConstraint.activate([
            scanFrame.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            scanFrame.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            scanFrame.widthAnchor.constraint(equalToConstant: 240),
            scanFrame.heightAnchor.constraint(equalToConstant: 240)
        ])
    }
    
    private func showNoCameraUI() {
        let label = UILabel()
        label.text = "Camera not available\non this device"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "Avenir-Medium", size: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned else { return }
        
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           metadataObject.type == .qr,
           let stringValue = metadataObject.stringValue {
            hasScanned = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            captureSession?.stopRunning()
            onCodeScanned?(stringValue)
        }
    }
}

#Preview {
    QRPairingView()
}
