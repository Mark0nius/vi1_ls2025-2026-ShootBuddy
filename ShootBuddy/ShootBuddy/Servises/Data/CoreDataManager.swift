//
//  CoreDataManager.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import SwiftUI
import CoreData
import CoreLocation

final class CoreDataManager: DataManaging {
    private let container = NSPersistentContainer(name: "ShootBuddy") // must match the .xcdatamodeld name – beware of typos!
    private var context: NSManagedObjectContext { container.viewContext }

    init() {
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to create container: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Spots

    func saveSpot(_ spot: Spot) {
        let request = SpotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", spot.id as CVarArg)
        request.fetchLimit = 1

        do {
            let existingEntity = try context.fetch(request).first
            let entity = existingEntity ?? SpotEntity(context: context) // upsert by id
            apply(spot, to: entity)
            save()
        } catch {
            print("Could not save spot: \(error)")
        }
    }

    func fetchSpots() -> [Spot] {
        let request = NSFetchRequest<SpotEntity>(entityName: "SpotEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let entities = try context.fetch(request)
            return entities.map(makeSpot)
        } catch {
            print("CoreDataManager fetchSpots error: \(error.localizedDescription)")
            return []
        }
    }

    func deleteSpot(_ spot: Spot) {
        guard let entity = spotEntity(id: spot.id) else {
            print("CoreDataManager deleteSpot error: spot not found")
            return
        }
        context.delete(entity) // cascades to its photos
        save()
    }

    // MARK: - Routes

    func saveRoute(_ route: Route) {
        let entity = routeEntity(id: route.id) ?? RouteEntity(context: context)
        apply(route, to: entity)
        save()
    }

    func fetchRoutes() -> [Route] {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

        do {
            let entities = try context.fetch(request)
            return entities.map(makeRoute)
        } catch {
            print("CoreDataManager fetchRoutes error: \(error.localizedDescription)")
            return []
        }
    }

    func deleteRoute(_ route: Route) {
        guard let entity = routeEntity(id: route.id) else {
            print("CoreDataManager deleteRoute error: route not found")
            return
        }
        context.delete(entity) // cascades to its stops
        save()
    }

    // MARK: - Shoot presets

    func savePreset(_ preset: ShootPreset) {
        let entity = presetEntity(id: preset.id) ?? ShootPresetEntity(context: context)
        entity.id = preset.id
        entity.name = preset.name
        entity.setUpMinutes = Int16(clamping: preset.setUpMinutes)
        entity.averageShootMinutes = Int16(clamping: preset.averageShootMinutes)
        entity.packUpMinutes = Int16(clamping: preset.packUpMinutes)
        save()
    }

    func fetchPresets() -> [ShootPreset] {
        let request = NSFetchRequest<ShootPresetEntity>(entityName: "ShootPresetEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let entities = try context.fetch(request)
            return entities.map { entity in
                ShootPreset(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "No name",
                    setUpMinutes: Int(entity.setUpMinutes),
                    averageShootMinutes: Int(entity.averageShootMinutes),
                    packUpMinutes: Int(entity.packUpMinutes)
                )
            }
        } catch {
            print("CoreDataManager fetchPresets error: \(error.localizedDescription)")
            return []
        }
    }

    func deletePreset(_ preset: ShootPreset) {
        guard let entity = presetEntity(id: preset.id) else {
            print("CoreDataManager deletePreset error: preset not found")
            return
        }
        context.delete(entity)
        save()
    }
}

// MARK: - Private methods
private extension CoreDataManager {

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Cannot save MOC: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Light conditions (stored as Binary Data)

    /// Encodes the light conditions' raw values into `Data` for the
    /// Binary Data attribute.
    func encodeLightConditions(_ lights: [LightType]) -> Data? {
        let rawValues = lights.map { $0.rawValue } // [Int16]
        return try? JSONEncoder().encode(rawValues)
    }

    /// Decodes the Binary Data attribute back into `[LightType]`.
    func decodeLightConditions(_ data: Data?) -> [LightType] {
        guard let data,
              let rawValues = try? JSONDecoder().decode([Int16].self, from: data) else {
            return []
        }
        return rawValues.compactMap { LightType(rawValue: $0) }
    }

    // MARK: Fetch-by-id helpers

    func spotEntity(id: UUID) -> SpotEntity? {
        let request = NSFetchRequest<SpotEntity>(entityName: "SpotEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    func routeEntity(id: UUID) -> RouteEntity? {
        let request = NSFetchRequest<RouteEntity>(entityName: "RouteEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    func presetEntity(id: UUID) -> ShootPresetEntity? {
        let request = NSFetchRequest<ShootPresetEntity>(entityName: "ShootPresetEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    // MARK: Spot mapping

    /// Copies a `Spot` struct into a `SpotEntity`, rebuilding its photos.
    func apply(_ spot: Spot, to entity: SpotEntity) {
        entity.id = spot.id
        entity.name = spot.name
        entity.street = spot.address.street
        entity.houseNumber = spot.address.houseNumber
        entity.orientationalNumber = spot.address.orientationalNumber
        entity.city = spot.address.city
        entity.latitude = spot.coordinate.latitude
        entity.longitude = spot.coordinate.longitude
        entity.note = spot.note

        // Light conditions are stored as Binary Data (encoded raw Int16 values).
        entity.lightConditions = encodeLightConditions(spot.lightConditions)

        // Rebuild the photo set: delete the old PhotoEntities, recreate from the struct.
        if let existingPhotos = entity.photos {
            for case let photo as PhotoEntity in existingPhotos {
                context.delete(photo)
            }
        }
        let photoEntities: [PhotoEntity] = spot.photos.map { photo in
            let photoEntity = PhotoEntity(context: context)
            photoEntity.id = photo.id
            photoEntity.imageData = photo.imageData
            photoEntity.spot = entity
            return photoEntity
        }
        entity.photos = NSOrderedSet(array: photoEntities)
    }

    /// Builds a `Spot` struct from a `SpotEntity`.
    func makeSpot(_ entity: SpotEntity) -> Spot {
        let address = Address(
            street: entity.street ?? "",
            houseNumber: entity.houseNumber ?? "",
            orientationalNumber: entity.orientationalNumber,
            city: entity.city ?? ""
        )

        let photos: [Photo] = (entity.photos?.array as? [PhotoEntity] ?? []).map { photoEntity in
            Photo(id: photoEntity.id ?? UUID(),
                  imageData: photoEntity.imageData ?? Data())
        }

        let lightConditions = decodeLightConditions(entity.lightConditions)

        return Spot(
            id: entity.id ?? UUID(),
            name: entity.name ?? "No name",
            address: address,
            coordinate: CLLocationCoordinate2D(latitude: entity.latitude,
                                               longitude: entity.longitude),
            lightConditions: lightConditions,
            photos: photos,
            note: entity.note
        )
    }

    /// Returns the stored `SpotEntity` for this spot, creating it if it doesn't
    /// exist yet (e.g. an auto-generated spot that was never saved on its own).
    func fetchOrCreateSpotEntity(from spot: Spot) -> SpotEntity {
        if let existing = spotEntity(id: spot.id) {
            return existing
        }
        let entity = SpotEntity(context: context)
        apply(spot, to: entity)
        return entity
    }

    // MARK: Route mapping

    /// Copies a `Route` struct into a `RouteEntity`, rebuilding its ordered stops.
    func apply(_ route: Route, to entity: RouteEntity) {
        entity.id = route.id
        entity.name = route.name
        entity.desiredSpotCount = Int16(clamping: route.desiredSpotCount)
        entity.startDate = route.startDate
        entity.endDate = route.endDate
        entity.note = route.note
        entity.calendarEventID = route.calendarEventID
        entity.transportMode = route.transportMode.rawValue

        // Rebuild the stops: delete the old RouteStopEntities, recreate in order.
        if let existingStops = entity.stops {
            for case let stop as RouteStopEntity in existingStops {
                context.delete(stop)
            }
        }
        let stopEntities: [RouteStopEntity] = route.stops.map { stop in
            let stopEntity = RouteStopEntity(context: context)
            stopEntity.id = stop.id
            stopEntity.assignedLight = stop.assignedLight.rawValue
            stopEntity.arrivalTime = stop.arrivalTime
            stopEntity.departureTime = stop.departureTime
            stopEntity.note = stop.note
            stopEntity.isAutoGenerated = stop.isAutoGenerated
            stopEntity.travelTimeFromPrevious = stop.travelTimeFromPrevious
            stopEntity.route = entity
            stopEntity.spot = fetchOrCreateSpotEntity(from: stop.spot)
            return stopEntity
        }
        entity.stops = NSOrderedSet(array: stopEntities)
    }

    /// Builds a `Route` struct from a `RouteEntity`. Stops whose spot was
    /// deleted (relationship nullified) are dropped.
    func makeRoute(_ entity: RouteEntity) -> Route {
        let stops: [RouteStop] = (entity.stops?.array as? [RouteStopEntity] ?? []).compactMap { stopEntity in
            guard let spotEntity = stopEntity.spot else { return nil }
            return RouteStop(
                id: stopEntity.id ?? UUID(),
                spot: makeSpot(spotEntity),
                assignedLight: LightType(rawValue: stopEntity.assignedLight) ?? .noonLight,
                arrivalTime: stopEntity.arrivalTime ?? Date(),
                departureTime: stopEntity.departureTime ?? Date(),
                note: stopEntity.note,
                isAutoGenerated: stopEntity.isAutoGenerated,
                travelTimeFromPrevious: stopEntity.travelTimeFromPrevious
            )
        }

        return Route(
            id: entity.id ?? UUID(),
            name: entity.name ?? "No name",
            desiredSpotCount: Int(entity.desiredSpotCount),
            startDate: entity.startDate ?? Date(),
            endDate: entity.endDate ?? Date(),
            stops: stops,
            note: entity.note,
            transportMode: TransportMode(rawValue: entity.transportMode ?? "Driving") ?? .driving,
            calendarEventID: entity.calendarEventID
        )
    }
}
