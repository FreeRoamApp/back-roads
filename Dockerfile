FROM node:8.7.0

RUN apt-get update && apt-get install -y libcairo2-dev libjpeg-dev libpango1.0-dev libgif-dev build-essential

# Cache dependencies
COPY npm-shrinkwrap.json /tmp/npm-shrinkwrap.json
COPY package.json /tmp/package.json
COPY dynamic_images/fonts/LuckiestGuy-Regular.ttf /tmp/LuckiestGuy-Regular.ttf
RUN mkdir -p /opt/app && \
    cd /opt/app && \
    cp /tmp/npm-shrinkwrap.json . && \
    cp /tmp/package.json . && \
    mkdir ~/.fonts && \
    cp /tmp/LuckiestGuy-Regular.ttf ~/.fonts && \
    fc-cache -f -v ~/.fonts && \
    npm install --production --unsafe-perm --loglevel warn

COPY . /opt/app

WORKDIR /opt/app

CMD ["npm", "start"]
