#!/usr/bin/env bash

set -x
ssh grxuser@hrp2017c -t "bash -ci \"export DISPLAY=:0;/home/grxuser/drc/9.servo_off.sh \""
