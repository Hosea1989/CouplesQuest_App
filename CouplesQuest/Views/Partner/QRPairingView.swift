import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import AVFoundation

struct QRPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var characters: [PlayerCharacter]
    @Query private var bonds: [Bond]
    
    @State private var selectedTab: PairingTab = .showQR
    @State private var showPairingSuccess = false
    @State private var pairedPartnerName: String = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var character: PlayerCharacter? { characters.first }
    
    enum PairingTab {
        case showQR
        case scanQR
    }
    
    var body: some View {
        NavigationStack {
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .alert("Ally Joined!", isPresented: $showPairingSuccess) {
                Button("Let's Go!") { dismiss() }
            } message: {
                Text("\(pairedPartnerName) has joined your party! Start sharing tasks and questing together.")
            }
            .alert("Pairing Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Something went wrong.")
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
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
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
            
            // Also show the character ID for manual entry
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
            
            Spacer()
        }
    }
    
    // MARK: - Scan QR Tab
    
    private var scanQRTab: some View {
        VStack(spacing: 16) {
            Text("Scan Ally's QR Code")
                .font(.custom("Avenir-Medium", size: 16))
                .foregroundColor(.secondary)
                .padding(.top)
            
            QRScannerView { scannedString in
                handleScannedCode(scannedString)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("AccentGold").opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal)
            
            Text("Point your camera at your ally's QR code")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom)
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
        
        // Scale up the QR code
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
        
        // Link the new member
        character.linkPartner(data: pairingData)
        
        // Create or update bond
        if let existingBond = bonds.first {
            // Add new member to existing bond
            guard let memberUUID = UUID(uuidString: pairingData.characterID) else { return }
            existingBond.addMember(memberUUID)
        } else {
            // Create a new bond with both members
            guard let partnerUUID = UUID(uuidString: pairingData.characterID) else { return }
            let newBond = Bond(memberIDs: [character.id, partnerUUID])
            modelContext.insert(newBond)
        }
        
        pairedPartnerName = pairingData.name
        showPairingSuccess = true
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
        
        // Add scan frame overlay
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
            
            // Haptic feedback
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
