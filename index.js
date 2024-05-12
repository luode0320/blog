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

    const filteredFiles = files.filter(file => !excludeDirs.includes(file));
    filteredFiles.sort((a, b) => {
        const numA = parseInt(a.substring(0, 2)) || Infinity; // 非数字的元素排在数字元素的后面
        const numB = parseInt(b.substring(0, 2)) || Infinity; // 非数字的元素排在数字元素的后面
        if (isNaN(numA) && isNaN(numB)) {
            return a.localeCompare(b); // 都不是数字时，按照字符串排序
        } else {
            return numA - numB; // 是数字时，按照数字大小排序
        }
    });

    filteredFiles.forEach(file => {
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
