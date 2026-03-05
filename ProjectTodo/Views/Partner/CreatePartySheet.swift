import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import Supabase

/// Sheet shown when a solo player taps "Join a Party" (passive role).
/// Displays their QR code and party code so another player can scan/enter it to invite them.
/// Listens for incoming requests and celebrates on pairing.
struct CreatePartySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    // Displayer: incoming request detection
    @State private var incomingRequest: PartnerRequest?
    @State private var incomingRequestProfile: Profile?
    @State private var showIncomingRequestDialog = false
    
    // Error handling
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Realtime subscriptions + polling fallback
    @State private var pairingChannel: RealtimeChannelV2?
    @State private var requestChannel: RealtimeChannelV2?
    @State private var pairingPollTimer: Timer?
    @State private var waitingForPartner = false
    
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
    
    // QR animation states
    @State private var qrGlowPulse = false
    @State private var scanLineOffset: CGFloat = -110
    @State private var dotPhase: Int = 0
    
    private let supabase = SupabaseService.shared
    
    private var character: PlayerCharacter? { characters.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Text("Show this code to the party leader")
                        .font(.custom("Avenir-Medium", size: 16))
                        .foregroundColor(.secondary)
                    
                    // QR Code
                    if let character = character, let qrImage = generateQRCode(for: character) {
                        ZStack {
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
                    
                    // Character info
                    if let character = character {
                        VStack(spacing: 4) {
                            Text(character.name)
                                .font(.custom("Avenir-Heavy", size: 16))
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
                    
                    // Waiting indicator
                    if waitingForPartner {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(Color("AccentGold"))
                                    .frame(width: 8, height: 8)
                                    .opacity(dotPhase == index ? 1.0 : 0.3)
                            }
                            Text("Waiting for an invite...")
                                .font(.custom("Avenir-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .background(Color("BackgroundTop").ignoresSafeArea())
                .navigationTitle("Join a Party")
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
                .onAppear {
                    subscribeForPairing()
                    startQRAnimations()
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
    
    // MARK: - Subscriptions + Polling
    
    private func subscribeForPairing() {
        if let character = character, character.partyMembers.count >= 3 {
            return
        }
        
        waitingForPartner = true
        
        if requestChannel == nil {
            Task {
                requestChannel = await supabase.subscribeToIncomingRequests { request in
                    Task { @MainActor in
                        await handleIncomingRequest(request)
                    }
                }
            }
        }
        
        startPairingPoll()
    }
    
    private func startPairingPoll() {
        pairingPollTimer?.invalidate()
        pairingPollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                guard !showCelebration else {
                    stopPairingPoll()
                    return
                }
                await pollForIncomingRequests()
            }
        }
    }
    
    private func stopPairingPoll() {
        pairingPollTimer?.invalidate()
        pairingPollTimer = nil
    }
    
    @MainActor
    private func pollForIncomingRequests() async {
        guard incomingRequest == nil, !showIncomingRequestDialog else { return }
        do {
            let requests = try await supabase.fetchIncomingRequests()
            if let request = requests.first {
                await handleIncomingRequest(request)
            }
        } catch {
            print("Poll for incoming requests failed: \(error)")
        }
    }
    
    @MainActor
    private func handleIncomingRequest(_ request: PartnerRequest) async {
        guard incomingRequest == nil, !showIncomingRequestDialog else { return }
        
        incomingRequest = request
        
        do {
            let profiles: [Profile] = try await supabase.client
                .from("profiles")
                .select()
                .eq("id", value: request.fromUserID.uuidString)
                .execute()
                .value
            incomingRequestProfile = profiles.first
        } catch {
            print("Failed to fetch requester profile: \(error)")
        }
        
        showIncomingRequestDialog = true
    }
    
    // MARK: - Accept / Decline
    
    private func acceptIncomingRequest() {
        guard let request = incomingRequest, let character = character else { return }
        
        Task {
            do {
                try await supabase.acceptPartnerRequest(request.id)
                
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
                            existingBond.addMember(request.fromUserID)
                        } else {
                            let newBond = Bond(memberIDs: [character.id, request.fromUserID])
                            newBond.leaderID = character.id
                            modelContext.insert(newBond)
                        }
                        
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
                await MainActor.run {
                    errorMessage = "Failed to accept: \(error.localizedDescription)"
                    showError = true
                    incomingRequest = nil
                    incomingRequestProfile = nil
                }
            }
        }
    }
    
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
    
    // MARK: - Cleanup
    
    private func cleanupSubscription() async {
        await supabase.unsubscribeChannel(pairingChannel)
        await supabase.unsubscribeChannel(requestChannel)
        pairingChannel = nil
        requestChannel = nil
        stopPairingPoll()
        waitingForPartner = false
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
    
    // MARK: - QR Animations
    
    private func startQRAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            qrGlowPulse = true
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            scanLineOffset = 110
        }
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
                    Text("PARTY FORMED!")
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
