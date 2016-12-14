;;人の顔の方をを向く。

#!/usr/bin/env roseus

(load "package://fetcheus/fetch-interface.l")
(fetch-init)
(print "done face-init")
(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "opencv_apps")
(ros::load-ros-manifest "jsk_pcl_ros")
(ros::wait-for-service "pointcloud_screenpoint/screen_to_point")
(ros::roseus "face")

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
      (setq theta-x (atan (/ (send res :point :x) (send res :point :z))))
      (setq theta-y (atan (/ (send res :point :y) (send res :point :z))))
      (setq neck-y (send *fetch* :head :neck-y :joint-angle))
      (setq neck-p (send *fetch* :head :neck-p :joint-angle))
      (send *fetch* :head :neck-y :joint-angle (- neck-y (* 0.5 (rad2deg theta-x)))) ;;joint-angleの引数が正の時左を向く（引数はdeg）
      ;;カメラのx軸正方向とneck-yの正方向が逆であることに注意。
      (send *fetch* :head :neck-p :joint-angle (+ neck-p (* 0.5 (rad2deg theta-y))) :debug-view t) ;;joint-angleの引数が正の時下を向く（引数はdeg）
      ;;カメラのy軸正方向とneck-pの正方向は同じ。
      (send *ri* :angle-vector-raw (send *fetch* :angle-vector) 1000 :head-controller)
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
