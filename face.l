;;watasuはしないが、人のほうを向く機能はつけている。

#!/usr/bin/env roseus

;;実機を動かす場合は、事前に以下の２つのファイルを実行しておく。
;;roslaunch pointcloud_screenpoint.launch　(~/semi_ws内にあるlaunchファイル)
;; /opt/ros/indigo/lib/opencv_apps/face_detection image:=/head_camera/rgb/image_raw __name:=face_detection  _debug_view:=true _use_camera_info:=true _image_transport:=theora (theoraという圧縮された画像を用いて顔認識をする。)



;;semi_wsの中でcatkin sourceしないと、(send msg :methods)の中で、
;;[ERROR] [1478780792.059942841]: Could not find roseus messages for opencv_apps under (/opt/ros/indigo/share/roseus/ros)
;try rosrun roseus generate-all-msg-srv.sh opencv_apps
;[ERROR] [1478780792.060016260]: Could not find nil/manifest.l
;try rosrun roseus generate-all-msg-srv.sh opencv_apps
;;というエラーが出る。なぜ？？
(load "package://fetcheus/fetch-interface.l")
(fetch-init)
(print "done face-init")
(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "opencv_apps")
(ros::load-ros-manifest "jsk_pcl_ros")
(ros::wait-for-service "pointcloud_screenpoint/screen_to_point")
(ros::roseus "face")
;;(setq sys::*gc-hook* #'(lambda (a b) (format t ";; gc ~A ~A~%" a b)))


;(defun hantei (before after)
;  (and (> after (* before 0.8)) (< after (* before 1.2))))
(defmacro hantei (before after)
  `(and (> ,after (* ,before ,0.8)) (< ,after (* ,before ,1.2))))


(setq count 0) ;;何回連続で人が居ると判断されたか
(setq flag t) ;;複数回watasuを呼ぶのを防ぐ。一回watasuが呼ばれたらnilにする。
(setq xtemp 0) ;;直前の顔のx座標
(setq ytemp 0)
(setq wtemp 0)
(setq htemp 0)
;; callback function
;;カメラ画像を用いて顔認識をし、人がいるか判断するプログラムを書く。


(defun find-people (msg)
  ;;msgが存在すれば（目の前に人がいれば）whenの中身を実行する。
  ;;whenを入れないとmsgがなくなった瞬間にエラーが起きてプログラムが終了してしまう。
  (when (and flag (send msg :faces))
    ;;letだと直前に宣言した局所変数を使えない。
    (let* ((f (car (send msg :faces)))
	   (cx (send f :face :x)) (cy (send f :face :y))
	   (w (send f :face :width)) (h (send f :face :height))
	   (depth 0))
      ;;サービスを用いて顔の位置の深度情報を得る。
      (setq req (instance jsk_pcl_ros::TransformScreenpointRequest :init))
      (send req :x cx)
      (send req :y cy)
      (setq res (ros::service-call "pointcloud_screenpoint/screen_to_point" req))
      (setq depth (send res :point :z))
      ;;cx, cy, w, hの単位は全てピクセル。depthのみ単位はメートル。
      (format t "cx:~3d cy:~3d~%w:~3d h:~3d~%count:~3d~%depth:~A" cx cy w h count depth)
      ;;目の前に人が居るか判定、居たらcountに1を加える。
      (if (and (hantei xtemp cx) (hantei ytemp cy) (hantei wtemp w) (hantei htemp h) (and (< 0.8 depth) (< depth 2)))
	  (setq count (+ count 1))
	(setq count 0))
      ;;5回以上連続で目の前に人がいればwatasu呼んでものを渡す。またフラグ変数をnilにする。
      (if (> count 5) 
	  (progn (format t "watasu!") (setq count 0) (setq flag nil))
	nil)
      (setq xtemp cx)
      (setq ytemp cy)
      (setq wtemp w)
      (setq htemp h)
      ))
  ;;msgがなければ（目の前に人がいなければ）unlessの中身を実行する。
  (unless (send msg :faces)
    (setq count 0))
  )
;(ros::subscribe "/face_detection/faces" opencv_apps::FaceArrayStamped #'find-people)


;;人の顔を見つけたらそっちを見る。
(defun look-at (msg)
  (when (send msg :faces)
    (let* ((f (car (send msg :faces)))
	   (cx (send f :face :x)) (cy (send f :face :y))
	   (w (send f :face :width)) (h (send f :face :height))
	   (theta-x 0) (theta-y 0) (neck-y 0) (neck-p 0))
      (setq req (instance jsk_pcl_ros::TransformScreenpointRequest :init))
      (send req :x cx)
      (send req :y cy)
      ;(print (list 'face cx cy))
      (setq res (ros::service-call "pointcloud_screenpoint/screen_to_point" req))
      (send *fetch* :angle-vector (send *ri* :state :potentio-vector))
      ;;thetaはせいぜい-0.5~0.5[rad]くらい
      ;(print (list (send res :point :x) (send res :point :y) (send res :point :z)))
      (setq theta-x (atan (/ (send res :point :x) (send res :point :z))))
      (setq theta-y (atan (/ (send res :point :y) (send res :point :z))))
      (setq neck-y (send *fetch* :head :neck-y :joint-angle))
      (setq neck-p (send *fetch* :head :neck-p :joint-angle))
      (send *fetch* :head :neck-y :joint-angle (- neck-y (* 0.5 (rad2deg theta-x)))) ;;joint-angleの引数が正の時左を向く（引数はdeg）
      ;;カメラのx軸正方向とneck-yの正方向が逆であることに注意。
      (send *fetch* :head :neck-p :joint-angle (+ neck-p (* 0.5 (rad2deg theta-y))) :debug-view t) ;;joint-angleの引数が正の時下を向く（引数はdeg）
      ;;カメラのy軸正方向とneck-pの正方向は同じ。
      ;;(unix:sleep 5)
      ;;
      ;(format t "x:~A y:~A~%" cx cy)
      ;(format t "x:~A y:~A z:~A~%" (send res :point :x) (send res :point :y) (send res :point :z))
      ;(format t "neck-y:~A neck-p:~A~%" (send *fetch* :head :neck-y :joint-angle) (send *fetch* :head :neck-p :joint-angle))
      ;(format t "theta-x[deg]:~A theta-y[deg]:~A~%" (rad2deg theta-x) (rad2deg theta-y))
      (send *ri* :angle-vector (send *fetch* :angle-vector))
      (unix:usleep 500000) ;;0.5秒
      (find-people msg)
      ;;(send *ri* :wait-interpolation)
      ))
    )
(ros::subscribe "/face_detection/faces" opencv_apps::FaceArrayStamped #'look-at)


(do-until-key
 (ros::spin-once)
 ;;(sys::gc)
)
;(ros::spin)
