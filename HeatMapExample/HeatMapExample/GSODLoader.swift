//
//  GSODLoader.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//


// GSODLoader.swift

import Foundation
import CoreLocation

struct GSODLoader {

    struct RawPoint: Decodable {
        let latitude: Double
        let longitude: Double
        let weight: Double
    }

    struct GSODFile: Decodable {
        let date: String
        let field: String
        let valueMin: Double
        let valueMax: Double
        let count: Int
        let points: [RawPoint]

        enum CodingKeys: String, CodingKey {
            case date, field, count, points
            case valueMin = "value_min"
            case valueMax = "value_max"
        }
    }

    static func load(from url: URL) throws -> [HeatMapPoint] {
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(GSODFile.self, from: data)
        return file.points.map { raw in
            HeatMapPoint(
                coordinate: CLLocationCoordinate2D(
                    latitude: raw.latitude,
                    longitude: raw.longitude
                ),
                weight: raw.weight
            )
        }
    }
}