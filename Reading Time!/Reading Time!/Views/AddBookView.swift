import SwiftUI
import PhotosUI

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var coverImage: Image?
    @State private var coverImageData: Data?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingImageSource = false
    @State private var errorMessage: String?
    @State private var hasAttemptedSave = false
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Book Details") {
                    TextField("Book Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                }
                
                Section("Book Cover") {
                    VStack {
                        if let coverImage {
                            coverImage
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        }
                        
                        Button(action: {
                            showingImageSource = true
                        }) {
                            Label(coverImage == nil ? "Add Cover Photo" : "Change Cover Photo", 
                                  systemImage: "camera")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isValidInput {
                            saveBook()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
            .confirmationDialog("Choose Image Source", isPresented: $showingImageSource) {
                Button("Camera") {
                    showingCamera = true
                }
                Button("Photo Library") {
                    showingPhotoPicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $coverImage, imageData: $coverImageData)
            }
            .photosPicker(isPresented: $showingPhotoPicker, 
                         selection: $selectedItem,
                         matching: .images)
            .onChange(of: selectedItem) { newItem in
                Task {
                    await loadTransferable(from: newItem)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !totalPages.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(totalPages) ?? 0 > 0
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem?) async {
        do {
            if let data = try await imageSelection?.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    coverImage = Image(uiImage: uiImage)
                    coverImageData = data
                }
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }
    
    private func saveBook() {
        guard let pagesInt = Int(totalPages), pagesInt > 0 else {
            errorMessage = "Please enter a valid number of pages"
            return
        }
        
        let book = Book(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            coverImage: coverImageData?.base64EncodedString(),
            totalPages: pagesInt
        )
        
        // Save book to UserDefaults
        var books = UserDefaults.standard.books
        books.append(book)
        UserDefaults.standard.books = books
        
        // Post notification for book added
        NotificationCenter.default.post(name: .bookAdded, object: nil)
        
        // Dismiss all the way back to the library
        presentationMode.wrappedValue.dismiss()
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: Image?
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, 
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = Image(uiImage: uiImage)
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Extension to handle book storage
extension UserDefaults {
    var books: [Book] {
        get {
            guard let data = data(forKey: "savedBooks"),
                  let books = try? JSONDecoder().decode([Book].self, from: data) else {
                return []
            }
            return books
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, forKey: "savedBooks")
        }
    }
}

// Add Notification name extension
extension Notification.Name {
    static let bookAdded = Notification.Name("bookAdded")
} 