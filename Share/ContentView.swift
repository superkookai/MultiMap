//
//  ContentView.swift
//  MultiMap
//
//  Created by Weerawut Chaiyasomboon on 22/11/2567 BE.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var mapCamera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
    )
    
    @AppStorage("searchText") private var searchText = ""
    
    @State private var locations = [Location]()
    
    @State private var selectedLocations: Set<Location> = []
    
    @State private var isShowLocationExistAlert = false
    
    @State private var isShowNoSearchResponseAlert = false
    
    var body: some View {
        NavigationSplitView {
            List(locations,selection: $selectedLocations){ location in
                Text(location.name)
                    .tag(location)
                    .contextMenu {
                        Button(role: .destructive) {
                            for location in selectedLocations{
                                delete(location)
                            }
                        } label: {
                            Text("Delete")
                        }

                    }
            }
            .frame(minWidth: 200)
//            .onDeleteCommand {
//                for location in selectedLocations{
//                    delete(location)
//                }
//            }
        } detail: {
            Map(position: $mapCamera){
                ForEach(locations) { location in
                    Annotation(location.name, coordinate: location.coordinate){
                        VStack {
                            Text(location.name)
                                .font(.headline)
                            Text(location.country)
                                .font(.caption)
                        }
                        .padding(5)
                        .padding(.horizontal,5)
                        .background(.black)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: selectedLocations) {
                //Create empty rect
                var visibleMap = MKMapRect.null
                for location in selectedLocations{
                    //Make location to point
                    let mapPoint = MKMapPoint(location.coordinate)
                    //Make point to rect
                    let pointRect = MKMapRect(x: mapPoint.x - 100_000, y: mapPoint.y - 100_000, width: 200_000, height: 200_200)
                    //Union new rect
                    visibleMap = visibleMap.union(pointRect)
                }
                //Convert rect to region
                var newRegion = MKCoordinateRegion(visibleMap)
                //Add some padding to new region
                newRegion.span.latitudeDelta *= 1.5
                newRegion.span.longitudeDelta *= 1.5
                
                //Set new region to the map camera with animation
                withAnimation{
                    mapCamera = .region(newRegion)
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
        .onSubmit(of: .search, checkLocationExistThenSearch)
        .alert("Location already exist!", isPresented: $isShowLocationExistAlert) {
            Button("OK") {
                searchText = ""
            }
        }
        .alert("No location found", isPresented: $isShowNoSearchResponseAlert) {
            Button("OK") {
                searchText = ""
            }
        }
    }
    
    func checkLocationExistThenSearch(){
        //Check search location already exist in the list
        if locations.contains(where: { $0.name.lowercased() == searchText.lowercased() }){
            isShowLocationExistAlert = true
            return
        }else{
            runSearch()
        }
    }
        
    func runSearch(){
        Task{
            //Create search request with natural language
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = searchText
            
            //Create search with searchRequest
            let search = MKLocalSearch(request: searchRequest)
            
            do{
                //Make search start and get response
                let response = try await search.start()
                
                //Get only one mapItem
                guard let item = response.mapItems.first else { return }
                //Get item name/location
                guard let itemName = item.name, let itemLocation = item.placemark.location, let itemCountry = item.placemark.country else { return }
                //Create Location and add to locations array
                let newLocation = Location(name: itemName, country: itemCountry, latitude: itemLocation.coordinate.latitude, longitude: itemLocation.coordinate.longitude)
                locations.append(newLocation)
                //Add new location to selectedLocations Set
                selectedLocations = [newLocation]
                
                //Clear search text
                searchText = ""
            }catch{
                isShowNoSearchResponseAlert = true
            }
        }
    }
    
    func delete(_ location: Location){
        guard let index = locations.firstIndex(of: location) else { return }
        locations.remove(at: index)
        
        getBackToDefaultCamera()
        
    }
    
    func getBackToDefaultCamera(){
        withAnimation{
            mapCamera = MapCameraPosition.region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
                    span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                )
            )
        }
    }
    
//    func removeExistingLocation(){
//        locations.removeAll(where: {$0.name.lowercased() == searchText.lowercased()})
//    }
}

#Preview {
    ContentView()
}


// Create Search function by using TextField and Button
//                HStack{
//                    TextField("Search for something...", text: $searchText)
//                        .onSubmit(runSearch)
//
//                    Button("Go",action: runSearch)
//                }
//                .padding([.top, .horizontal])


extension View {
    func selectOnDeleteByPlatform() -> some View {
        #if os(macOS)
            self
            .onDeleteCommand {
                for location in selectedLocations{
                    delete(location)
                }
            }
        #elseif os(iOS)
            self
            
        #endif
    }
}
