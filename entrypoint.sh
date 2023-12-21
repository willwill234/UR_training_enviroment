#!/usr/bin/env bash
#!/usr/bin/env bash

set -e

source /opt/ros/$ROS_DISTRO/setup.bash
source /robogym_ws_envir/devel/setup.bash
echo "robo-gym commit SHA: $GIT_COMMIT"

exec "$@"

