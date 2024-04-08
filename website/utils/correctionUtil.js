const { exec } = require('child_process');
const path = require('path');
const Queue = require('./queue');
const Submission = require('../models/submission');

const supportedLangugesFormat = {
    'c': 'c',
    'python': 'py'
};

const executionQueue = new Queue();


/**
 * Executes the submitted code and compares it to the expected output.
 * @param {number} submissionId ID of the submission.
 * @param {string} submittedFilePath Path to the submitted code file.
 * @param {number} courseId ID of the course (used to determine inputs/expected outputs).
 * @param {number} exerciseNumber The exercise number.
 * @param {string} language The programming language of the submission.
 * @returns {Promise<number>} The success percentage.
 */
function executeAndCompare(submissionId, submittedFilePath, courseId, exerciseNumber, language) {
    if (!supportedLangugesFormat[language]) {
        throw new Error('Unsupported language');
    }

    const fileFormat = supportedLangugesFormat[language];

    // Construct the path to the Bash script
    const scriptPath = path.join(__dirname, 'corrector.sh');
    const uploadedFilesPath = path.join(__dirname, '..');

    // Wrap the execution logic in a function that returns a Promise
    const task = () => new Promise((resolve, reject) => {
        exec(`bash "${scriptPath}" "${uploadedFilesPath}/${submittedFilePath}" "${courseId}" "${exerciseNumber}" "${fileFormat}"`, async (error, stdout, stderr) => {
            if (error) {
                console.error(`Execution error: ${error}`);
                return reject(error);
            }
            if (stderr) {
                console.error(`Script error: ${stderr}`);
                return reject(new Error(stderr));
            }

            console.log(`Success percentage: ${stdout}`);

            const result = parseInt(stdout.trim(), 10);

            await Submission.update({
                score: result,
                status: 'scored',
                updatedAt: new Date()
            }, {
                where: {id: submissionId}
            });


            resolve(result);
        });
    });

    // Add the task to the queue instead of running it directly
    executionQueue.enqueue(task);
}

module.exports = { executeAndCompare };
