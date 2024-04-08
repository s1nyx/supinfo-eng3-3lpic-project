const express = require('express');
const path = require('path');
const bcrypt = require('bcryptjs');
const User = require('../models/user');
const passport = require("../config/passport-config");

const router = express.Router();
const basePath = path.join(__dirname, '..', 'public');


// Route to serve the login page
router.get('/login', (req, res) => {
    res.sendFile(path.join(basePath, 'login.html'));
});

// Route to serve the registration page
router.get('/register', (req, res) => {
    res.sendFile(path.join(basePath, 'register.html'));
});

// Registration route
router.post('/register', async (req, res) => {
    const { email, password } = req.body;
    try {
        // Check if user already exists
        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return res.status(400).send('User already exists.');
        }

        // Hash password and create user
        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = await User.create({
            email,
            password: hashedPassword,
        });

        res.redirect('/login');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error registering the user.');
    }
});

// Login route
router.post('/login', passport.authenticate('local', {
    successRedirect: '/submit', // Redirect to a different URL on success
    failureRedirect: '/login', // Redirect back to login on failure
}));

module.exports = router;
