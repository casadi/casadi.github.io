FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt install sudo -y

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN sudo apt update && sudo apt install nodejs npm -y

RUN npm install -g sass gulp gulp-sass gulp-autoprefixer gulp-rename gulp-minifier

RUN sudo apt update && sudo apt install hugo -y

WORKDIR /local

EXPOSE 1313/tcp
