const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Submission = sequelize.define('Submission', {
    userId: DataTypes.INTEGER,
    courseId: DataTypes.INTEGER,
    exerciseNumber: DataTypes.INTEGER,
    language: DataTypes.STRING,
    status: {
        type: DataTypes.ENUM,
        values: ['awaiting correction', 'scored'],
        defaultValue: 'awaiting correction'
    },
    score: DataTypes.INTEGER,
    createdAt: DataTypes.DATE,
    updatedAt: DataTypes.DATE
});

module.exports = Submission;
