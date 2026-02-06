# Copilot Instructions for ThingsBoard Codebase

## Project Overview

**ThingsBoard** (v4.4.0) is an open-source IoT platform for device management, real-time data collection, visualization, and processing. Multi-tenant architecture with extensive microservices deployment options (Docker, Kubernetes).

**Tech Stack**: Java 17 + Spring Boot 3.4.10 + Maven | PostgreSQL/Cassandra | Valkey/Redis | Kafka | Protocol support: MQTT, HTTP, CoAP, LWM2M

---

## Architecture Essentials

### Core Service Layers

**Application Module** (`application/`): Main Spring Boot application containing:
- **Controllers** (`controller/`): REST API endpoints for devices, dashboards, rules, users
- **Services** (`service/`): Business logic organized by domain:
  - `device/` - Device provisioning & management
  - `telemetry/` - Timeseries data handling
  - `ruleengine/` - Rule chain processing (critical to platform)
  - `transport/` - Device communication abstraction
  - `user/`, `security/`, `session/` - Auth & multi-tenancy
  - `dashboard/`, `asset/`, `edge/`, `gateway_device/` - Feature services

**Protocol Transports** (`transport/`, `msa/`): Pluggable adapters for MQTT, HTTP, CoAP, LWM2M. Each transport validates credentials via `DeviceCredentialsService` and routes telemetry to `TelemetryService`.

**Common Modules** (`common/`): Shared abstractions:
- `actor/` - Akka-based actor model for distributed processing
- `dao-api/` - Repository interfaces (implemented in `dao/`)
- `queue/` - Kafka message queue abstraction
- `proto/` - Protocol Buffer definitions for inter-service communication
- `message/` - Core message types across services

**Data Access** (`dao/`): SQL/NoSQL implementations:
- PostgreSQL for entities (devices, users, rules, etc.)
- Cassandra for timeseries data (optimized for time-bucketed queries)

**Rule Engine** (`rule-engine/`): Separate module implementing configurable rule chains for data transformation and event triggering. Rules are chains of nodes (filter → transform → action) persisted as RuleChainMetadata.

---

## Critical Patterns & Conventions

### 1. **Rule Engine Chain Architecture**

Rules are modeled as **node chains** with inputs/outputs:

```java
// Rule chains are stored as RuleChainMetadata containing:
// - RuleNode[] nodes (filters, transformers, actions)
// - NodeConnectionInfo[] connections (defines graph)
// - Root node designation

// Example flow: [MQTT Message] → [Filter] → [Transform] → [Send Email Action]
```

**Key service**: `RuleEngineService` processes messages through chains. New rule node types extend `RuleNode`.

### 2. **Multi-Tenant Isolation**

All tenants share infrastructure but are **logically isolated**:
- Every entity has `tenantId` field (NEVER skip when querying/creating)
- Service methods filter by `SecurityContext.tenantId()` implicitly
- Query builders in `DAO` apply tenant filters automatically
- **Important**: REST controllers receive `TenantId` from JWT claims

Example pattern:
```java
// Controller layer
@PostMapping("/api/device")
public Device saveDevice(@RequestBody Device device) {
    device.setTenantId(getTenantId());  // From SecurityContext
    return deviceService.saveDevice(device);
}
```

### 3. **Entity-Relation Model**

Entities (device, asset, dashboard, etc.) can have **arbitrary relations**:

```java
EntityRelation relation = new EntityRelation(
    from: EntityId(type=DEVICE, uuid=xxx),
    to: EntityId(type=ASSET, uuid=yyy),
    type: "contains"  // Custom relation type
);
relationService.saveRelation(tenantId, relation);
```

Use `RelationService` for querying entity graphs.

### 4. **Telemetry & Attributes Two-Track System**

Devices store:
- **Telemetry** - Time-bucketed timeseries (Cassandra, queryable by time ranges)
- **Attributes** - Key-value pairs (PostgreSQL, per-device)
- **Latest values** - Cached in-memory and Valkey

Use `TelemetryService` for both. Cassandra partition keys are time-based (see `TimeseriesProto`).

### 5. **Transport Protocol Abstraction**

New protocol support: Extend `TransportService` or `TbTransportDeviceSession`. Each transport:
1. Authenticates device via `DeviceCredentialsService`
2. Converts protocol-specific messages to `TransportProtos.SessionEventMsg`
3. Publishes to Kafka topic for `TelemetryService` consumer

See `MqttTransportService`, `HttpTransportService` as reference implementations.

---

## Developer Workflows

### Building & Testing

**Full Build** (includes Docker image):
```bash
MAVEN_OPTS="-Xmx1024m" mvn clean install -DskipTests
```

**Fast Builds** (multi-threaded, parallel modules):
```bash
# See TEST_FAST.md for comprehensive test strategy
export MAVEN_OPTS="-Xmx1024m"
export SUREFIRE_JAVA_OPTS="-Xmx1200m -Xss256k"

# Build without tests (fastest)
mvn -T6 clean install -DskipTests

# Run non-application tests (DAO, common services) in parallel
mvn test -pl='!application,!dao,!ui-ngx,!msa/js-executor,!msa/web-ui' -T4

# Run DAO tests (heavy on DB)
mvn test -pl dao -Dparallel=packages -DforkCount=4

# Run application tests by domain (controller, service, transport tests separate)
mvn test -pl application -Dtest='org.thingsboard.server.controller.**' -DforkCount=6
mvn test -pl application -Dtest='org.thingsboard.server.service.**' -DforkCount=6
```

**Running Full Application**:
```bash
cd docker
./docker-install-tb.sh                        # Initialize DB
./docker-start-services.sh                    # Start all services
./docker-stop-services.sh                     # Stop gracefully
```

Default credentials: `sysadmin@thingsboard.org` / `sysadmin`

### IDE Setup

- **Java**: OpenJDK 17+ (project enforces via `maven.compiler.target`)
- **Build**: Maven 3.8+ (multi-module project, use `-T2` or `-T6` for parallel builds)
- **Lombok**: Required (generates getters/setters) - enable annotation processing
- **Code Style**: Apache License header in all files (enforced via `license-maven-plugin`)

---

## File Organization by Feature

| Domain | Main Files | Key Patterns |
|--------|-----------|--------------|
| **Devices** | `application/service/device/**`, `application/controller/DeviceController` | Uses `DeviceService`, `DeviceCredentialsService`; entity vs details pattern |
| **Dashboards** | `application/service/dashboard/**`, `application/controller/DashboardController` | Supports public sharing; widgets stored as JSON |
| **Rules** | `rule-engine/**`, `application/service/ruleengine/**` | Chain-based, nodes extend `RuleNode`; persisted in PostgreSQL |
| **Telemetry** | `application/service/telemetry/**` | Time-series in Cassandra; latest values cached; streaming via WebSocket |
| **Users & Auth** | `application/service/user/**`, `application/service/security/**` | JWT-based; SecurityContext holds tenant/user info; roles: SYS_ADMIN, TENANT_ADMIN, CUSTOMER_USER |
| **Edge** | `application/service/edge/**` | On-premise edge gateway; sync protocol with cloud |
| **Notifications** | `application/service/notification/**` | Email/SMS/push via pluggable handlers |

---

## Cross-Module Communication

1. **Kafka Messages** (`common/queue/`): Inter-service events encoded as Protocol Buffers
   - Topic: `tb.core.telemetry` for device data → Rule Engine
   - See `TransportProtos`, `RuleEngineProtos` for message definitions

2. **REST APIs**: Controllers expose OpenAPI (Swagger docs auto-generated)

3. **Database Propagation**: Rule Engine → affects Device state → visible in telemetry

---

## Documentation References

- **Configuration**: [MANUAL_CONFIGURACION.md](../MANUAL_CONFIGURACION.md)
- **Credentials/Auth**: [GUIA_CREDENCIALES.md](../GUIA_CREDENCIALES.md)
- **Deployment**: [GUIA_DESPLIEGUE_RASPBERRY.md](../GUIA_DESPLIEGUE_RASPBERRY.md), [GUIA_CICD.md](../GUIA_CICD.md)
- **Hybrid/Remote Access**: [GUIA_HIBRIDA_TAILSCALE_NGINX.md](../GUIA_HIBRIDA_TAILSCALE_NGINX.md)
- **Protocol Buffers**: Rebuild with `build_proto.sh` if modifying `common/proto/`

---

## Common Gotchas

- **Tenant filtering**: Always include `tenantId` in queries; don't rely solely on SecurityContext in background tasks
- **Cassandra time buckets**: Timeseries queries must account for partition key (time-based)
- **Rule Engine async**: Rule nodes are processed asynchronously; use callback patterns for chaining
- **Protocol upgrades**: If modifying Kafka message formats in `.proto` files, ensure backward compatibility
- **Docker volumes**: Database volumes persist; use `docker-compose.volumes.yml` for clean reinstalls

---

## Before Modifying Core Code

1. **Check `TEST_FAST.md`** for test patterns specific to the component
2. **Verify multi-tenancy**: Add tenant filtering if touching queries/services
3. **Update API docs**: Controllers auto-generate Swagger; check `@Operation` annotations  
4. **Run parallel tests**: Use test profile matching the domain (controller, service, transport)
5. **Test in Docker**: Integration with Kafka/Cassandra requires full environment
