#!/usr/bin/env roseus

(load "package://jsk_maps/tools/publish_spot_utils.l")

(defun load-scene ()
  (load (format nil "package://jsk_maps/src/~A-scene.l" *scene-name*))
  (setq *scene* (funcall (intern (string-upcase (format nil "make-~A-scene" *scene-name*))))))

(defun publish-spot ()
  (let* ((stamp (ros::time-now))
         (header (instance std_msgs::header :init :stamp stamp :frame_id (format nil "/~A" *scene-name*)))
         spots)

    ;; transform spots
    (dolist (spot (send *scene* :spots))
      (when (substringp (concatenate string *current-map-id* "/") (send spot :name))
        (push (cons (send spot :name)
                    (send spot :worldcoords))
              spots)))

    ;; publish spots
    (if *use-pictogram-p*
        (publish-pictogram-array spots header)
        (publish-pin-marker-array spots header))))

(defun map-selected-cb (msg)
  (setq *current-map-id*
        (string-right-trim "_" (string-right-trim "tf"   ;; remove '_tf'
                                                  (send msg :data))))
  (ros::ros-info "[jsk_maps/publish_spot.l] map id \"~A\" is selected." *current-map-id*))

(defun main ()
  (ros::roseus "publish_spot")

  ;; load params
  (setq *scene-name* (ros::get-param "~scene" "eng2"))
  (setq *use-pictogram-p* (ros::get-param "~use_pictogram" nil))

  (unless *tf-listener*
    (setq *tf-listener* (instance ros::transform-listener :init)))

  (load-scene)

  (ros::subscribe "/map_tf_mux/selected" std_msgs::String #'map-selected-cb)

  ;; wait for map namespace
  (ros::rate 1)
  (ros::spin-once)
  (ros::sleep)
  (while (null *current-map-id*)
    (ros::ros-warn "[jsk_maps/publish_spot.l] map id is empty! please publish /map_tf_mux/selected.")
    (ros::spin-once)
    (ros::sleep))

  (ros::rate 0.1)
  (while (ros::ok)
    (ros::spin-once)
    (publish-spot)
    (ros::sleep)))

(main)
