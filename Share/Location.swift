//
//  Location.swift
//  MultiMap
//
//  Created by Weerawut Chaiyasomboon on 22/11/2567 BE.
//

import MapKit

struct Location: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
