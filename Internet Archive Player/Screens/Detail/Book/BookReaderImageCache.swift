//
//  BookReaderImageCache.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import UIKit
import Foundation
import iaAPI

/// Simple image cache for book reader pages
actor BookReaderImageCache {
    static let shared = BookReaderImageCache()
    
    private var cache: [URL: UIImage] = [:]
    private let maxCacheSize = 50 // Maximum number of images to cache
    private var accessOrder: [URL] = [] // Track access order for LRU eviction
    
    private init() {}
    
    /// Retrieve cached image for URL
    func image(for url: URL) -> UIImage? {
        if let image = cache[url] {
            // Update access order (move to end = most recently used)
            accessOrder.removeAll { $0 == url }
            accessOrder.append(url)
            return image
        }
        return nil
    }
    
    /// Store image in cache
    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
        accessOrder.append(url)
        
        // Evict oldest if cache is too large
        if cache.count > maxCacheSize {
            if let oldestURL = accessOrder.first {
                cache.removeValue(forKey: oldestURL)
                accessOrder.removeFirst()
            }
        }
    }
    
    /// Clear all cached images
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()
    }
    
    /// Get cache statistics
    var cacheInfo: (count: Int, maxSize: Int) {
        (cache.count, maxCacheSize)
    }
}

/// Enhanced BookPageViewController with caching
class CachedBookPageViewController: UIViewController {
    private let pageNumber: Int
    private let imageURL: URL
    private let imageView: UIImageView
    private let activityIndicator: UIActivityIndicatorView
    private let errorLabel: UILabel
    private var imageTask: Task<Void, Never>?
    
    // Zoom support
    private let scrollView: UIScrollView
    
    init(pageNumber: Int, imageURL: URL) {
        self.pageNumber = pageNumber
        self.imageURL = imageURL
        self.scrollView = UIScrollView()
        self.imageView = UIImageView()
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.errorLabel = UILabel()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadImage()
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        // Configure scroll view for zooming
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        // Configure image view
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        view.addSubview(activityIndicator)
        
        // Configure error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = .white
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        view.addSubview(errorLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        // Double tap to zoom
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    private func loadImage() {
        activityIndicator.startAnimating()
        imageView.image = nil
        errorLabel.isHidden = true
        
        imageTask = Task {
            // Check cache first
            if let cachedImage = await BookReaderImageCache.shared.image(for: imageURL) {
                await MainActor.run {
                    self.imageView.image = cachedImage
                    self.activityIndicator.stopAnimating()
                }
                return
            }
            
            // Load from network
            do {
                let (data, response) = try await URLSession.shared.data(from: imageURL)
                
                guard !Task.isCancelled else { return }
                
                // Check for HTTP errors
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(.badServerResponse)
                }
                
                if let image = UIImage(data: data) {
                    // Cache the image
                    await BookReaderImageCache.shared.setImage(image, for: imageURL)
                    
                    await MainActor.run {
                        self.imageView.image = image
                        self.activityIndicator.stopAnimating()
                    }
                } else {
                    await MainActor.run {
                        self.showError("Invalid image data")
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    let errorMessage: String
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "No internet connection"
                        case .timedOut:
                            errorMessage = "Request timed out"
                        default:
                            errorMessage = "Failed to load page \(self.pageNumber)"
                        }
                    } else {
                        errorMessage = "Failed to load page \(self.pageNumber)"
                    }
                    self.showError(errorMessage)
                }
                print("Failed to load image for page \(pageNumber): \(error)")
            }
        }
    }
    
    private func showError(_ message: String) {
        activityIndicator.stopAnimating()
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let zoomRect = zoomRect(for: scrollView.maximumZoomScale / 2, center: location)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func zoomRect(for scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    deinit {
        imageTask?.cancel()
    }
}

// MARK: - UIScrollViewDelegate

extension CachedBookPageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center image when zoomed
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
