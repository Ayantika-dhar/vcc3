const express = require("express");
const osUtils = require("os-utils");
const { spawn, exec } = require("child_process");

const app = express();
const PORT = 5000;

let computeProcess = null;
const GCP_PROJECT = "vcc-ass3";
const GCP_ZONE = "us-central1-a";
const GCP_VM_NAME = "auto-scaled-vm";
const LOCAL_PATH = "~/cpu-monitoring-app";
const GCP_INSTANCE_PATH = "~/cpu-monitoring-app";
let isScaling = false;  // Prevent multiple scaling attempts

app.use(express.json());
app.use(require("cors")());

// Endpoint to get CPU usage
app.get("/cpu-usage", (req, res) => {
    osUtils.cpuUsage((usage) => {
        res.json({ cpuUsage: usage * 100 });
    });
});

// Start CPU-intensive task
app.post("/start-computation", (req, res) => {
    if (!computeProcess) {
        computeProcess = spawn("node", ["compute.js"], { detached: true, stdio: "ignore" });
        computeProcess.unref();
        return res.json({ message: "Computation started" });
    }
    res.json({ message: "Already running" });
});

// Stop CPU-intensive task
app.post("/stop-computation", (req, res) => {
    if (computeProcess) {
        process.kill(-computeProcess.pid);
        computeProcess = null;
        return res.json({ message: "Computation stopped" });
    }
    res.json({ message: "No computation running" });
});

// Function to create GCP VM if it doesn't exist
function createGCPVM(callback) {
    console.log("Checking if GCP VM exists...");

    exec(`gcloud compute instances list --filter="name=${GCP_VM_NAME}" --format="value(name)"`, (error, stdout, stderr) => {
        if (!stdout.trim()) {
            console.log("No existing VM found. Creating new VM...");
            exec(`gcloud compute instances create ${GCP_VM_NAME} --zone=${GCP_ZONE} --machine-type=e2-medium`, 
                (error, stdout, stderr) => {
                    if (error) {
                        console.error(`Error creating VM: ${error.message}`);
                        isScaling = false; // Reset flag on failure
                        return;
                    }
                    console.log(`VM Created: ${stdout}`);
                    transferFilesToGCP(callback);
                }
            );
        } else {
            console.log("VM already exists. Proceeding to file transfer...");
            transferFilesToGCP(callback);
        }
    });
}

// Function to transfer files to GCP VM via SCP
function transferFilesToGCP(callback) {
    console.log("Transferring files using SCP...");

    exec(`gcloud compute scp -r . ${GCP_VM_NAME}:~/cpu-monitoring-app --zone=${GCP_ZONE}`, 
        (error, stdout, stderr) => {
            if (error) {
                console.error(`SCP Error: ${error.message}`);
                isScaling = false; // Reset flag on failure
                return;
            }
            console.log("Files transferred successfully!");
            isScaling = false; // Reset flag after completion
            if (callback) callback();
        }
    );
}

// Monitor CPU usage and trigger auto-scaling if usage exceeds 75%
function monitorCPUUsage() {
    if (isScaling) return; // Prevent duplicate scaling actions

    osUtils.cpuUsage((usage) => {
        const cpuPercent = usage * 100;
        console.log(`CPU Usage: ${cpuPercent.toFixed(2)}%`);

        if (cpuPercent > 75 && !isScaling) {
            isScaling = true;
            console.log("CPU usage exceeded 75%! Initiating auto-scaling...");

            createGCPVM(() => {
                console.log("Scaling process complete. Resuming monitoring...");
            });
        }
    });
}

// Run CPU monitoring every 5 seconds
setInterval(monitorCPUUsage, 5000);

// Endpoint to check GCP status
app.get("/gcp-status", (req, res) => {
    res.json({ message: "Monitoring GCP VM status..." });
});

// Start server
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
