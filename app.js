const express = require('express');
const app = express();
const packageJson = require('./package.json');

// Root endpoint
app.get('/', (req, res) => {
  res.send('Hello from Node API');
});

// API version endpoint
app.get('/api/version', (req, res) => {
  res.json({ version: packageJson.version });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
