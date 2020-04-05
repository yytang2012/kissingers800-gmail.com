# openpose-docker
A docker build file for CMU openpose with Python API support

https://hub.docker.com/r/cwaffles/openpose

### Requirements
- Nvidia Docker runtime: https://github.com/NVIDIA/nvidia-docker#quickstart
- CUDA 10.1 or higher on your host, check with `nvidia-smi`

### Example
Build image 

`docker  build .  -t openpose:latest`

Run container

`docker run -it --rm --runtime=nvidia openpose:latest /bin/bash`

`docker run  -v /etc/localtime:/etc/localtime -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY -e QT_X11_NO_MITSHM=1  -it --rm --runtime=nvidia openpose-python /bin/bash `

The Openpose repo is in `/openpose`

# issue
If meet the following error

`xhost local:root`