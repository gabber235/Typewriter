# Contributing

This document outlines the process for setting up the local development environment for this project.

**Note:** These instructions are intended for **official project contributors** who have been granted access to the necessary secrets and infrastructure (specifically, the Pulumi stack). This guide does not cover contributions from external parties.

## Local Development Setup

This project uses Docker Compose to orchestrate services and Pulumi to manage environment configuration.

### Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Git:** For cloning the repository.
2.  **Docker & Docker Compose:** To build and run the containerized services. Docker Desktop usually includes both. Ensure the Docker daemon is running.
3.  **Pulumi CLI:** Used to fetch environment variables. [Install Pulumi CLI](https://www.pulumi.com/docs/install/).
4.  **Pulumi Account & Access:** You must have a Pulumi account and be granted access to the `seamlezz/development/typewriter` stack by a project administrator.

### Setup Instructions

1.  **Clone the Repository:**
    ```bash
    git clone <your-repository-url>
    cd <repository-directory>
    ```

2.  **Log into Pulumi:**
    Ensure you are logged into the Pulumi CLI using the account that has access to the project stack.
    ```bash
    pulumi login
    ```
    *(Follow the prompts to log in, typically via the browser).*

3.  **Generate Environment Configuration (`.env` file):**
    The project uses a script to fetch configuration secrets from Pulumi and place them into a `.env` file in the project root. This file is required by some services defined in Docker Compose.

    *   **(First time only) Make the script executable:**
        ```bash
        chmod +x docker/setup.sh
        ```
    *   **Run the setup script:**
        ```bash
        ./docker/setup.sh
        ```
    This script will:
    *   Navigate to the project root.
    *   Run `pulumi env open ...` to fetch secrets for the `seamlezz/development/typewriter` stack.
    *   Create or update the `.env` file in the project root.
    *   Provide clear error messages if the Pulumi command fails (e.g., if you're not logged in or lack access).

4.  **Start Services:**
    Once the `./docker/setup.sh` script completes successfully and the `.env` file is present:

    Navigate to the project root (if not already there) and run:
    ```bash
    # Run in foreground (logs in terminal)
    docker compose up

    # OR Run in detached mode (background)
    docker compose up -d
    ```
    This will build the necessary images (like `marketplace-frontend`) and start all the services defined across the included `*.compose.yml` files (`marketplace`, `surrealdb`, `wasmcloud`, etc.).

5.  **Accessing Services:**
    Once the containers are running, you should be able to access the services, for example:
    *   Marketplace Frontend (Dev): `http://localhost:5173`
    *   Storybook: `http://localhost:6006`
    *   SurrealDB (if needed directly): `localhost:9000` (Use credentials `root`/`root`)
    *   wasmCloud Dashboard (check wasmCloud docs for access): Potentially via NATS ports or specific dashboard setup. NATS monitoring: `http://localhost:8222`

### Development Workflow Notes

*   **`.env` Updates:** If the configuration in the Pulumi `seamlezz/development/typewriter` stack changes, you will need to re-run `./docker/setup.sh` to update your local `.env` file. You might need to restart your Docker Compose services (`docker compose down && docker compose up -d`) afterwards.
*   **Stopping Services:**
    ```bash
    docker compose down
    ```
*   **Cleaning Up:** To stop containers AND remove associated volumes (like database data, NATS data stored in `docker/surrealdb` and `docker/nats`):
    ```bash
    docker compose down -v
    ```
    **Warning:** This deletes local development data stored in the volumes.

### Troubleshooting

*   **Pulumi Errors during `./docker/setup.sh`:** Check the error message. Ensure you ran `pulumi login` and have access to the `seamlezz/development/typewriter` stack. Check your network connection.
*   **Docker Errors:** Ensure the Docker daemon is running. Check Docker's resource allocation (CPU/memory) if builds fail or containers crash. `docker compose logs <service_name>` can show logs for a specific container (e.g., `docker compose logs marketplace-frontend`).
