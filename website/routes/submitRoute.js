const express = require('express');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });
const router = express.Router();
const path = require('path');

const basePath = path.join(__dirname, '..', 'public');


// Route to serve the submit page
router.get('/submit', (req, res) => {
    // Ensure the user is authenticated before allowing access to the submit page
    //if (req.isAuthenticated()) {
        res.sendFile(path.join(basePath, 'submit.html'));
    /*} else {
        res.redirect('/login');
    }*/
});

router.post('/', upload.single('codeFile'), (req, res) => {
    // Handle file submission
    // For example: Compare the uploaded file's output with expected output
    res.send('File uploaded successfully.');
});

module.exports = router;
