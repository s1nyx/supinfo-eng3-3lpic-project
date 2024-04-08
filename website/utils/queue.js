class Queue {
    constructor() {
        this.tasks = [];
        this.running = false;
    }

    // Add a task to the queue
    enqueue(task) {
        this.tasks.push(task);
        this.run();
    }

    // Run the next task if the queue is not already running
    async run() {
        if (this.running || this.tasks.length === 0) {
            return;
        }
        this.running = true;
        const task = this.tasks.shift();
        try {
            await task();
        } catch (error) {
            console.error(error);
        }
        this.running = false;
        this.run(); // Try to run the next task in the queue
    }
}

module.exports = Queue;
