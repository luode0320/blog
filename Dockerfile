# 使用一个基础的Node.js镜像
FROM node:18-alpine

# 安装 Git
RUN apk update && apk add --no-cache git

# 设置 Git 配置
RUN git config --global user.email "1846555387@qq.com"
RUN git config --global user.name "luode"

# 克隆代码库
RUN git clone https://github.com/Rod0320/blog.git /app

# 切换到代码库目录
WORKDIR /app

# 安装依赖
RUN npm install
RUN npm install express

# 在每次启动时从 GitHub 更新文件
CMD ["sh", "-c", "git pull origin main && node index.js"]
