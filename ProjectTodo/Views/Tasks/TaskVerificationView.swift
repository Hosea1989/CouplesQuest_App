import SwiftUI
import CoreLocation
import CoreMotion

/// A sheet that handles task verification (photo proof and/or location check-in)
struct TaskVerificationView: View {
    @Bindable var task: GameTask
    var characterLevel: Int = 1
    @Environment(\.dismiss) private var dismiss
    
    /// Called when verification is complete and task should be finished
    let onVerified: () -> Void
    
    // Photo state
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var photoTimestamp: Date?
    @State private var hasMotionAtCapture = false
    
    // Location state
    @StateObject private var locationManager = VerificationLocationManager()
    @State private var locationCaptured = false
    @State private var geofenceResult: GeofenceResult?
    
    // UI state
    @State private var isSubmitting = false
    @State private var photoExpiredAlert = false
    
    // Motion manager for anti-screenshot detection
    private let motionManager = CMMotionManager()
    
    private var photoSatisfied: Bool {
        !task.verificationType.requiresPhoto || capturedImage != nil
    }
    
    private var locationSatisfied: Bool {
        !task.verificationType.requiresLocation || locationCaptured
    }
    
    private var canSubmit: Bool {
        photoSatisfied && locationSatisfied
    }
    
    /// Whether the captured photo is still within the 5-minute validity window
    private var isPhotoValid: Bool {
        VerificationEngine.isPhotoTimestampValid(photoTakenAt: photoTimestamp)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BackgroundTop"), Color("BackgroundBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Photo Section
                        if task.verificationType.requiresPhoto {
                            photoSection
                        }
                        
                        // Location Section
                        if task.verificationType.requiresLocation {
                            locationSection
                        }
                        
                        // Reward Preview
                        rewardPreview
                        
                        // Verification Bonuses Summary
                        bonusSummary
                        
                        Spacer(minLength: 20)
                        
                        // Submit Button
                        submitButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Verify Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("AccentGold"))
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(
                    image: $capturedImage,
                    photoTimestamp: $photoTimestamp,
                    hasMotion: $hasMotionAtCapture
                )
            }
            .alert("Photo Expired", isPresented: $photoExpiredAlert) {
                Button("Retake Photo") { showCamera = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your photo was taken more than 5 minutes ago. Please take a new photo to verify.")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: task.verificationType.icon)
                .font(.system(size: 48))
                .foregroundColor(Color(task.verificationType.color))
            
            Text(task.title)
                .font(.custom("Avenir-Heavy", size: 22))
                .multilineTextAlignment(.center)
            
            Text("Complete verification to earn \(String(format: "%.1f", task.verificationMultiplier))x rewards")
                .font(.custom("Avenir-Medium", size: 14))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Photo Proof")
                    .font(.custom("Avenir-Heavy", size: 16))
                
                Spacer()
                
                if capturedImage != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                }
            }
            
            if let image = capturedImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("AccentGreen"), lineWidth: 2)
                        )
                    
                    // Timestamp watermark overlay
                    if let timestamp = photoTimestamp {
                        timestampWatermark(date: timestamp)
                    }
                }
                
                HStack {
                    Button(action: { showCamera = true }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                            Text("Retake Photo")
                        }
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(Color("AccentGold"))
                    }
                    
                    Spacer()
                    
                    // Motion indicator
                    HStack(spacing: 4) {
                        Image(systemName: hasMotionAtCapture ? "iphone.gen3.radiowaves.left.and.right" : "iphone.gen3")
                            .font(.system(size: 12))
                        Text(hasMotionAtCapture ? "Motion detected" : "No motion")
                            .font(.custom("Avenir-Medium", size: 11))
                    }
                    .foregroundColor(hasMotionAtCapture ? Color("AccentGreen") : .secondary)
                }
                
                // Photo age warning
                if let timestamp = photoTimestamp {
                    let age = Date().timeIntervalSince(timestamp)
                    if age > 240 && age <= 300 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Photo expires soon. Submit quickly or retake.")
                                .font(.custom("Avenir-Medium", size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Button(action: { showCamera = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color("AccentGold"))
                        Text("Take Photo")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color("AccentGold"))
                        Text("Snap a photo as proof of completion")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color("AccentGold").opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Timestamp Watermark
    
    private func timestampWatermark(date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm:ss a"
        return Text(formatter.string(from: date))
            .font(.custom("Avenir-Heavy", size: 11))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(8)
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Color("AccentGreen"))
                Text("Location Check-in")
                    .font(.custom("Avenir-Heavy", size: 16))
                
                Spacer()
                
                if locationCaptured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                }
            }
            
            // Geofence target info (if set)
            if let locationName = task.geofenceLocationName {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color("AccentOrange"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Target: \(locationName)")
                            .font(.custom("Avenir-Heavy", size: 13))
                        if let radius = task.geofenceRadius {
                            Text("Within \(Int(radius))m radius")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AccentOrange").opacity(0.1))
                )
            }
            
            if locationCaptured {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color("AccentGreen"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location recorded")
                            .font(.custom("Avenir-Heavy", size: 14))
                            .foregroundColor(Color("AccentGreen"))
                        if let loc = locationManager.currentLocation {
                            Text("\(String(format: "%.4f", loc.coordinate.latitude)), \(String(format: "%.4f", loc.coordinate.longitude))")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("AccentGreen").opacity(0.1))
                )
                
                // Geofence result
                if let geo = geofenceResult {
                    HStack(spacing: 8) {
                        Image(systemName: geo.inRange ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(geo.inRange ? Color("AccentGreen") : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(geo.inRange ? "Inside target zone" : "Outside target zone")
                                .font(.custom("Avenir-Heavy", size: 13))
                                .foregroundColor(geo.inRange ? Color("AccentGreen") : .orange)
                            Text(geo.inRange ? "Full location bonus applied" : "\(geo.distanceText) away — reduced bonus")
                                .font(.custom("Avenir-Medium", size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((geo.inRange ? Color("AccentGreen") : Color.orange).opacity(0.1))
                    )
                }
            } else {
                Button(action: captureLocation) {
                    VStack(spacing: 12) {
                        if locationManager.isLoading {
                            ProgressView()
                                .tint(Color("AccentGreen"))
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color("AccentGreen"))
                        }
                        Text(locationManager.isLoading ? "Getting location..." : "Check In")
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(Color("AccentGreen"))
                        Text("Record your current location")
                            .font(.custom("Avenir-Medium", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color("AccentGreen").opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .disabled(locationManager.isLoading)
                
                if let error = locationManager.errorMessage {
                    Text(error)
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Reward Preview
    
    private var rewardPreview: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("+\(Int(Double(task.scaledExpReward(characterLevel: characterLevel)) * task.verificationMultiplier))")
                    .font(.custom("Avenir-Heavy", size: 22))
                    .foregroundColor(Color("AccentGold"))
                Text("EXP")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 40)
            
            VStack(spacing: 4) {
                Text("+\(Int(Double(task.scaledGoldReward(characterLevel: characterLevel)) * task.verificationMultiplier))")
                    .font(.custom("Avenir-Heavy", size: 22))
                    .foregroundColor(Color("AccentGold"))
                Text("Gold")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1, height: 40)
            
            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", task.verificationMultiplier))x")
                    .font(.custom("Avenir-Heavy", size: 22))
                    .foregroundColor(Color(task.verificationType.color))
                Text("Multiplier")
                    .font(.custom("Avenir-Medium", size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    // MARK: - Bonus Summary
    
    private var bonusSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verification Bonuses")
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(.secondary)
            
            if task.verificationType.requiresPhoto {
                bonusRow(icon: "camera.fill", text: "Photo Proof", value: "1.5x", active: capturedImage != nil)
            }
            if task.verificationType.requiresLocation {
                if let geo = geofenceResult {
                    bonusRow(icon: "location.fill", text: geo.inRange ? "In Geofence" : "Outside Geofence", value: geo.inRange ? "~1.8x" : "0.9x", active: locationCaptured)
                } else {
                    bonusRow(icon: "location.fill", text: "Location Check-in", value: "~1.8x", active: locationCaptured)
                }
            }
            if task.category == .physical {
                bonusRow(icon: "heart.fill", text: "HealthKit Auto-Verify", value: "+1.25x", active: task.healthKitVerified)
            }
            if task.isFromPartner {
                bonusRow(icon: "person.2.fill", text: "Partner Confirmation", value: "+1.15x", active: task.partnerConfirmed)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
    }
    
    private func bonusRow(icon: String, text: String, value: String, active: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(active ? Color("AccentGreen") : .secondary)
                .frame(width: 20)
            Text(text)
                .font(.custom("Avenir-Medium", size: 13))
                .foregroundColor(active ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(.custom("Avenir-Heavy", size: 13))
                .foregroundColor(active ? Color("AccentGold") : .secondary)
            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                .foregroundColor(active ? Color("AccentGreen") : .secondary)
                .font(.system(size: 14))
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: submitVerification) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                Text("Verify & Complete")
            }
            .font(.custom("Avenir-Heavy", size: 18))
            .foregroundColor(canSubmit ? .black : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                canSubmit
                ? AnyShapeStyle(LinearGradient(colors: [Color("AccentGold"), Color("AccentOrange")], startPoint: .leading, endPoint: .trailing))
                : AnyShapeStyle(Color.gray.opacity(0.3))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!canSubmit || isSubmitting)
    }
    
    // MARK: - Actions
    
    private func captureLocation() {
        locationManager.requestLocation()
        // Observe changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let loc = locationManager.currentLocation {
                task.verificationLatitude = loc.coordinate.latitude
                task.verificationLongitude = loc.coordinate.longitude
                locationCaptured = true
                
                // Check geofence if target is set
                if task.geofenceLatitude != nil {
                    geofenceResult = VerificationEngine.verifyGeofence(
                        task: task,
                        userLatitude: loc.coordinate.latitude,
                        userLongitude: loc.coordinate.longitude
                    )
                }
            }
        }
    }
    
    private func submitVerification() {
        // Validate photo timestamp (must be within 5 minutes)
        if task.verificationType.requiresPhoto, let timestamp = photoTimestamp {
            if !VerificationEngine.isPhotoTimestampValid(photoTakenAt: timestamp) {
                photoExpiredAlert = true
                capturedImage = nil
                photoTimestamp = nil
                return
            }
        }
        
        isSubmitting = true
        
        // Save photo data with timestamp watermark
        if let image = capturedImage {
            if let timestamp = photoTimestamp {
                // Embed watermark into the image
                let watermarked = embedTimestampWatermark(image: image, date: timestamp)
                task.verificationPhotoData = watermarked.jpegData(compressionQuality: 0.7)
            } else {
                task.verificationPhotoData = image.jpegData(compressionQuality: 0.7)
            }
            task.photoTakenAt = photoTimestamp
            task.photoHasMotionData = hasMotionAtCapture
        }
        
        // Save location data
        if let loc = locationManager.currentLocation {
            task.verificationLatitude = loc.coordinate.latitude
            task.verificationLongitude = loc.coordinate.longitude
        }
        
        task.isVerified = true
        onVerified()
        dismiss()
    }
    
    // MARK: - Watermark
    
    /// Embed a semi-transparent timestamp watermark onto the photo
    private func embedTimestampWatermark(image: UIImage, date: Date) -> UIImage {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm:ss a"
        let text = formatter.string(from: date)
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(at: .zero)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: max(image.size.width * 0.025, 14)),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
                .strokeColor: UIColor.black.withAlphaComponent(0.5),
                .strokeWidth: -2
            ]
            
            let textSize = (text as NSString).size(withAttributes: attributes)
            let x = image.size.width - textSize.width - 20
            let y = image.size.height - textSize.height - 20
            
            // Background rectangle
            let bgRect = CGRect(x: x - 10, y: y - 5, width: textSize.width + 20, height: textSize.height + 10)
            UIColor.black.withAlphaComponent(0.5).setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: 6).fill()
            
            // Draw text
            (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
}

// MARK: - Location Manager

class VerificationLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLoading = true
        errorMessage = nil
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            errorMessage = "Location access denied. Enable in Settings."
        @unknown default:
            isLoading = false
            errorMessage = "Unknown location status."
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Could not get location. Try again."
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            if isLoading {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - Camera View (UIImagePickerController wrapper) with motion detection

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var photoTimestamp: Date?
    @Binding var hasMotion: Bool
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        
        // Start motion monitoring
        context.coordinator.startMotionMonitoring()
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        private let motionManager = CMMotionManager()
        private var recentAcceleration: [Double] = []
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func startMotionMonitoring() {
            guard motionManager.isAccelerometerAvailable else { return }
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                // Track acceleration magnitude variance
                let magnitude = sqrt(data.acceleration.x * data.acceleration.x +
                                    data.acceleration.y * data.acceleration.y +
                                    data.acceleration.z * data.acceleration.z)
                self?.recentAcceleration.append(magnitude)
                // Keep last 5 readings (0.5 seconds)
                if (self?.recentAcceleration.count ?? 0) > 5 {
                    self?.recentAcceleration.removeFirst()
                }
            }
        }
        
        /// Check if device had physical motion at capture time
        private func detectMotion() -> Bool {
            guard recentAcceleration.count >= 3 else { return false }
            let avg = recentAcceleration.reduce(0, +) / Double(recentAcceleration.count)
            let variance = recentAcceleration.reduce(0) { $0 + ($1 - avg) * ($1 - avg) } / Double(recentAcceleration.count)
            // Variance > 0.001 indicates physical motion (not perfectly stationary)
            return variance > 0.001
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.photoTimestamp = Date()
                parent.hasMotion = detectMotion()
            }
            motionManager.stopAccelerometerUpdates()
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            motionManager.stopAccelerometerUpdates()
            parent.dismiss()
        }
        
        deinit {
            motionManager.stopAccelerometerUpdates()
        }
    }
}
