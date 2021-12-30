# -*- encoding: utf-8 -*-
import math


# Copied from https://github.com/komoot/staticmap/blob/master/staticmap/staticmap.py
# original code is distributed with Apache 2.0
def lon_to_x(lon, zoom_level):
    """
    transform longitude to tile number
    :type lon: float
    :type zoom_level: int
    :rtype: float
    """
    if not (-180 <= lon <= 180):
        lon = (lon + 180) % 360 - 180

    return ((lon + 180.) / 360) * pow(2, zoom_level)


# Copied from https://github.com/komoot/staticmap/blob/master/staticmap/staticmap.py
# original code is distributed with Apache 2.0
def lat_to_y(lat, zoom_level):
    """
    transform latitude to tile number
    :type lat: float
    :type zoom_level: int
    :rtype: float
    """
    if not (-90 <= lat <= 90):
        lat = (lat + 90) % 180 - 90

    return (1 - math.log(math.tan(lat * math.pi / 180) + 1 / math.cos(lat * math.pi / 180)) / math.pi) / 2 * pow(2, zoom_level)


# See https://wiki.openstreetmap.org/wiki/Zoom_levels
def calc_meters_per_pixel(latitude, zoom_level, earth_radius=6378137.000):
    earth_circumference = 2 * math.pi * earth_radius
    return earth_circumference * math.cos(math.radians(latitude)) / 2 ** (zoom_level+8)


def calc_transform_from_lon_lat(
        from_longitude,
        from_latitude,
        to_longitude,
        to_latitude,
        zoom_level=18,
        tile_size=256):
    resolution = calc_meters_per_pixel(from_latitude, zoom_level)
    from_x_meter = lon_to_x(from_longitude, zoom_level) * tile_size * resolution
    from_y_meter = lat_to_y(-from_latitude, zoom_level) * tile_size * resolution
    to_x_meter = lon_to_x(to_longitude, zoom_level) * tile_size * resolution
    to_y_meter = lat_to_y(-to_latitude, zoom_level) * tile_size * resolution
    diff_x_meter = to_x_meter - from_x_meter
    diff_y_meter = to_y_meter - from_y_meter
    return diff_x_meter, diff_y_meter
