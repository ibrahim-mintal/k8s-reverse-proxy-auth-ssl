const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => res.send('Hello from App1 - ' + (process.env.HOSTNAME||'unknown')));
app.get('/devops', (req, res) => res.send('DEVOPS area on App1 - ' + (process.env.HOSTNAME||'unknown')));

app.listen(port, () => console.log('App1 listening on', port));
