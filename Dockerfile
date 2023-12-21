FROM osrf/ros:noetic-desktop-full

ARG GIT_COMMIT=unknown
LABEL git-commit=$GIT_COMMIT
ARG CI_JOB_TOKEN

ENV DEBIAN_FRONTEND noninteractive
ENV ROS_DISTRO=noetic
ENV ROBOGYM_WS_ENVIR=/robogym_ws_envir

# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" \
    && useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && apt-get install -y curl && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add - && \
    apt-get update && apt-get install -y \
    apt-utils build-essential psmisc vim-gtk \
    git swig sudo libcppunit-dev \
    python3-catkin-tools python3-rosdep python3-pip \
    python3-rospkg python3-future python3-osrf-pycommon

RUN source /opt/ros/$ROS_DISTRO/setup.bash &&\
    apt-get -y update && apt-get install -y unzip libglu1-mesa-dev libgl1-mesa-dev libosmesa6-dev xvfb patchelf ffmpeg

RUN pip install pytest pytest-rerunfailures 


ARG CACHEBUST=1

RUN source /opt/ros/$ROS_DISTRO/setup.bash &&\
    mkdir -p $ROBOGYM_WS_ENVIR/robot_enviroment &&\
    cd $ROBOGYM_WS_ENVIR/robot_enviroment &&\
    apt-get update && \
    git clone https://github.com/jr-robotics/robo-gym.git &&\
    cd robo-gym &&\
    pip install -e .
    

RUN apt install -y terminator


# 修改COPY命令的路径
#COPY . /home/will/UR_training_20230928/environment_side/robo_gym/

# 修改WORKDIR命令的路径
#WORKDIR /home/will/UR_training_20230928/environment_side/robo_gym/

############################## USER CONFIG ####################################
# * Switch user to ${USER}
USER ${USER}

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && sudo rm -rf /config

RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc



# * Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]