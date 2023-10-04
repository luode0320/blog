# 使用一个基础的Node.js镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 将package.json和package-lock.json复制到工作目录
COPY package*.json ./

# 安装依赖
RUN npm install
RUN npm install express

# 将所有文件复制到工作目录
COPY . .

# 在每次启动时从 GitHub 更新文件
CMD ["sh", "-c", "git pull origin main && node index.js"]
