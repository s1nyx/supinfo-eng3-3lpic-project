const express = require('express');
const multer = require('multer');
const path = require('path');
const {executeAndCompare} = require("../utils/correctionUtil");
const Submission = require('../models/submission');

const upload = multer({ dest: 'uploads/' });
const router = express.Router();
const basePath = path.join(__dirname, '..', 'public');


// Route to serve the submit page
router.get('/submit', (req, res) => {
    // Ensure the user is authenticated before allowing access to the submit page
    if (req.isAuthenticated()) {
        res.sendFile(path.join(basePath, 'submit.html'));
    } else {
        res.redirect('/login');
    }
});

router.post('/submit', upload.single('codeFile'), async (req, res) => {
    if (!req.isAuthenticated()) {
        return res.status(401).send({ message: "Please log in to submit." });
    }

    const userId = req.user.id;
    const { course, exercise, language } = req.body;
    const filePath = req.file.path;

    try {
        const submission = await Submission.create({
            userId,
            courseId: course,
            exerciseNumber:  exercise,
            language,
            status: 'awaiting correction',
            createdAt: new Date(),
            updatedAt: new Date(),
            score: 0
        });

        await executeAndCompare(submission.id, filePath, course, exercise, language);

        res.json({ status: 'awaiting correction' })
    } catch (error) {
        console.error(error);
        res.status(500).send("Error processing submission");
    }
});

router.get('/submission-status', async (req, res) => {
    if (!req.isAuthenticated()) {
        return res.status(401).send({ message: "Please log in to submit." });
    }

    const userId = req.user.id;
    const { course, exercise } = req.query;

    try {
        const submission = await Submission.findOne({
            where: { userId: userId, courseId: course, exerciseNumber: exercise },
            order: [['createdAt', 'DESC']]
        });

        if (!submission) {
            return res.json({ status: 'Not Submitted' });
        }

        res.json({ status: submission.status, score: submission.score });
    } catch (error) {
        console.error('Failed to fetch submission status:', error);
        res.status(500).json({ status: 'Error fetching status' });
    }
});

module.exports = router;
