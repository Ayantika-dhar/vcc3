#!/bin/bash

echo "🚀 Setting up CPU Monitoring Full-Stack App..."

# Install Node.js and npm
# echo "📦 Installing Node.js and npm..."
# sudo apt update && sudo apt install -y nodejs npm

# Create project directory
mkdir -p ~/cpu-monitoring-app && cd ~/cpu-monitoring-app

# Initialize backend
echo "📂 Setting up Backend..."
npm init -y
npm install express cors os-utils mathjs child_process

# Create backend server.js
echo "📝 Creating server.js..."
cat <<EOF > server.js
const express = require("express");
const osUtils = require("os-utils");
const { exec } = require("child_process");
const math = require("mathjs");

const app = express();
const PORT = 5000;

// GCP Instance Details
const GCP_INSTANCE = "autoscale-vm";
const GCP_ZONE = "us-central1-a";
const GCP_USER = "ubuntu";

function getCPUUsage(callback) {
    osUtils.cpuUsage((usage) => {
        callback(usage * 100);
    });
}

function cpuIntensiveTask() {
    console.log("🚀 Running heavy computation...");
    
    const size = 4000;
    const matrixA = math.random([size, size]);
    const matrixB = math.random([size, size]);
    math.multiply(matrixA, matrixB);

    console.log("✔ Computation completed!");
}

function migrateToGCP() {
    console.log("⚠️ High CPU detected! Migrating workload to GCP...");

    exec(\`gcloud compute instances list --filter='name=\${GCP_INSTANCE}' --format='value(name)'\`, (error, stdout) => {
        if (!stdout.trim()) {
            console.log(\`⚠️ Creating instance: \${GCP_INSTANCE}...\`);
            exec(\`gcloud compute instances create \${GCP_INSTANCE} --zone=\${GCP_ZONE} --machine-type=e2-standard-2 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud\`, 
                (error) => {
                    if (error) {
                        console.error(\`Error creating VM: \${error.message}\`);
                        return;
                    }
                    console.log("✔ VM Created Successfully!");
                    transferFilesToGCP();
                }
            );
        } else {
            console.log("✔ VM already exists. Proceeding to file transfer...");
            transferFilesToGCP();
        }
    });
}

function transferFilesToGCP() {
    console.log("📂 Transferring files...");
    exec(\`gcloud compute scp -r . \${GCP_USER}@\${GCP_INSTANCE}:~/cpu-monitoring-app --zone=\${GCP_ZONE}\`, 
        (error) => {
            if (error) {
                console.error(\`SCP Error: \${error.message}\`);
                return;
            }
            console.log("✔ Files transferred!");
            setupAndRunOnGCP();
        }
    );
}

function setupAndRunOnGCP() {
    console.log("🔧 Setting up on GCP...");
    exec(\`gcloud compute ssh \${GCP_USER}@\${GCP_INSTANCE} --zone=\${GCP_ZONE} --command="
        sudo apt update && 
        sudo apt install -y nodejs npm && 
        cd ~/cpu-monitoring-app && 
        npm install && 
        node server.js
    "\`, 
        (error) => {
            if (error) {
                console.error(\`GCP Setup Error: \${error.message}\`);
                return;
            }
            console.log("✔ Workload migrated to GCP!");
        }
    );
}

app.get("/", (req, res) => {
    res.send("<h1>CPU Monitoring</h1>");
});

app.get("/cpu_usage", (req, res) => {
    getCPUUsage((usage) => {
        if (usage > 75) {
            migrateToGCP();
        }
        res.json({ cpu_usage: usage });
    });
});

app.get("/start_compute", (req, res) => {
    cpuIntensiveTask();
    res.json({ status: "Computation started!" });
});

app.listen(PORT, () => console.log(\`🚀 Server running on http://localhost:\${PORT}\`));
EOF

echo "✔ Backend setup complete!"

# Create frontend
echo "📂 Setting up Frontend..."
npx create-react-app frontend
cd frontend
npm install axios recharts

# Create frontend App.js
echo "📝 Creating frontend App.js..."
cat <<EOF > src/App.js
import React, { useState, useEffect } from "react";
import axios from "axios";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

const App = () => {
    const [cpuUsage, setCpuUsage] = useState(0);
    const [data, setData] = useState([]);

    useEffect(() => {
        const interval = setInterval(() => {
            axios.get("http://localhost:5000/cpu_usage")
                .then(response => {
                    const usage = response.data.cpu_usage;
                    setCpuUsage(usage);
                    setData(prevData => [...prevData.slice(-20), { time: new Date().toLocaleTimeString(), usage }]);
                })
                .catch(error => console.error("Error fetching CPU usage:", error));
        }, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <div style={{ textAlign: "center", padding: "20px" }}>
            <h1>CPU Monitoring</h1>
            <h2>CPU Usage: {cpuUsage.toFixed(2)}%</h2>
            <ResponsiveContainer width="80%" height={300}>
                <LineChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" />
                    <YAxis domain={[0, 100]} />
                    <Tooltip />
                    <Line type="monotone" dataKey="usage" stroke="#8884d8" />
                </LineChart>
            </ResponsiveContainer>
        </div>
    );
};

export default App;
EOF

echo "✔ Frontend setup complete!"

# Go back to project root
cd ~/cpu-monitoring-app

echo "✔ Full-Stack App setup complete!"
echo "📢 Start Backend: 'node server.js'"
echo "📢 Start Frontend: 'cd frontend && npm start'"
