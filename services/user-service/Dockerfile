FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

RUN apk add --no-cache curl

COPY . .

EXPOSE 4001

CMD ["node","server.js"]
