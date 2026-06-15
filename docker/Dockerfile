FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

RUN apt-get update -y && apt-get install -y python3.10 python3.10-distutils curl
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3.10 get-pip.py
RUN pip3 install fschat --timeout 3600
RUN pip3 install fschat[webui] --timeout 3600
RUN pip3 install fschat[model_worker] --timeout 3600