FROM ubuntu:19.10

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --yes --no-install-recommends \
    tcl \
    tk \
    pandoc \
    make \
    gcc \
    g++ \
    texlive-latex-recommended \
    texlive-fonts-recommended
