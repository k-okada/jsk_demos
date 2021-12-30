#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import rospy
from nav_msgs.msg import MapMetaData
from nav_msgs.msg import OccupancyGrid
import tf2_ros
from geometry_msgs.msg import TransformStamped

import numpy as np
import staticmap

from jsk_maps import calc_transform_from_lon_lat
from jsk_maps import calc_meters_per_pixel

from dynamic_reconfigure.server import Server
from jsk_maps.cfg import StaticMapPublisherConfig


class StaticMapPublisher:

    def callback_config(self, config, level):

        rospy.logdebug('level: {}'.format(level))
        rospy.logdebug('config: {}'.format(config))

        self.center_latitude = config['center_latitude']
        self.center_longitude = config['center_longitude']
        self.zoom_level = config['zoom_level']

        self.render_map()
        self.publish_map()
        self.calc_transform()

        return config

    def __init__(self):

        self.center_latitude = None
        self.center_longitude = None
        self.zoom_level = None

        self.initial_latitude = rospy.get_param('~initial_latitude')
        self.initial_longitude = rospy.get_param('~initial_longitude')

        self.map_size = rospy.get_param(
            '~map_size', 1000)
        self.map_type = rospy.get_param(
            '~map_type', 'osm')  # 'osm' or 'gsi_jp'
        self.initial_frame = rospy.get_param(
            '~initial_frame', 'initial_frame')
        self.static_map_frame = rospy.get_param(
            '~static_map_frame', 'static_map_frame')

        self.transform_initial_to_static = TransformStamped()
        self.transform_initial_to_static.header.frame_id = self.initial_frame
        self.transform_initial_to_static.child_frame_id = self.static_map_frame
        self.transform_initial_to_static.transform.rotation.w = 1.0

        if self.map_type == 'osm':
            self.static_map = staticmap.StaticMap(
                self.map_size,
                self.map_size,
                url_template='https://tile.openstreetmap.org/{z}/{x}/{y}.png')
        elif self.map_type == 'gsi_jp':
            self.static_map = staticmap.StaticMap(
                self.map_size,
                self.map_size,
                url_template='https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png')

        self.msg_map_meta_data = MapMetaData()
        self.msg_occupancy_grid = OccupancyGrid()

        self.tf_br = tf2_ros.TransformBroadcaster()

        self.pub_map_meta_data = rospy.Publisher(
            '/map_meta_data', MapMetaData, queue_size=1, latch=True)
        self.pub_occupancy_grid = rospy.Publisher(
            '/map', OccupancyGrid, queue_size=1, latch=True)

        self.srv_config = Server(
            StaticMapPublisherConfig, self.callback_config)

        rospy.logwarn('Initialized')

    def spin(self):
        rate = rospy.Rate(10)
        while not rospy.is_shutdown():
            self.calc_transform()
            self.publish_tf()
            rate.sleep()

    def calc_transform(self):
        # 地球を球体と仮定して、intial周りを平面近似して計算
        diff_x_meter, diff_y_meter = calc_transform_from_lon_lat(
            self.initial_longitude,
            self.initial_latitude,
            self.center_longitude,
            self.center_latitude,
            self.zoom_level
        )
        self.transform_initial_to_static.transform.translation.x = diff_x_meter
        self.transform_initial_to_static.transform.translation.y = diff_y_meter

    def render_map(self):
        map_resolution = calc_meters_per_pixel(
            self.center_latitude,
            self.zoom_level
        )
        rospy.logdebug('map resolution is {}'.format(map_resolution))
        rospy.logdebug('rendering map with parameter zoom : {}, center: {}'.format(
            self.zoom_level,
            (self.center_longitude, self.center_latitude)))
        try:
            image = self.static_map.render(
                zoom=self.zoom_level,
                center=(self.center_longitude, self.center_latitude)
            )
        except RuntimeError:
            rospy.logerr('Failed to download map images')
            self.msg_map_meta_data = MapMetaData()
            self.msg_occupancy_grid = OccupancyGrid()
            return

        self.msg_map_meta_data = MapMetaData()
        self.msg_map_meta_data.map_load_time = rospy.Time.now()
        self.msg_map_meta_data.resolution = map_resolution
        self.msg_map_meta_data.width = self.map_size
        self.msg_map_meta_data.height = self.map_size
        self.msg_map_meta_data.origin.position.x = -self.map_size * map_resolution / 2
        self.msg_map_meta_data.origin.position.y = self.map_size * map_resolution / 2
        self.msg_map_meta_data.origin.position.z = 0
        self.msg_map_meta_data.origin.orientation.x = 1.0
        self.msg_map_meta_data.origin.orientation.y = 0.0
        self.msg_map_meta_data.origin.orientation.z = 0.0
        self.msg_map_meta_data.origin.orientation.w = 0.0

        self.msg_occupancy_grid = OccupancyGrid()
        self.msg_occupancy_grid.header.frame_id = self.static_map_frame
        self.msg_occupancy_grid.header.stamp = rospy.Time.now()
        self.msg_occupancy_grid.info = self.msg_map_meta_data

        image_array = np.array(image.convert('L')) / 2
        self.msg_occupancy_grid.data = image_array.flatten().tolist()

    def publish_map(self):
        self.pub_map_meta_data.publish(self.msg_map_meta_data)
        self.pub_occupancy_grid.publish(self.msg_occupancy_grid)

    def publish_tf(self):
        self.tf_br.sendTransform(self.transform_initial_to_static)


if __name__ == '__main__':
    rospy.init_node('static_map_publisher')
    node = StaticMapPublisher()
    node.spin()
