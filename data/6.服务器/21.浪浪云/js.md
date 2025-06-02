# 删除端口

```js
async function deleteNat(ids) {
    const url = 'https://www.langlangy.cn/server/nat/4325';
    const data = new URLSearchParams();
    data.append('ids', ids);
    data.append('batch', 'del');

    // 自动获取当前页面的 Cookie
    const cookies = document.cookie;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json, text/javascript, */*; q=0.01',
                'X-Requested-With': 'XMLHttpRequest',
                'Origin': 'https://www.langlangy.cn',
                'Referer': 'https://www.langlangy.cn/server/lxc',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
                'Cookie': cookies // 动态获取 Cookie
            },
            body: data.toString()
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        console.log('删除成功:', result);
        return result;
    } catch (error) {
        console.error('删除失败:', error);
        throw error;
    }
}

async function deleteNatRange(startId, endId) {
    for (let id = startId; id <= endId; id++) {
        try {
            console.log(`正在删除 ID: ${id}...`);
            const result = await deleteNat(id);
            console.log(`删除成功 (ID=${id}):`, result);
        } catch (error) {
            console.error(`删除失败 (ID=${id}):`, error);
        }
        // 可选的延迟（避免请求过快被封）
        await new Promise(resolve => setTimeout(resolve, 100));
    }
}

// 调用示例：删除 500-600
deleteNatRange(621, 621)
    .then(() => console.log("批量删除完成！"))
    .catch(error => console.error("批量删除出错:", error));
```

# 更新配置

```js
async function deleteNat(ids) {
    const url = 'https://www.langlangy.cn/server/detail/4322/upgrade';
    const data = new URLSearchParams();
    data.append('spec_id', "677");
    data.append('net', "10");
    data.append('def', "100");
    data.append('action', "1");
    data.append('amount', "1");
    data.append('type', "server");
    data.append('scene', "server_upgrade"); 
    data.append('type', "amount");

    // 自动获取当前页面的 Cookie
    const cookies = document.cookie;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json, text/javascript, */*; q=0.01',
                'X-Requested-With': 'XMLHttpRequest',
                'Origin': 'https://www.langlangy.cn',
                'Referer': 'https://www.langlangy.cn/server/lxc',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
                'Cookie': cookies // 动态获取 Cookie
            },
            body: data.toString()
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        console.log('删除成功:', result);
        return result;
    } catch (error) {
        console.error('删除失败:', error);
        throw error;
    }
}

// 使用示例
deleteNat(601)
    .then(data => console.log('操作结果:', data))
    .catch(error => console.error('操作失败:', error));
```

```js
async function deleteNat(ids) {
    const url = 'https://www.langlangy.cn/server/detail/4224/upgrade';
    const data = new URLSearchParams();
    data.append('spec_id', "633");
    data.append('net', "20");
    data.append('def', "49");
    data.append('action', "1");
    data.append('type', "server");
    data.append('scene', "server_upgrade");
    data.append('type', "amount");

    // 自动获取当前页面的 Cookie
    const cookies = document.cookie;

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json, text/javascript, */*; q=0.01',
                'X-Requested-With': 'XMLHttpRequest',
                'Origin': 'https://www.langlangy.cn',
                'Referer': 'https://www.langlangy.cn/server/lxc',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
                'Cookie': cookies // 动态获取 Cookie
            },
            body: data.toString()
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        console.log('删除成功:', result);
        return result;
    } catch (error) {
        console.error('删除失败:', error);
        throw error;
    }
}

// 使用示例
deleteNat(601)
    .then(data => console.log('操作结果:', data))
    .catch(error => console.error('操作失败:', error));
```



