science_animal
==============

Gazebo simulation package for Cobotta and Panda

![Gazebo Image](https://i.ibb.co/mtqVHqr/science-animal.png)

# how to build package
```
source /opt/ros/melodic/setup.bash
mkdir -p catkin_ws/src
cd catkin_ws/src
catkin init
git clone --depth 1 -b science_animal https://github.com/k-okada/jsk_demos
wstool merge -y jsk_demos/science_animal/melodic.rosinstall
wstool update
rosdep install --from-paths jsk_demos/science_animal --ignore-src -y -r
cd ..
catkin build science_animal
source devel/setup.bash

```

# how to run

Type
```
roslaunch science_animal gazebo.launch
```
to start simulation


To control cobotta robot, start

```
ROS_NAMESPACE=/robot_1/cobotta/  rosrun rqt_joint_trajectory_controller rqt_joint_trajectory_controller
```

To control panda robot, start
```
rosrun rqt_joint_trajectory_controller rqt_joint_trajectory_controller
```

