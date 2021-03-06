//
//  MediaDetailViewController.swift
//  uStream
//
//  Created by stanley phillips on 2/22/21.
//

import UIKit
import SafariServices

protocol RefreshDelegate: AnyObject {
    func refresh()
}

class MediaDetailViewController: UIViewController, SFSafariViewControllerDelegate  {
    // MARK: - Sections
    private enum Section: Int, CaseIterable {
        case selectedMedia
        case whereToWatch
        case similar
    }
    
    // MARK: - Properties
    var selectedMedia: Media? {
        didSet {
            collectionView.reloadSections([0])
            collectionView.scrollToItem(at: [0,0], at: .top, animated: false)
        }
    }
    
    var providerLink: String?
    var providers: [Provider] = []
    var similar: [Media] = []
    
    static weak var delegate: RefreshDelegate?
    
    // MARK: - Views
    lazy var dismissViewButton: UIButton = {
        let button: UIButton = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        button.tintColor = .systemGray2
        button.contentMode = .scaleAspectFill
        button.setPreferredSymbolConfiguration(.init(pointSize: 18), forImageIn: .normal)
        button.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.makeLayout())
        collectionView.backgroundColor = UIColor.systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPrefetchingEnabled = true
        collectionView.prefetchDataSource = self
        collectionView.register(MediaDetailCollectionViewCell.self, forCellWithReuseIdentifier: "mediaDetailCell")
        collectionView.register(WhereToWatchCollectionViewCell.self, forCellWithReuseIdentifier: "providerCell")
        collectionView.register(MediaCollectionViewCell.self, forCellWithReuseIdentifier: "similarCell")
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.systemBackground
        setupViews()
    }
    
    // MARK: - Methods
    func setupViews() {
        fetchWhereToWatch()
        fetchSimilar()
        
        self.view.addSubview(self.dismissViewButton)
        self.view.addSubview(self.collectionView)
        
        NSLayoutConstraint.activate([
            self.dismissViewButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8),
            self.dismissViewButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
        ])
        
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.dismissViewButton.bottomAnchor, constant: 0),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }//end func
    
    func makeLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (section, env) -> NSCollectionLayoutSection? in
            switch section {
            case Section.selectedMedia.rawValue:
                return LayoutBuilder.buildMediaDetailSection()
            case Section.whereToWatch.rawValue:
                if self.providers.count != 0 {
                    return LayoutBuilder.buildWhereToWatchIconSection()
                } else {
                    return nil
                }
            case Section.similar.rawValue:
                if self.similar.count != 0 {
                    return LayoutBuilder.buildMediaHorizontalScrollLayout()
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }//end func
    
    func fetchWhereToWatch() {
        guard let media = selectedMedia else {return}
        let mediaType = media.getMediaTypeFor(media)
        MediaService().fetchProviders(.whereToWatch(mediaType, media.id ?? 603)) { [weak self] (result) in
            switch result {
            case .success(let location):
                DispatchQueue.main.async {
                    self?.providers = location.streaming ?? []
                    self?.providerLink = location.deepLink
                    self?.collectionView.reloadSections([1])
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
//        WhereToWatchController.fetchWhereToWatchBy(id: media.id ?? 603, mediaType: mediaType) { [weak self] (result) in
//            switch result {
//            case .success(let location):
//                DispatchQueue.main.async {
//                    self?.providers = location.streaming ?? []
//                    self?.providerLink = location.deepLink
//                    self?.collectionView.reloadSections([1])
//                }
//            case .failure(let error):
//                print(error.localizedDescription)
//            }
//        }
    }//end func
    
    func fetchSimilar() {
        guard let media = selectedMedia else {return}
        let mediaType = media.getMediaTypeFor(media)
        MediaService().fetch(.similar(mediaType, media.id ?? 603)) { [weak self] (result: Result<MediaResults, NetError>) in
            switch result {
            case .success(let similar):
                DispatchQueue.main.async {
                    let similarWithPoster = similar.results.filter { (result) -> Bool in
                        return result.backdropPath != nil
                    }
                    self?.similar = similarWithPoster
                    self?.collectionView.reloadSections([2])
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }//end func
    
    func launchApp(provider: Provider) {
        guard let providerName = provider.providerName else {return}
        print(providerName)
        let url = AppLinks.getURLFor(providerName: providerName)
        print(url)
        if let appURL = URL(string: url) {
            UIApplication.shared.open(appURL) { success in
                if success {
                    print("The URL was delivered successfully.")
                } else {
                    print("The URL failed to open.")
                    if AppLinks.supportedApps.contains(providerName) {
                        let appID = AppLinks.getIDfor(providerName: providerName)
                        self.presentAppNotInstalledAlert(appName: providerName, appID: appID)
                    } else {
                        self.presentAppNotSupportedAlert(appName: providerName)
                    }
                }
            }
        } else {
            print("Invalid URL specified.")
        }
    }//end func
    
    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }//end func
}//end class

// MARK: - Extensions
extension MediaDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case Section.selectedMedia.rawValue:
            return 1
        case Section.whereToWatch.rawValue:
            return providers.count
        case Section.similar.rawValue:
            return similar.count
        default:
            return 0
        }
    }//end func
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SectionHeader else {return UICollectionReusableView()}
        
        switch indexPath.section {
        case Section.selectedMedia.rawValue:
            header.setup(label: ((self.selectedMedia?.name ?? self.selectedMedia?.title) ?? "The Matrix"))
        case Section.whereToWatch.rawValue:
            header.setup(label: "Stream")
        case Section.similar.rawValue:
            header.setup(label: "Similar")
        default:
            break
        }
        
        return header
    }//end func
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if indexPath.section == Section.similar.rawValue {
                ImageService().fetchImage(.poster(similar[indexPath.row].posterPath ?? "")) {(_) in}
            }
        }
    }//end func
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case Section.selectedMedia.rawValue:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaDetailCell", for: indexPath) as? MediaDetailCollectionViewCell else {return UICollectionViewCell()}
            guard let media = selectedMedia else {return UICollectionViewCell()}
            cell.addDelegate = self
            cell.setup(media: media)
            return cell
            
        case Section.whereToWatch.rawValue:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "providerCell", for: indexPath) as? WhereToWatchCollectionViewCell else {return UICollectionViewCell()}
            cell.setup(provider: providers[indexPath.row], newIndexPath: indexPath)
            return cell
            
        case Section.similar.rawValue:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "similarCell", for: indexPath) as? MediaCollectionViewCell else {return UICollectionViewCell()}
            cell.setup(media: similar[indexPath.row], indexPath: indexPath)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }//end func
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.whereToWatch.rawValue:
            launchApp(provider: providers[indexPath.row])
        case Section.similar.rawValue:
            selectedMedia = similar[indexPath.row]
            setupViews()
        default:
            break
        }
    }//end func
}//end extension

extension MediaDetailViewController: AddToListButtonDelegate {
    func addToList() {
        guard let selectedMedia = self.selectedMedia else {return}
        Haptics.playSuccessNotification()
        ListMediaController.shared.addToList(media: selectedMedia)
        MediaDetailViewController.delegate?.refresh()
    }
}//end extension
