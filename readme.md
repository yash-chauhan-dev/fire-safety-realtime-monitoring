## Architecture Diagram

![Architecture Diagram](path/to/your/architecture-diagram.png)


## Node-RED Flow Image

![Node-RED Flow](assets\nodered-flow-image.PNG)



## Prerequisites

Before starting, ensure the following dependencies are installed on your machine:

- **Docker Desktop**: For containerized environments.
- **Node.js**: The runtime for JavaScript.
- **npm**: Node's package manager (comes with Node.js).

### Install Docker Desktop

1. Download Docker Desktop from the official website:
   - [Docker Desktop Download](https://www.docker.com/products/docker-desktop)

2. Follow the installation instructions based on your operating system.

### Install Node.js

1. Download Node.js from the official website:
   - [Node.js Download](https://nodejs.org/)

2. Choose the LTS (Long Term Support) version for stable builds.



## Installation & Setup

Once Docker Desktop and Node.js are installed, follow these steps to set up your development environment:

### 1. Install Node-RED globally

Node-RED is a flow-based development tool for visual programming, and you will need it to run this project.

Run the following command in your terminal:
```bash
npm install -g --unsafe-perm node-red
```
This installs Node-RED globally on your system. The `--unsafe-perm` flag is necessary for certain system environments that require elevated permissions.

### 2. Start Node-RED

After installation, start the Node-RED server with the following command:
```bash
node-red
```
This will start the Node-RED runtime.

## Start Docker Compose

You can start the containers with the following command:
```bash
docker-compose up -d
```

## Accessing the Application

1. Open your web browser.
2. Navigate to the following URL:
```bash
http://localhost:1880
```
3. You should now see the Node-RED interface, where you can create and manage your flows.

