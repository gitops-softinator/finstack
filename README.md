# FinStack

FinStack is a microservices based finacial platform.

## Architecture

This application is divided in to 6 main microservices:

- **API Gateway (3000)**: Single entry point that routes requests to internal services.
- **Auth Service (4000)**: User authentication and registrations.
- **User Service (4001)**: User profile management.
- **Payment Service (4002)**: Payment processing simulation.
- **Notification Service (4003)**: System notifications.
- **Transaction Service (4004)**: Ledger records.

## Quick Start (Local Setup)

Use Docker Compose to start the application:

```bash
docker-compose up -d
```

Access Frontend: `http://localhost:8080`\
API Gateway: `http://localhost:3000`

## Project Structure

- `/services`: Backend microservices.
- `/Frontend`: React client application.
- `/gateway`: API Gateway.

## Tech Stack

- **Frontend**: React.js
- **Backend**: Node.js & Express
- **Database**: MongoDB (6.0)