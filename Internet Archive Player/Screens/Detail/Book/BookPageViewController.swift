//
//  BookPageViewController.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import UIKit
import SwiftUI
import iaAPI

/// A single page view controller that displays an image from URL
class BookPageViewController: UIViewController {
    private let pageNumber: Int
    private let imageURL: URL
    private let imageView: UIImageView
    private let activityIndicator: UIActivityIndicatorView
    private var imageTask: Task<Void, Never>?
    
    init(pageNumber: Int, imageURL: URL) {
        print("🎬 [BookPageVC] Initializing page \(pageNumber)")
        print("🎬 [BookPageVC] URL: \(imageURL.absoluteString)")
        
        self.pageNumber = pageNumber
        self.imageURL = imageURL
        self.imageView = UIImageView()
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        
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
        
        // Configure image view
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        view.addSubview(activityIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add pinch to zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(pinchGesture)
    }
    
    private func loadImage() {
        print("🖼️ [Page \(pageNumber)] loadImage() called")
        print("🖼️ [Page \(pageNumber)] URL: \(imageURL.absoluteString)")
        
        activityIndicator.startAnimating()
        imageView.image = nil
        
        imageTask = Task {
            do {
                print("🌐 [Page \(pageNumber)] Starting URL request...")
                let (data, response) = try await URLSession.shared.data(from: imageURL)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 [Page \(pageNumber)] HTTP Status: \(httpResponse.statusCode)")
                }
                
                print("📦 [Page \(pageNumber)] Received data: \(data.count) bytes")
                
                guard !Task.isCancelled else {
                    print("🚫 [Page \(pageNumber)] Task was cancelled")
                    return
                }
                
                if let image = UIImage(data: data) {
                    print("✅ [Page \(pageNumber)] Image decoded successfully, size: \(image.size)")
                    await MainActor.run {
                        self.imageView.image = image
                        self.activityIndicator.stopAnimating()
                    }
                } else {
                    print("❌ [Page \(pageNumber)] Failed to decode image from data")
                    await MainActor.run {
                        self.showErrorPlaceholder()
                    }
                }
            } catch {
                guard !Task.isCancelled else {
                    print("🚫 [Page \(pageNumber)] Task was cancelled")
                    return
                }
                
                print("❌ [Page \(pageNumber)] Failed to load image: \(error.localizedDescription)")
                await MainActor.run {
                    self.showErrorPlaceholder()
                }
            }
        }
    }
    
    private func showErrorPlaceholder() {
        activityIndicator.stopAnimating()
        
        let label = UILabel()
        label.text = "Failed to load page \(pageNumber)"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        switch gesture.state {
        case .changed:
            let scale = gesture.scale
            view.transform = view.transform.scaledBy(x: scale, y: scale)
            gesture.scale = 1.0
        case .ended, .cancelled:
            // Optionally reset or constrain the scale
            UIView.animate(withDuration: 0.3) {
                view.transform = .identity
            }
        default:
            break
        }
    }
    
    deinit {
        imageTask?.cancel()
    }
}

/// UIPageViewController wrapper for SwiftUI
struct BookPageViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: BookReaderViewModel
    @Binding var currentPage: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        print("📱 [BookPageVC] makeUIViewController called")
        print("📱 [BookPageVC] Current page: \(currentPage)")
        
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        // Set initial page
        if let initialVC = context.coordinator.viewController(for: currentPage) {
            print("✅ [BookPageVC] Setting initial view controller for page \(currentPage)")
            pageViewController.setViewControllers(
                [initialVC],
                direction: .forward,
                animated: false
            )
        } else {
            print("❌ [BookPageVC] Failed to create initial view controller for page \(currentPage)")
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // Update current page if it changed from outside the page view controller
        guard let currentVC = pageViewController.viewControllers?.first as? BookPageViewController,
              context.coordinator.pageNumber(for: currentVC) != currentPage,
              let newVC = context.coordinator.viewController(for: currentPage) else {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = 
            context.coordinator.pageNumber(for: currentVC) < currentPage ? .forward : .reverse
        
        pageViewController.setViewControllers(
            [newVC],
            direction: direction,
            animated: true
        )
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: BookPageViewControllerRepresentable
        private var viewControllers: [Int: BookPageViewController] = [:]
        
        init(_ parent: BookPageViewControllerRepresentable) {
            self.parent = parent
        }
        
        func viewController(for page: Int) -> BookPageViewController? {
            print("🔧 [Coordinator] viewController(for: \(page)) called")
            print("🔧 [Coordinator] Total pages: \(parent.viewModel.totalPages)")
            
            guard page > 0 && page <= parent.viewModel.totalPages else {
                print("❌ [Coordinator] Page \(page) is out of range (1...\(parent.viewModel.totalPages))")
                return nil
            }
            
            guard let url = parent.viewModel.urlForPage(page) else {
                print("❌ [Coordinator] Failed to generate URL for page \(page)")
                return nil
            }
            
            print("✅ [Coordinator] Generated URL for page \(page): \(url.absoluteString)")
            
            // Cache view controllers
            if let existingVC = viewControllers[page] {
                print("♻️ [Coordinator] Reusing cached view controller for page \(page)")
                return existingVC
            }
            
            print("🆕 [Coordinator] Creating new view controller for page \(page)")
            let vc = BookPageViewController(pageNumber: page, imageURL: url)
            viewControllers[page] = vc
            return vc
        }
        
        func pageNumber(for viewController: UIViewController) -> Int {
            guard let bookPageVC = viewController as? BookPageViewController else {
                return 0
            }
            
            for (page, vc) in viewControllers {
                if vc === bookPageVC {
                    return page
                }
            }
            return 0
        }
        
        // MARK: - UIPageViewControllerDataSource
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            let currentPage = pageNumber(for: viewController)
            guard currentPage > 1 else { return nil }
            return self.viewController(for: currentPage - 1)
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            let currentPage = pageNumber(for: viewController)
            guard currentPage < parent.viewModel.totalPages else { return nil }
            return self.viewController(for: currentPage + 1)
        }
        
        // MARK: - UIPageViewControllerDelegate
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let currentVC = pageViewController.viewControllers?.first else {
                return
            }
            
            let newPage = pageNumber(for: currentVC)
            if newPage != parent.currentPage {
                parent.currentPage = newPage
            }
        }
    }
}
