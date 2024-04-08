const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('your_database_name', 'replication_user', 'strong_replication_password', {
    host: 'db1.localdomain.lan',
    dialect: 'mysql'
});

module.exports = sequelize;