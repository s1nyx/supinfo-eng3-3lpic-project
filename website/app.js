const express = require('express');
const mysql = require('mysql2');

const app = express();
const port = 9000;

const pool = mysql.createPool({
    connectionLimit : 10,
    host            : 'db1.localdomain.lan',
    user            : 'replication_user',
    password        : 'strong_replication_password',
    database        : 'your_database_name'
});

// Route principale qui affiche des données depuis la base de données
app.get('/', (req, res) => {
    pool.query("CREATE TABLE IF NOT EXISTS votre_table (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255))", (err) => {
        if (err) throw err;
    });

    pool.query("INSERT INTO votre_table (name) VALUES ('John Doe'), ('Jane Doe'), ('Alice'), ('Bob')", (err) => {
        if (err) throw err;
    });

    pool.query('SELECT * FROM votre_table LIMIT 10', (err, rows) => {
        if (err) throw err;
        res.send(rows);
    });
});

app.listen(port, () => {
    console.log(`L'application écoute sur le port ${port}`);
});
