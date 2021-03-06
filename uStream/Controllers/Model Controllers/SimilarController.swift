//
//  SimilarController.swift
//  uStream
//
//  Created by stanley phillips on 2/24/21.
//

import UIKit
//base urlhttps://api.themoviedb.org/
//image urlhttp://image.tmdb.org/t/p/w500/(imageEndpoint)
//https://api.themoviedb.org/3/movie/603/recommendations?api_key=48bcdd5f1ad8e7b88756b97c0c6c3c74&language=en-US&page=1

class SimilarController {
    // MARK: - String Constants
    static let posterBaseURL = URL(string: "https://image.tmdb.org/t/p/w500/")
    static let baseURL = URL(string: "https://api.themoviedb.org/")
    static let versionComponent = "3"
    static let recommendationsComponent = "similar"
    static let apiKey = "48bcdd5f1ad8e7b88756b97c0c6c3c74"
    
    // MARK: - Properties
    static var imageCache = NSCache<NSURL, UIImage>()

    static func fetchSimilarFor(mediaType: String, id: Int, completion: @escaping (Result<[Media], NetworkError>) -> Void) {
        guard let baseURL = baseURL else {return completion(.failure(.invalidURL))}
        let versionURL = baseURL.appendingPathComponent(versionComponent)
        let mediaTypeURL = versionURL.appendingPathComponent(mediaType)
        let mediaIDURL = mediaTypeURL.appendingPathComponent(String(id))
        let recommendationsURL = mediaIDURL.appendingPathComponent(recommendationsComponent)
        
        var components = URLComponents(url: recommendationsURL, resolvingAgainstBaseURL: true)
        let apiQuery = URLQueryItem(name: "api_key", value: apiKey)
        
        components?.queryItems = [apiQuery]
        
        guard let finalURL = components?.url else {return completion(.failure(.invalidURL))}
        print(finalURL)
        
        URLSession.shared.dataTask(with: finalURL) { (data, response, error) in
            if let error = error {
                print("======== ERROR ========")
                print("Function: \(#function)")
                print("Error: \(error)")
                print("Description: \(error.localizedDescription)")
                print("======== ERROR ========")
                return completion(.failure(.thrownError(error)))
            }
            
            if let response = response as? HTTPURLResponse {
                print("SIMILAR STATUS CODE: \(response.statusCode)")
            }
            
            guard let data = data else {return completion(.failure(.noData))}
            do {
                let similar = try JSONDecoder().decode(Similar.self, from: data)
                let similarWithPoster = similar.results.filter { (result) -> Bool in
                    return result.backdropPath != nil
                }
                return completion(.success(similarWithPoster))
            } catch {
                completion(.failure(.thrownError(error)))
            }
        }.resume()
    }//end func
}//end class
