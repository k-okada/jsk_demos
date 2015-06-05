#!/usr/bin/env bash

set -x
ssh grxuser@hrp2017c -t "bash -ci \"export DISPLAY=:0;/home/grxuser/drc/2.servo_on.sh\""
