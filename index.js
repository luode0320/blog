const path = require('path');
const fs = require('fs');
const express = require('express');
const app = express();

app.use(express.static(path.join(__dirname, '/')));

const port = 4100;
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
