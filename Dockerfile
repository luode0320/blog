# 使用一个基础的Node.js镜像
FROM node:18-alpine

COPY . /app

WORKDIR /app
RUN npm install

# 在每次启动时从 GitHub 更新文件
CMD ["sh", "-c", "node index.js"]
