//
//  TrendingPeopleCollectionViewCell.swift
//  uStream
//
//  Created by stanley phillips on 2/22/21.
//

import UIKit

public class TrendingPeopleCollectionViewCell: UICollectionViewCell {
    // MARK: - Views
    var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.cornerRadius = 15
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 15
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var profileImageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    var subtitleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.text = "error fetching"
        label.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(8)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.container)
        self.container.addSubview(self.profileImageView)
        self.container.addSubview(self.subtitleLabel)

        NSLayoutConstraint.activate([
            self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.container.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.container.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
        ])
        
        NSLayoutConstraint.activate([
            self.profileImageView.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 0),
            self.profileImageView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: 0),
            self.profileImageView.leadingAnchor.constraint(equalTo: self.container.leadingAnchor, constant: 0),
            self.profileImageView.trailingAnchor.constraint(equalTo: self.container.trailingAnchor, constant: 0),
        ])
        
        NSLayoutConstraint.activate([
            self.subtitleLabel.topAnchor.constraint(equalTo: self.profileImageView.bottomAnchor, constant: 6),
            self.subtitleLabel.centerXAnchor.constraint(equalTo: self.profileImageView.centerXAnchor, constant: 0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        profileImageView.image = nil
    }
    
    func setupCell(person: Person) {
        TrendingPeopleController.fetchPosterFor(person: person) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.profileImageView.image = image
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        self.subtitleLabel.text = person.name
    }//end func
}//end class