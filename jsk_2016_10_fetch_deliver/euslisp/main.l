;;"/go_to_room_arrived"がくればgive.lを読み込む

#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "std_msgs")
(ros::roseus "main")
(load "package://fetcheus/fetch-interface.l")
(fetch-init t)

(setq flag 0)

(defun main-cb (msg)
  (if (= flag 0)
      (progn (setq flag 1)
	     (format t "load give.l~%")
	     (load "give.l"))
    )
  )

(ros::subscribe "/go_to_room_arrived" std_msgs::string #'main-cb)

(do-until-key
 (ros::spin-once)
 )
