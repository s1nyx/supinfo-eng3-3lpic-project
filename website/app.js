const express = require('express');
const mysql = require('mysql2');

const app = express();
const port = 3000;

const pool = mysql.createPool({
    connectionLimit : 10,
    host            : 'db1.localdomain.lan',
    user            : 'replication_user',
    password        : 'strong_replication_password',
    database        : 'your_database_name'
});

app.get('/', (req, res) => {
    pool.query('SELECT * FROM votre_table LIMIT 10', (err, rows) => {
        if (err) throw err;
        res.send(rows);
    });
});

app.listen(port, () => {
    console.log(`L'application écoute sur le port ${port}`);
});