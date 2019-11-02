jsk_2019_10_semi
================

ロボットモデルの作り方
----------------------
```
source /opt/ros/melodic/setup.bash
mkdir -p semi_ws/src
cd semi_ws/src
wstool init
wstool merge https://gist.githubusercontent.com/k-okada/db02de337e957d482ebb63c7a08a218b/raw/20b19f3ad92a8576510c0e0aa02bcd311b347beb/semi.rosinstall
wstool update
rosdep install --from-paths . --ignore-src -y -r
cd ..
catkin build -vi
source devel/setup.bash
```

とすると以下のプログラムでロボットのモデルを作ることが出来ます．

```
(load "package://peppereus/pepper.l")
(setq *pepepr* (pepper))
(objects (list *pepper*))

(load "package://naoeus/nao.l")
(setq *nao* (NaoH25V50))
(objects (list *nao*))

(load "package://baxtereus/baxter.l")
(setq *pepepr* (baxter))
(objects (list *baxter*))

(load "package://fetcheus/fetch.l")
(setq *pepepr* (fetch))
(objects (list *fetch*))

(load "package://pr2eus/pr2.l")
(setq *pepepr* (pr2))
(objects (list *pr2*))
```

Coral TPU環境のセットアップのしかた
-----------------------------------

Coral TPUのインストール を行う
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

https://github.com/knorth55/coral_usb_ros#install-the-edge-tpu-runtime をみてCoral TPUをインストールする

```
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install libedgetpu1-max
sudo apt-get install python3-edgetpu
```

Tensorflowliteのインストール を行う
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

https://github.com/knorth55/coral_usb_ros#install-just-the-tensorflow-lite-interpreter をみてtensorflowlite interpreterをインストールする
```
sudo apt-get install python3-pip
wget https://dl.google.com/coral/python/tflite_runtime-1.14.0-cp36-cp36m-linux_x86_64.whl
pip3 install tflite_runtime-1.14.0-cp36-cp36m-linux_x86_64.whl
```

ワークスペースをビルドする
^^^^^^^^^^^^^^^^^^^^^^^^^^
https://github.com/knorth55/coral_usb_ros#workspace-build-melodic
をみてワークスペースを作成しコンパイルする

```
source /opt/ros/melodic/setup.bash
mkdir -p ~/coral_ws/src
cd ~/coral_ws/src
git clone https://github.com/knorth55/coral_usb_ros.git
wstool init
wstool merge coral_usb_ros/fc.rosinstall.melodic
wstool update
rosdep install --from-paths . --ignore-src -y -r
cd ~/coral_ws
catkin init
catkin config -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.6m.so
catkin build -vi
````````````````

学習済みモデルをダウンロードする
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

https://github.com/knorth55/coral_usb_ros#model-download をみてモデルをダウンロードする

```
source /opt/ros/melodic/setup.bash
source ~/coral_ws/devel/setup.bash
roscd coral_usb/scripts
python download_models.py
`````

Coral TPUを試してみる
---------------------

USBカメラを立ち上げる
^^^^^^^^^^^^^^^^^^^^^

カメラノードを立ち上げる

```
source /opt/ros/melodic/setup.bash
rosrun usb_cam usb_cam_node
```

Coralの認識ノードを立ち上げる
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

認識ノードを立ち上げる

```
source /opt/ros/melodic/setup.bash
source ~/coral_ws/devel/setup.bash
roslaunch coral_usb edgetpu_object_detector.launch INPUT_IMAGE:=/usb_cam/image_raw
```

結果を見てみる
^^^^^^^^^^^^^

表示ノードを立ち上げる

```
source /opt/ros/melodic/setup.bash
rosrun image_view image_view image:=/edgetpu_object_detector/output/image
```

GitHubの使い方
=============

```
git checkout add_jsk_2019_10_semi   # jsk_2019_10_semi ブランチに移動
git pull origin addjsk_2019_10_semi # リモートのファイルをダウンロード
git checkout -b add_new_feature # ブランチを作って移動する
git add new_file.l              # ファイルをgitの管理下に置く
git commit -m "add feature" new_file.l # ローカルにコミットする
git push <user> add_new_feature # リモートにアップロードする

```