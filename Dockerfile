ARG IMAGE_NAME=nvidia/cuda
FROM ${IMAGE_NAME}:10.1-devel-ubuntu18.04 AS base
LABEL maintainer="Yutao Tang <kissingers800@gmail.com>"

ENV CUDNN_VERSION 7.6.0.64
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda10.1 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda10.1 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*


ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs


FROM base AS openpose-install

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3-dev python3-pip git g++ wget make libprotobuf-dev protobuf-compiler libopencv-dev \
        libgoogle-glog-dev libboost-all-dev libcaffe-cuda-dev libhdf5-dev libatlas-base-dev vim

#replace cmake as old version has CUDA variable bugs
RUN wget https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.tar.gz && \
tar xzf cmake-3.16.0-Linux-x86_64.tar.gz -C /opt && \
rm cmake-3.16.0-Linux-x86_64.tar.gz
ENV PATH="/opt/cmake-3.16.0-Linux-x86_64/bin:${PATH}"

# install opencv 3.4.0
ENV OPENCV_ROOT /root/Downloads/
WORKDIR $OPENCV_ROOT
RUN cd $OPENCV_ROOT && test -d opencv_contrib && echo "opencv_contrib exist" || \
        git clone https://github.com/opencv/opencv_contrib.git && \
        cd opencv_contrib && git checkout tags/3.4.0 && \
        cd $OPENCV_ROOT && test -d opencv && echo "opencv exist" || \
        git clone https://github.com/opencv/opencv.git && \
        cd opencv && git checkout tags/3.4.0 && mkdir -p build && cd build && \
        cmake -D CMAKE_BUILD_TYPE=Release \
        cmake -D WITH_TBB=ON -D WITH_OPENMP=ON -D WITH_IPP=ON -D BUILD_PNG=ON \
        -D OPENCV_EXTRA_MODULES_PATH=$OPENCV_ROOT/opencv_contrib/modules \
        -D CMAKE_BUILD_TYPE=RELEASE -D BUILD_EXAMPLES=OFF -D WITH_QT=OFF \
        -D WITH_CUDA=OFF -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF \
        -D WITH_CSTRIPES=ON -D WITH_OPENCL=ON -D BUILD_opencv_cnn_3dobj=OFF \
        -D CMAKE_INSTALL_PREFIX=/usr/local/ -D BUILD_TESTS=OFF -D WITH_NVCUVID=ON \
        -D BUILD_opencv_dnn_modern=OFF -D WITH_GTK=ON -D WITH_GTK_2_X=ON .. && \
        make -j$(nproc) && make install && ldconfig && cd $OPENCV_ROOT && rm -Rf opencv_contrib && rm -Rf opencv


#for python api
RUN pip3 install numpy opencv-python==3.4.5.20


FROM openpose-install AS openpose-env
# make sure the right GPU is used (in case of multi-GPU setups)
ENV CUDA_VISIBLE_DEVICES=0

# get openpose
WORKDIR /openpose
RUN git clone https://github.com/yytang2012/openpose.git .

#build it
WORKDIR /openpose/build
RUN cmake -DBUILD_PYTHON=ON .. && make -j `nproc`
WORKDIR /openpose

# set python environment
ENV PYTHONPATH=/openpose/build/python
RUN echo "export PYTHONPATH=/openpose/build/python${PYTHONPATH:+:${PYTHONPATH}}" >> ~/.bashrc

FROM openpose-env AS openpose-python
WORKDIR /app
# Run Python app
CMD ["python3", "body_from_images.py"]

