FROM node:lts-alpine

# Install inotify-tools for filesystem watching
RUN apk add --no-cache inotify-tools bash
RUN npm install -g serve

WORKDIR /app

# Copy package files and install dependencies
# (including devDependencies, needed for astro build)
COPY package*.json ./
RUN npm install

# Copy the rest of the project (excluding content, which will be volume-mounted)
COPY . .

# Do an initial build so the container starts in a serving state
RUN npm run build

EXPOSE 4321

VOLUME /app/src/content

ENV HOST=0.0.0.0
ENV PORT=4321

# Copy and run the rebuild script
COPY rebuild.sh /app/rebuild.sh
RUN chmod +x /app/rebuild.sh

CMD ["/app/rebuild.sh"]