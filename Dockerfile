# FIXME: switch back to FROM:node:10.16.0 once it's on buster for gdal 2.3
FROM ubuntu:18.10


# RUN printf "deb http://archive.debian.org/debian/ stretch main\ndeb-src http://archive.debian.org/debian/ stretch main" > /etc/apt/sources.list
RUN apt-get update && apt-get install -y gdal-bin git curl python libcairo2-dev libjpeg-dev libpango1.0-dev libgif-dev librsvg2-dev build-essential

RUN curl --silent --location https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install --yes nodejs

# Cache dependencies
COPY npm-shrinkwrap.json /tmp/npm-shrinkwrap.json
COPY package.json /tmp/package.json
RUN mkdir -p /opt/app && \
    cd /opt/app && \
    cp /tmp/npm-shrinkwrap.json . && \
    cp /tmp/package.json . && \
    npm install --production --unsafe-perm --loglevel warn

COPY . /opt/app

WORKDIR /opt/app

CMD ["npm", "start"]
