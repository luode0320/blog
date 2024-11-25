/*
 * @Author: luode 1846555387@qq.com
 * @Date: 2024-02-25 18:20:33
 * @LastEditors: luode 1846555387@qq.com
 * @LastEditTime: 2024-11-25 22:37:37
 * @FilePath: \blog\index.js
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE   
 */
const fs = require('fs');
const path = require('path');
const express = require('express');
const app = express();

function generateMarkdown(dir, indent = '') {
    const files = fs.readdirSync(dir);
    let markdown = '';
    // 自定义要排除的目录列表
    const excludeDirs = [
        '.github', '.git', '.idea', 'node_modules', 'Static', 'node_modules', 'tmp', '.gitignore', '_sidebar.md', 'picture',
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
            markdownSub = generateMarkdown(filePath, `${indent}  `);
            if (markdownSub === '' || !markdownSub){
                return;
            }
            markdown += `${indent}* **${file}**\n`;
            markdown = markdown + markdownSub
        } else {
            // 只处理扩展名为 .md的文件, 并忽略包含 "(私密)" 字样的文件
            if (!/\.md$/i.test(file) || /\(私密\)/.test(file)) {
                return;
            }
            // 计算当前文件相对于当前工作目录 (__dirname) 的相对路径。
            const relativePath = path.relative(__dirname, filePath);
            // 计算当前文件相对于当前工作目录 (__dirname) 的相对路径。
            markdown += `${indent}* [${file}](${relativePath})\n`;
        }
    });

    return markdown;
}

const projectPath = path.join(path.dirname(__filename), 'data');
const markdown = generateMarkdown(projectPath);
fs.writeFileSync('_sidebar.md', markdown);

// 新增刷新目录接口
app.post('/refresh-dir', (req, res) => {
    try {
        const markdown = generateMarkdown(projectPath);
        fs.writeFileSync('_sidebar.md', markdown);
        res.status(200).send('刷新目录成功.');
    } catch (error) {
        console.error(error);
        res.status(500).send('刷新目录是失败.');
    }
});

app.use(express.static(path.join(__dirname, '/')));
const port = 4000;
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
