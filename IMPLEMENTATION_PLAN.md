# FoodDash - Implementation Plan

**Project Goal**: Build a real-time food delivery status tracking system using Event-Driven Architecture with AWS, Terraform, NestJS, and TypeScript.

**Total Estimated Time**: 10 hours

---

## 📋 Overview

This plan breaks down the project into 5 main milestones, each with specific tasks and deliverables. The architecture follows an Event-Driven pattern with:

- **External Producer** → AWS SQS → **NestJS Backend** → **Redis Pub/Sub** → **GraphQL Subscriptions** → **React Frontend**

---

## 🎯 Milestone 1: Core Setup (2 hours)

### Tasks:

1. **Initialize NestJS Project** (30 min)
   - Create NestJS application with TypeScript
   - Configure ESLint and Prettier
   - Set up project structure (`src/modules/`, `src/config/`, etc.)

2. **Set up Prisma** (30 min)
   - Install Prisma dependencies
   - Create `schema.prisma` with `Order` model and `OrderStatus` enum
   - Configure PostgreSQL connection
   - Generate Prisma Client
   - Create initial migration

3. **Configure Docker Compose** (20 min)
   - Verify existing `docker-compose.yml` (PostgreSQL + Redis)
   - Add NestJS service to docker-compose (optional for local dev)
   - Test database and Redis connections

4. **Set up Environment Configuration** (20 min)
   - Create `.env.example` with required variables
   - Configure NestJS `ConfigModule`
   - Set up environment validation

5. **Initialize Git Repository** (20 min)
   - Create `.gitignore`
   - Add initial commit
   - Set up basic project structure

### Deliverables:
- ✅ Working NestJS project structure
- ✅ Prisma schema with Order model
- ✅ Local PostgreSQL and Redis running via Docker
- ✅ Database migrations applied

### Files to Create:
```
food-dash/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── prisma/
│   │   └── schema.prisma
│   ├── config/
│   │   └── database.config.ts
│   └── modules/
├── .env.example
├── .gitignore
├── package.json
└── tsconfig.json
```

---

## 🎯 Milestone 2: GraphQL API (2 hours)

### Tasks:

1. **Install GraphQL Dependencies** (15 min)
   - `@nestjs/graphql`, `@nestjs/apollo`, `graphql`, `apollo-server-express`
   - `@graphql-tools/schema` (if needed)

2. **Create GraphQL Schema** (30 min)
   - Define `Order` type (matching Prisma model)
   - Define `Query` type with `getOrder(id: ID!): Order`
   - Define `Subscription` type with `orderStatusUpdated(orderId: ID!): Order`
   - Create `schema.gql` file

3. **Implement Order Service** (30 min)
   - Create `OrderService` with Prisma Client
   - Implement `findById(id: string)` method
   - Implement `updateStatus(id: string, status: OrderStatus)` method

4. **Implement Order Resolver** (30 min)
   - Create `OrderResolver` with `@Query()` for `getOrder`
   - Add `@Subscription()` decorator for `orderStatusUpdated`
   - Connect to Redis Pub/Sub for subscriptions

5. **Set up Redis Pub/Sub Module** (15 min)
   - Install `ioredis` or `redis` package
   - Create `RedisModule` with provider for Redis client
   - Create `RedisPubSubService` for publishing/subscribing

### Deliverables:
- ✅ GraphQL schema defined and working
- ✅ Query to fetch order by ID
- ✅ Subscription that listens to order status updates
- ✅ Redis Pub/Sub integration for multi-instance support

### Files to Create:
```
src/
├── modules/
│   └── order/
│       ├── order.module.ts
│       ├── order.service.ts
│       ├── order.resolver.ts
│       └── dto/
│           └── order.dto.ts
├── modules/
│   └── redis/
│       ├── redis.module.ts
│       └── redis.service.ts
└── graphql/
    └── schema.gql
```

### Key Implementation Notes:
- Use Redis Pub/Sub channel pattern: `order:${orderId}:status`
- Publish to Redis when order status updates
- Subscribe in GraphQL resolver to emit subscription events

---

## 🎯 Milestone 3: AWS Integration - SQS Worker (2 hours)

### Tasks:

1. **Set up AWS SDK** (20 min)
   - Install `@aws-sdk/client-sqs`
   - Configure AWS credentials (environment variables or IAM)
   - Create AWS configuration module

2. **Create SQS Queue Structure** (20 min)
   - Design message format for order updates
   - Example: `{ orderId: string, status: OrderStatus, driverName?: string }`
   - Document message schema

3. **Build SQS Worker Service** (60 min)
   - Create `SqsWorkerService` with polling logic
   - Implement long-polling (20 seconds) for efficiency
   - Parse incoming messages
   - Update order in database via `OrderService`
   - Publish status update to Redis Pub/Sub
   - Handle errors and message deletion
   - Add logging for debugging

4. **Create Simulated External Producer** (20 min)
   - Create script `scripts/simulate-producer.ts` or `src/scripts/send-test-message.ts`
   - Send test messages to SQS queue
   - Validate message format

### Deliverables:
- ✅ SQS worker polling messages from AWS SQS
- ✅ Order status updates processed and saved to database
- ✅ Status updates published to Redis for GraphQL subscriptions
- ✅ Test script to simulate external producer

### Files to Create:
```
src/
├── modules/
│   └── sqs/
│       ├── sqs.module.ts
│       ├── sqs-worker.service.ts
│       ├── sqs.config.ts
│       └── interfaces/
│           └── order-update-message.interface.ts
└── scripts/
    └── simulate-producer.ts
```

### Key Implementation Notes:
- Use SQS `receiveMessage` with `WaitTimeSeconds: 20` for long-polling
- Run worker as a background service (can use NestJS `@Cron` or separate process)
- Delete messages only after successful processing
- Handle duplicate messages (idempotency)

---

## 🎯 Milestone 4: React UI Dashboard (2 hours)

### Tasks:

1. **Set up React Project** (20 min)
   - Create `frontend/` directory
   - Initialize React with Vite or Create React App
   - Install dependencies: `@apollo/client`, `graphql`, `graphql-ws`

2. **Configure Apollo Client** (30 min)
   - Set up Apollo Client with GraphQL HTTP link
   - Configure WebSocket link for subscriptions
   - Create Apollo Provider wrapper

3. **Build Order Tracking Component** (40 min)
   - Create `OrderTracker` component
   - Display order details (customer name, driver name, status)
   - Show status timeline/stepper (Preparing → Out for Delivery → Delivered)
   - Add smooth transitions and animations
   - Handle loading and error states

4. **Implement Real-time Subscription** (30 min)
   - Subscribe to `orderStatusUpdated` subscription
   - Update component state when new status arrives
   - Add visual feedback for status changes

### Deliverables:
- ✅ React dashboard displaying order information
- ✅ Real-time status updates via GraphQL subscriptions
- ✅ Smooth UI transitions between statuses
- ✅ Responsive and visually appealing design

### Files to Create:
```
frontend/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── components/
│   │   ├── OrderTracker.tsx
│   │   └── StatusTimeline.tsx
│   ├── apollo/
│   │   └── client.ts
│   └── graphql/
│       ├── queries.ts
│       └── subscriptions.ts
├── package.json
└── vite.config.ts (or similar)
```

### Key Implementation Notes:
- Use `subscriptions-transport-ws` or `graphql-ws` for WebSocket connection
- Connect to GraphQL subscription endpoint (e.g., `ws://localhost:4000/graphql`)
- Show order ID input field to track specific orders

---

## 🎯 Milestone 5: Terraform & Cloud Deployment (1 hour)

### Tasks:

1. **Design Infrastructure** (15 min)
   - Identify required AWS resources:
     - EC2 instance (t3.micro)
     - SQS Queue
     - Security Groups
     - VPC (use default or create simple one)
     - IAM roles and policies

2. **Write Terraform Configuration** (30 min)
   - `main.tf`: EC2 instance configuration
   - `sqs.tf`: SQS queue setup
   - `security-groups.tf`: Inbound rules (SSH:22, HTTP:80, HTTPS:443, GraphQL:4000)
   - `variables.tf`: Input variables (instance type, region, etc.)
   - `outputs.tf`: Output SQS queue URL, EC2 public IP

3. **Create User Data Script** (15 min)
   - Script to install Docker on EC2
   - Pull application Docker image or clone repo
   - Start services with docker-compose
   - Configure environment variables

### Deliverables:
- ✅ Terraform files defining all AWS infrastructure
- ✅ Infrastructure can be deployed with `terraform apply`
- ✅ EC2 instance running application
- ✅ SQS queue created and accessible

### Files to Create:
```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── sqs.tf
├── security-groups.tf
├── ec2.tf
└── user-data.sh
```

### Key Implementation Notes:
- Use EC2 User Data to bootstrap the instance
- Store sensitive values in Terraform variables or AWS Secrets Manager
- Configure security groups to allow only necessary ports
- Use `aws provider` with credentials configured

---

## 🎯 Milestone 6: Polishing & Documentation (1 hour)

### Tasks:

1. **Create Comprehensive README.md** (30 min)
   - Project description and architecture overview
   - Prerequisites and setup instructions
   - Local development guide
   - AWS deployment instructions
   - Architecture diagram (text-based or image)
   - Environment variables documentation

2. **Add Architecture Diagram** (15 min)
   - Create diagram showing data flow
   - Show all components and their interactions
   - Can use Mermaid, PlantUML, or draw.io

3. **Final Testing & Bug Fixes** (15 min)
   - End-to-end test: Producer → SQS → Backend → Subscription → Frontend
   - Fix any critical bugs
   - Verify all components work together

### Deliverables:
- ✅ Complete README with setup instructions
- ✅ Architecture diagram
- ✅ Project ready for demonstration

### Files to Create/Update:
```
README.md (update with full documentation)
ARCHITECTURE.md (optional - detailed architecture)
```

---

## 📁 Final Project Structure

```
food-dash/
├── src/                          # NestJS Backend
│   ├── main.ts
│   ├── app.module.ts
│   ├── config/
│   ├── modules/
│   │   ├── order/
│   │   ├── sqs/
│   │   └── redis/
│   ├── prisma/
│   │   └── schema.prisma
│   └── scripts/
├── frontend/                     # React Application
│   ├── src/
│   │   ├── components/
│   │   ├── apollo/
│   │   └── graphql/
│   └── package.json
├── infrastructure/               # Terraform Files
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── sqs.tf
│   ├── security-groups.tf
│   └── ec2.tf
├── docker-compose.yml           # Local development
├── .env.example
├── .gitignore
├── package.json
├── tsconfig.json
├── README.md
└── IMPLEMENTATION_PLAN.md       # This file
```

---

## 🔑 Key Technical Decisions

1. **GraphQL Subscriptions**: Use Redis Pub/Sub to support horizontal scaling
2. **Message Queue**: AWS SQS provides reliability and decoupling
3. **Infrastructure**: Terraform for reproducible infrastructure
4. **Database**: PostgreSQL with Prisma ORM for type safety
5. **Real-time**: GraphQL Subscriptions over WebSocket

---

## 🚀 Quick Start Commands (Reference)

```bash
# Start local services
docker-compose up -d

# Run database migrations
npx prisma migrate dev

# Start NestJS backend
npm run start:dev

# Start React frontend
cd frontend && npm run dev

# Deploy infrastructure
cd infrastructure && terraform init && terraform apply

# Simulate producer
npm run script:simulate-producer
```

---

## 📝 Next Steps

Start with **Milestone 1** and work through each milestone sequentially. Each milestone builds upon the previous one, ensuring a solid foundation for the next component.

**Good luck building FoodDash! 🚀**