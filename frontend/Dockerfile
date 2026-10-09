# Stage 1: build the static bundle
FROM node:20-slim AS build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
# VITE_API_URL is baked in at build time — override with --build-arg if the
# backend isn't reachable at the default http://localhost:8010
ARG VITE_API_URL=http://localhost:8010
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Stage 2: serve the built files with nginx — no node/npm in the final image
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
