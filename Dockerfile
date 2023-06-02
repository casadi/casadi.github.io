FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt install sudo -y

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN sudo apt update && sudo apt install nodejs npm -y

RUN npm install -g sass gulp gulp-sass gulp-autoprefixer gulp-rename gulp-minifier

# RUN sudo apt update && sudo apt install hugo -y

RUN sudo apt update && sudo apt install curl -y
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v0.112.7/hugo_extended_0.112.7_linux-amd64.deb -o hugo.deb
RUN sudo apt install ./hugo.deb -y

WORKDIR /local

EXPOSE 1313/tcp
