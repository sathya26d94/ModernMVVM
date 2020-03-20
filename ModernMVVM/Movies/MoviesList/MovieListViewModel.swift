//
//  MovieListViewModel.swift
//  AsyncImageList
//
//  Created by Vadim Bulavin on 3/17/20.
//  Copyright © 2020 Vadym Bulavin. All rights reserved.
//

import Foundation
import Combine

final class MoviesListViewModel: ObservableObject {
    @Published private(set) var state = State.idle
    
    let navigation = PassthroughSubject<Route, Never>()
            
    private var bag = Set<AnyCancellable>()
    
    private let input = PassthroughSubject<Event, Never>()
    
    init() {
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
        
//        $state.compactMap { state in
//            switch state {
//            case .showingMovieDetail(let movies, let selectedMovie):
//                return Route(movieDetail: selectedMovie)
//            default:
//                return nil
//            }
//        }
//        .subscribe(navigation)
//        .store(in: &bag)
    }
    
    deinit {
        bag.removeAll()
    }
    
    func send(event: Event) {
        input.send(event)
    }
    
    enum State {
        case idle
        case loading
        case loaded([ListItem])
        case error(Error)
//        case showingMovieDetail([MovieListItemViewModel], MovieDetailViewModel)
    }
    
    enum Event {
        case onAppear
        case onDisappear
        case onSelectMovie(Int)
        case onMoviesLoaded([ListItem])
        case onFailedToLoadMovies(Error)
    }
    
    struct Route {
        let movieDetail: MovieDetailViewModel
    }
    
    struct ListItem: Identifiable {
        let id: Int
        let title: String
        let poster: URL?
        
        init(movie: MovieDTO) {
            id = movie.id
            title = movie.title
            poster = movie.poster
        }
    }
    
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .onAppear:
                return .loading
            default:
                return state
            }
        case .loading:
            switch event {
            case .onFailedToLoadMovies(let error):
                return .error(error)
            case .onMoviesLoaded(let movies):
                return .loaded(movies)
            default:
                return state
            }
        case .loaded:
//            switch event {
//            case .onSelectMovie(let id):
//                return .showingMovieDetail(movies, MovieDetailViewModel(movieID: id))
//            default:
                return state
//            }
        case .error:
            return state
//        case .showingMovieDetail(let movies, _):
//            switch event {
//            case .onDisappear:
//                return .loaded(movies)
//            default:
//                return state
//            }
        }
    }
    
    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state else { return Empty().eraseToAnyPublisher() }
            
            return MoviesAPI.trending()
                .map { $0.results.map(ListItem.init) }
                .map(Event.onMoviesLoaded)
                .catch { Just(Event.onFailedToLoadMovies($0)) }
                .eraseToAnyPublisher()
        }
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback(run: { _ in
            return input
        })
    }
}
