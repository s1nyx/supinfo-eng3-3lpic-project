const LocalStrategy = require('passport-local').Strategy;
const bcrypt = require('bcryptjs');
const passport = require('passport');
const User = require('../models/User'); // Adjust the path as necessary

passport.use(new LocalStrategy({ usernameField: 'email' }, async (email, password, done) => {
    // Match user
    try {
        const user = await User.findOne({ where: { email } });
        if (!user) {
            return done(null, false, { message: 'No user found with that email' });
        }

        // Match password
        const match = await bcrypt.compare(password, user.password);
        if (match) {
            return done(null, user);
        } else {
            return done(null, false, { message: 'Password incorrect' });
        }
    } catch (error) {
        return done(error);
    }
}));

passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
    try {
        const user = await User.findByPk(id);
        done(null, user);
    } catch (error) {
        done(error);
    }
});

module.exports = passport;
