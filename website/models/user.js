const { DataTypes } = require('sequelize');
const sequelize = require('../database'); // Adjust the path as necessary

const User = sequelize.define('User', {
  // Define attributes
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  }
}, {
  // Model options
  tableName: 'users', // If your table name is not the pluralized version of the model name
  timestamps: false // If you don't want Sequelize to automatically add `createdAt` and `updatedAt` columns
});

module.exports = User;