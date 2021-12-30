#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import rospy
import tf2_ros
from geometry_msgs.msg import TransformStamped
import math

import jsk_maps


class StaticLonLatPublisher:

    def __init__(self):

        self.from_frame_id = rospy.get_param('~from_frame_id')
        self.from_latitude = rospy.get_param('~from_latitude')
        self.from_longitude = rospy.get_param('~from_longitude')

        self.to_frame_id = rospy.get_param('~to_frame_id')
        self.to_latitude = rospy.get_param('~to_latitude')
        self.to_longitude = rospy.get_param('~to_longitude')

        self.diff_angle_from_to = rospy.get_param(
            '~diff_angle_from_to')  # radians

        self.tf_br = tf2_ros.StaticTransformBroadcaster()

        diff_x, diff_y = jsk_maps.calc_transform_from_lon_lat(
            self.from_longitude,
            self.from_latitude,
            self.to_longitude,
            self.to_latitude)

        transform = TransformStamped()
        transform.header.frame_id = self.from_frame_id
        transform.child_frame_id = self.to_frame_id
        transform.transform.translation.x = diff_x
        transform.transform.translation.y = diff_y
        transform.transform.rotation.z = math.sin(self.diff_angle_from_to/2.0)
        transform.transform.rotation.w = math.cos(self.diff_angle_from_to/2.0)

        self.tf_br.sendTransform(transform)


if __name__ == '__main__':
    rospy.init_node('static_lon_lat_publisher', anonymous=True)
    node = StaticLonLatPublisher()
    rospy.spin()
