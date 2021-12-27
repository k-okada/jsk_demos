# jsk_2021_10_semi

[![](http://img.youtube.com/vi/nkQucUiqb24/0.jpg)](http://www.youtube.com/watch?v=nkQucUiqb24 "")

https://github.com/k-okada/jsk_demos/tree/jsk_2021_10_semi/jsk_2021_10_semi

## ロボットモデルの作り方

```bash
sudo apt install python3 python3-pip
python3 -m pip install --user conan
conan config set general.revisions_enabled=1
conan profile new default --detect > /dev/null
conan profile update settings.compiler.libcxx=libstdc++11 default
```

ターミナルを立ち上げ直す.

```bash
source /opt/ros/melodic/setup.bash
mkdir -p ~/semi_ws/src
cd ~/semi_ws/src
wstool init
wstool merge https://raw.githubusercontent.com/k-okada/jsk_demos/jsk_2021_10_semi/jsk_2021_10_semi/semi.rosinstall
wstool update
rosdep update
rosdep install --from-paths . --ignore-src -y -r
cd ..
git clone https://github.com/k-okada/jsk_demos -b jsk_2021_10_semi
git clone https://github.com/sktometometo/jsk_robot -b develop/spot
cd src
ln -sf ../jsk_demos/jsk_2021_10_semi/ .
ln -sf ../jsk_robot/jsk_spotkinova_robot/ .
ln -sf ../jsk_robot/jsk_spot_robot/ .
ln -sf ../jsk_robot/jsk_kinova_robot/jsk_kinova_description/ .
cd ..
catkin build -vi
source devel/setup.bash
```

とすると以下のプログラムでロボットのモデルを作ることが出来ます．インタプリタは `roseus` として実行してください．

```
(load "package://peppereus/pepper.l")
(setq *pepper* (pepper))
(objects (list *pepper*))

(load "package://naoeus/nao.l")
(setq *nao* (NaoH25V50))
(objects (list *nao*))

(load "package://baxtereus/baxter.l")
(setq *baxter* (baxter))
(objects (list *baxter*))

(load "package://fetcheus/fetch.l")
(setq *fetch* (fetch))
(objects (list *fetch*))

(load "package://spotkinovaeus/spotkinova.l")
(setq *spotkinova* (spotkinova))
(objects (list *spotkinova*))

(load "package://pr2eus/pr2.l")
(setq *pr2* (pr2))
(objects (list *pr2*))
```

## 実機の動かし方
- ネットワークに接続する  
- rossetmaster (ロボット)
- rossetip
- rostopic listで表示されるか確認する
- roseusで実機に送る

## pepper 情報
## nao 情報
## baxter 情報
## fetch 情報
## spotkinova　情報
spotにkinovaというマニピュレータがついたロボットのこと  
  
**注意**  
kinovaはロボットが動いた時に危ないと判断するのでデフォルトではrest-poseにすること  
  
**よく使うコマンド**  
はじめに  
- load "package://spotkinovaeus/spotkinova-interface.l"
- spotkinova-init  
  
便利関数
- :kinova-rest-pose
    - kinovaをrest-poseにする、基本的にはこの姿勢にすること  
- :start-grasp :stop-grasp
    - kinovaのエンドエフェクタを掴む、離す

## pr2 情報

```
rossetmaster pr1040

rossetip

```
192.のネットワークだと繋がらないので注意。113.11.のやつを使う

## rosbag 情報
**rosbagとは**  
実機などを使っているときに、Topicを録画できる。例えば画像のTopicを録画しておけば、家でも画像処理のコードが書ける。

**録画のしかた(pr2)**  
- rossetmaster (ロボット)
- launchファイルは~/semi_ws/src/jsk_robot/jsk_pr2_robot/jsk_pr2_startup/jsk_pr2_lifelogにある
- roslaunch jsk_pr2_startup rosbag_record.launch rosbag:=fuga
- これで~/.ros/にfuga.bagが作られている。Ctrl+Cで録画終了

**再生のしかた**  
ここから先は、rossetmasterしていないターミナルで行うこと。
- roslaunch jsk_pr2_startup rosbag_play.launch rosbag:=/home/mech-user/.ros/fuga.bag  gui:=true
- これでfuga.bagが再生される。gui:=trueとするとrvizも立ち上がる。

便利情報
- rostopic list | grep image でimageのトピックを探せる
- rosrun image_view image_view image:=/kinect_head/rgb/image_rect_color で画像が見れる

## Coral TPU 情報
**Coral TPUとは?**  
PCに挿すと、ディープラーニングのような重い画像処理をしてくれる。
k-okadaに言うと貸してくれる。

**使い方**  
下のURLの通りにすればできる
- 注意1 必ず新しくワークスペースを作ること（Pythonのバージョンが異なるため）。一言一句すべて下のURLに書いてある通りにやるといい
- 注意2 下のURLの、Melodicと書いてある部分をやること。

https://github.com/knorth55/coral_usb_ros

**便利情報**
pr2の中ではすでにcoralがあるので次のようにしてノード名を変えるとよく、またcompressedにすると処理が早くなってよい
```
roslaunch --screen coral_usb edgetpu_human_pose_estimator.launch INPUT_IMAGE:=/kinect_head/rgb/image_color nodename:=my_human_detector IMAGE_TRANSPORT:=compressed
rosrun image_view image_view image:=/my_human_detector/output/image
```
次のようにするとlaunchファイルを見なくても引数がわかる
```
roslaunch --screen coral_usb edgetpu_human_pose_estimator.launch --ros-arg
```