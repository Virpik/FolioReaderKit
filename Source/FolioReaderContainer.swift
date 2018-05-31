//
//  FolioReaderContainer.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FontBlaster

/// Reader container
open class FolioReaderContainer: UIViewController {
    
    var shouldHideStatusBar = true
    
///    public var epubPath: String
//    public var unzipPath: String!
//    public var book: FRBook
    
    public var centerNavigationController: UINavigationController?
    public var centerViewController: FolioReaderCenter?
    public var audioPlayer: FolioReaderAudioPlayer?
    
    public var readerConfig: FolioReaderConfig
    public var folioReader: FolioReader

    fileprivate var errorOnLoad = false

    // MARK: - Init

    /// Init a Folio Reader Container
    ///
    /// - Parameters:
    ///   - config: Current Folio Reader configuration
    ///   - folioReader: Current instance of the FolioReader kit.
    ///   - path: The ePub path on system. Must not be nil nor empty string.
	///   - unzipPath: Path to unzip the compressed epub.
    ///   - removeEpub: Should delete the original file after unzip? Default to `true` so the ePub will be unziped only once.
    public init(withConfig config: FolioReaderConfig, folioReader: FolioReader) {
        
        self.readerConfig = config
        self.folioReader = folioReader

//        self.book = FRBook()

        super.init(nibName: nil, bundle: Bundle.frameworkBundle())

        // Configure the folio reader.
        self.folioReader.readerContainer = self
    }

    required public init?(coder aDecoder: NSCoder) {
        // When a FolioReaderContainer object is instantiated from the storyboard this function is called before.
        // At this moment, we need to initialize all non-optional objects with default values.
        // The function `setupConfig(config:epubPath:removeEpub:)` MUST be called afterward.
        // See the ExampleFolioReaderContainer.swift for more information?
        self.readerConfig = FolioReaderConfig()
        self.folioReader = FolioReader()
        
        self.book = FRBook()

        super.init(coder: aDecoder)

        // Configure the folio reader.
        self.folioReader.readerContainer = self
    }

    /// Common Initialization
    fileprivate func initialization() {
        // Register custom fonts
        FontBlaster.blast(bundle: Bundle.frameworkBundle())

        // Register initial defaults
        self.folioReader.register(defaults: [
            kCurrentFontFamily: FolioReaderFont.andada.rawValue,
            kNightMode: false,
            kCurrentFontSize: 2,
            kCurrentAudioRate: 1,
            kCurrentHighlightStyle: 0,
            kCurrentTOCMenu: 0,
            kCurrentMediaOverlayStyle: MediaOverlayStyle.default.rawValue,
            kCurrentScrollDirection: FolioReaderScrollDirection.defaultVertical.rawValue
        ])
    }

    /// Set the `FolioReaderConfig` and epubPath.
    ///
    /// - Parameters:
    ///   - config: Current Folio Reader configuration
    ///   - path: The ePub path on system. Must not be nil nor empty string.
	///   - unzipPath: Path to unzip the compressed epub.
    ///   - removeEpub: Should delete the original file after unzip? Default to `true` so the ePub will be unziped only once.
    open func setupConfig(_ config: FolioReaderConfig) {
        self.readerConfig = config
        self.folioReader = FolioReader()
        self.folioReader.readerContainer = self
    }

    // MARK: - View life cicle

    override open func viewDidLoad() {
        super.viewDidLoad()

        _ = {
            let canChangeScrollDirection = self.readerConfig.canChangeScrollDirection
            self.readerConfig.canChangeScrollDirection = self.readerConfig.isDirection(canChangeScrollDirection, canChangeScrollDirection, false)
            
            // If user can change scroll direction use the last saved
            if self.readerConfig.canChangeScrollDirection == true {
                
                let cScrollDirrection = self.folioReader.currentScrollDirection
                var scrollDirection = FolioReaderScrollDirection(rawValue: cScrollDirrection) ?? .vertical
                
                if (scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical) {
                    scrollDirection = self.readerConfig.scrollDirection
                }
                
                self.readerConfig.scrollDirection = scrollDirection
            }
        }()

        _ = {
            let hideBars = readerConfig.hideBars
            
            let shouldHideNavigationOnTap = self.readerConfig.shouldHideNavigationOnTap
            self.readerConfig.shouldHideNavigationOnTap = ((hideBars == true) ? true : shouldHideNavigationOnTap)
            
            self.centerViewController = FolioReaderCenter(withContainer: self)
            
            if let rootViewController = self.centerViewController {
                self.centerNavigationController = UINavigationController(rootViewController: rootViewController)
            }
        }()

        _ = {
            let shouldHideNavigationOnTap = self.readerConfig.shouldHideNavigationOnTap
            self.centerNavigationController?.setNavigationBarHidden(shouldHideNavigationOnTap, animated: false)
            
            if let _centerNavigationController = self.centerNavigationController {
                self.view.addSubview(_centerNavigationController.view)
                self.addChildViewController(_centerNavigationController)
            }
            
            self.centerNavigationController?.didMove(toParentViewController: self)
            
            if (self.readerConfig.hideBars == true) {
                self.readerConfig.shouldHideNavigationOnTap = false
                self.navigationController?.navigationBar.isHidden = true
                self.centerViewController?.pageIndicatorHeight = 0
            }
        }()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if (self.errorOnLoad == true) {
            self.dismiss()
        }
    }

    func read(book: FRBook) {
        self.book = book
        self.folioReader.isReaderOpen = true
        
        if self.book.hasAudio || self.readerConfig.enableTTS {
            self.addAudioPlayer()
        }
        
        self.folioReader.isReaderReady = true
        self.folioReader.delegate?.folioReader?(self.folioReader, didFinishedLoading: self.book)
        
        self.centerViewController?.reloadData()
    }
    
    /**
     Initialize the media player
     */
    func addAudioPlayer() {
        self.audioPlayer = FolioReaderAudioPlayer(withFolioReader: self.folioReader, book: self.book)
        self.folioReader.readerAudioPlayer = audioPlayer
    }

    // MARK: - Status Bar

    override open var prefersStatusBarHidden: Bool {
        return (self.readerConfig.shouldHideNavigationOnTap == false ? false : self.shouldHideStatusBar)
    }

    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return self.folioReader.isNight(.lightContent, .default)
    }
}

extension FolioReaderContainer {
    func alert(message: String) {
        let alertController = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) { [weak self]
            (result : UIAlertAction) -> Void in
            self?.dismiss()
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
}
