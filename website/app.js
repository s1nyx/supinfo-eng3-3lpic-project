const express = require('express');
const mysql = require('mysql2');
const submitRoute = require('./routes/submitRoute');
const authRoutes = require('./routes/authRoutes');
const sequelize = require("./database");
const session = require('express-session');
const passport = require('./config/passport-config');

const app = express();
const port = 9000;

// Middleware
app.use(express.static('public'));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Session middleware
app.use(session({
    secret: 'secret', // Use a long, random string in production
    resave: true,
    saveUninitialized: true
}));

// Passport middleware
app.use(passport.initialize());
app.use(passport.session());

// Routes
app.use(authRoutes);
app.use(submitRoute);

// Default route which redirects to the submit page
app.get('/', (req, res) => {
    res.redirect('/submit');
});

(async () => {
    try {
        await sequelize.sync({}); // Add { force: true } if you want to drop tables and recreate them
        console.log('Connection to the database has been established successfully.');
        // Start your Express server here
    } catch (error) {
        console.error('Unable to connect to the database:', error);
    }
})();

app.listen(port, () => {
    console.log(`L'application écoute sur le port ${port}`);
});
