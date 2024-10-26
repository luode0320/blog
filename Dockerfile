# 注意: 此 Dockerfile 配合GitHub action自动化配置, GitHub action自动化配置文件在 .github/workflows/main.yml
# 如果手动执行此dockerfile, 注意将不必要的文件夹删除, 例如.idea, .github, 依赖等

# 使用一个基础的Node.js镜像
FROM node:18-alpine

# 复制
COPY . /app
COPY data/ /var/data

# 设置主目录为 / app
WORKDIR /app

# 安装依赖
RUN npm install

# 启动
CMD ["sh", "-c", "cp -R /var/data /app && node index.js"]
