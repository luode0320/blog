const fs = require('fs');
const path = require('path');
const express = require('express');
const app = express();
function generateMarkdown(dir, indent = '') {
    const files = fs.readdirSync(dir);
    let markdown = '';
    // 自定义要排除的目录列表
    const excludeDirs = [
        '.github','.git','.idea','node_modules','Static','node_modules', 'tmp','.gitignore','_sidebar.md','图片保存',
        'Dockerfile','favicon.ico','HOME.md','index.html','index.js','package.json','package-lock.json','README.md',
    ];

    files.forEach(file => {
        if (excludeDirs.includes(file)) {
            return
        }
        const filePath = path.join(dir, file);
        const stats = fs.statSync(filePath);

        if (stats.isDirectory()) {
            markdown += `${indent}* **${file}**\n`;
            markdown += generateMarkdown(filePath, `${indent}  `);
        } else {
            const relativePath = path.relative(__dirname, filePath);
            markdown += `${indent}* [${file}](${relativePath})\n`;
        }
    });

    return markdown;
}

const projectPath = path.dirname(__filename);
const markdown = generateMarkdown(projectPath);
fs.writeFileSync('_sidebar.md', markdown);

app.use(express.static(path.join(__dirname, '/')));
const port = 4000;
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
