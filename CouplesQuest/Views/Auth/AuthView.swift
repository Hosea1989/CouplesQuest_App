import SwiftUI
import AuthenticationServices
import CryptoKit

/// Sign Up / Sign In form for Swords & Chores.
struct AuthView: View {
    @ObservedObject private var supabase = SupabaseService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailConfirmation = false
    @State private var showForgotPassword = false
    @State private var showResetSent = false
    @State private var resetEmail = ""
    @State private var currentNonce: String?
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color("BackgroundTop"),
                    Color("BackgroundBottom")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if showEmailConfirmation {
                emailConfirmationView
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer().frame(height: 40)
                        
                        // Logo / Title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color("AccentGold").opacity(0.3), Color.clear],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 56))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color("AccentGold"), Color("AccentPink")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Swords & Chores")
                                .font(.custom("Avenir-Heavy", size: 32))
                                .foregroundColor(.primary)
                            
                            Text("Your adventure awaits")
                                .font(.custom("Avenir-Medium", size: 16))
                                .foregroundColor(.secondary)
                        }
                        
                        // Form Card
                        VStack(spacing: 20) {
                            // Mode Toggle
                            HStack(spacing: 0) {
                                modeButton(title: "Sign Up", isActive: isSignUp) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSignUp = true
                                        errorMessage = nil
                                    }
                                }
                                modeButton(title: "Sign In", isActive: !isSignUp) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSignUp = false
                                        errorMessage = nil
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("CardBackground").opacity(0.5))
                            )
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 10) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 20)
                                    
                                    TextField("adventurer@example.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .font(.custom("Avenir-Medium", size: 15))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBackground"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.custom("Avenir-Heavy", size: 13))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 20)
                                    
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(isSignUp ? .newPassword : .password)
                                        .font(.custom("Avenir-Medium", size: 15))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBackground"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
                                )
                                
                                if isSignUp {
                                    Text("Password must be at least 6 characters")
                                        .font(.custom("Avenir-Medium", size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Forgot Password (sign-in mode only)
                            if !isSignUp {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        resetEmail = email
                                        showForgotPassword = true
                                    }) {
                                        Text("Forgot Password?")
                                            .font(.custom("Avenir-Medium", size: 13))
                                            .foregroundColor(Color("AccentGold"))
                                    }
                                }
                            }
                            
                            // Error Message
                            if let errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.custom("Avenir-Medium", size: 13))
                                        .foregroundColor(.red)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                            
                            // Submit Button
                            Button(action: submit) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.black)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle.fill")
                                        Text(isSignUp ? "Create Account" : "Sign In")
                                    }
                                }
                                .font(.custom("Avenir-Heavy", size: 16))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color("AccentGold"), Color("AccentGold").opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                            
                            // "or" divider
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .font(.custom("Avenir-Medium", size: 13))
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            
                            // Sign in with Apple
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("CardBackground"))
                                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                        )
                        .padding(.horizontal, 4)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $resetEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) {}
            Button("Send Reset Link") { sendPasswordReset() }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .alert("Check Your Email", isPresented: $showResetSent) {
            Button("OK") {}
        } message: {
            Text("If an account exists with that email, a password reset link has been sent.")
        }
    }
    
    // MARK: - Email Confirmation View
    
    private var emailConfirmationView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AccentGold").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentGold"), Color("AccentPink")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Check Your Email")
                    .font(.custom("Avenir-Heavy", size: 28))
                
                Text("We've sent a confirmation link to:")
                    .font(.custom("Avenir-Medium", size: 16))
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.custom("Avenir-Heavy", size: 16))
                    .foregroundColor(Color("AccentGold"))
                
                Text("Tap the link in the email to verify your account, then come back here and sign in.")
                    .font(.custom("Avenir-Medium", size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            Button(action: {
                withAnimation {
                    showEmailConfirmation = false
                    isSignUp = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Go to Sign In")
                }
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color("AccentGold"), Color("AccentGold").opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func modeButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(isActive ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isActive
                    ? RoundedRectangle(cornerRadius: 10)
                        .fill(Color("AccentGold"))
                    : RoundedRectangle(cornerRadius: 10)
                        .fill(Color.clear)
                )
        }
    }
    
    private func submit() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    let canProceed = try await supabase.signUp(email: email, password: password)
                    if !canProceed {
                        // Email confirmation is required — show the confirmation screen
                        withAnimation {
                            showEmailConfirmation = true
                        }
                    }
                    // If canProceed is true, isAuthenticated is already set,
                    // and AuthGateView will navigate away automatically.
                } else {
                    try await supabase.signIn(email: email, password: password)
                }
            } catch let error as NSError {
                errorMessage = friendlyError(from: error)
            } catch {
                errorMessage = friendlyError(from: error as NSError)
            }
            isLoading = false
        }
    }
    
    private func sendPasswordReset() {
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return }
        
        Task {
            do {
                try await supabase.resetPassword(email: trimmedEmail)
            } catch {
                // Don't reveal whether the email exists
            }
            showResetSent = true
        }
    }
    
    // MARK: - Sign in with Apple
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Unable to retrieve Apple credentials. Please try again."
                return
            }
            
            isLoading = true
            errorMessage = nil
            
            Task {
                do {
                    try await supabase.signInWithApple(idToken: idToken, nonce: nonce)
                } catch let error as NSError {
                    errorMessage = friendlyError(from: error)
                } catch {
                    errorMessage = friendlyError(from: error as NSError)
                }
                isLoading = false
            }
            
        case .failure(let error):
            // User cancelled — ASAuthorizationError.canceled (code 1001)
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return // User intentionally cancelled; no error needed
            }
            errorMessage = "Apple Sign In failed. Please try again."
        }
    }
    
    /// Generate a random nonce string for Apple Sign In.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    /// SHA256 hash of the input string, returned as a hex string.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Convert raw Supabase / network errors into user-friendly messages.
    private func friendlyError(from error: NSError) -> String {
        let description = error.localizedDescription.lowercased()
        
        // Network / connectivity issues
        if error.domain == NSURLErrorDomain ||
            description.contains("network") ||
            description.contains("internet") ||
            description.contains("offline") ||
            description.contains("not connected") {
            return "No internet connection. Please check your network and try again."
        }
        
        // Timeout
        if description.contains("timed out") || description.contains("timeout") {
            return "The request timed out. Please try again."
        }
        
        // Invalid credentials
        if description.contains("invalid login") || description.contains("invalid credentials") {
            return "Invalid email or password. Please try again."
        }
        
        // User not found
        if description.contains("user not found") {
            return "No account found with that email. Try signing up instead."
        }
        
        // Email not confirmed
        if description.contains("email not confirmed") {
            return "Your email hasn't been confirmed yet. Check your inbox for the verification link."
        }
        
        // Weak password
        if description.contains("password") && (description.contains("short") || description.contains("weak") || description.contains("at least")) {
            return "Password must be at least 6 characters long."
        }
        
        // User already exists
        if description.contains("already registered") || description.contains("already exists") || description.contains("already been registered") {
            return "An account with this email already exists. Try signing in instead."
        }
        
        // Rate limiting
        if description.contains("rate") || description.contains("too many") {
            return "Too many attempts. Please wait a moment and try again."
        }
        
        // Fallback: show the original error but trim it
        let original = error.localizedDescription
        if original.count > 200 {
            return String(original.prefix(200)) + "..."
        }
        return original
    }
}

#Preview {
    AuthView()
}
