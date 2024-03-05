BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Datacenter Configurations
CREATE TABLE datacenter_configs (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    datacenter VARCHAR(255),
    network VARCHAR(255),
    server VARCHAR(255),
    insecure BOOLEAN,
    thumbprint TEXT,
    created_by_user_id INT REFERENCES users(id) ON DELETE SET NULL
);

-- Optional: Add user_id columns to existing tables to track who created/modified/deleted entities

-- Cluster Networks
CREATE TABLE cluster_networks (
    cluster_network_id SERIAL PRIMARY KEY,
    cni_plugin VARCHAR(255),
    pods_cr_blocks TEXT,
    services_cr_blocks TEXT,
    created_by_user_id INT REFERENCES users(id) ON DELETE SET NULL
);

-- Machine Configurations
CREATE TABLE machine_configs (
    machine_config_id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    annotations TEXT,
    clone_mode VARCHAR(255),
    datastore VARCHAR(255),
    disk_gib INT,
    folder VARCHAR(255),
    memory_mib INT,
    num_cpus INT,
    os_family VARCHAR(255),
    resource_pool VARCHAR(255),
    template VARCHAR(255),
    machine_role VARCHAR(255) CHECK (
        machine_role IN ('control-plane', 'etcd', 'worker')
    )
);

-- Clusters
CREATE TABLE clusters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    namespace VARCHAR(255),
    eksa_version VARCHAR(255),
    kubernetes_version VARCHAR(255),
    datacenter_config_id INT,
    cluster_network_id INT,
    control_plane_config_id INT,
    etcd_config_id INT,
    cluster_type VARCHAR(255) CHECK (cluster_type IN ('management', 'worker')),
    environment_id INT,
    kubernetes_provider_id INT,
    FOREIGN KEY (kubernetes_provider_id) REFERENCES kubernetes_providers(id) ON DELETE SET NULL
    FOREIGN KEY (datacenter_config_id) REFERENCES datacenter_configs (
        datacenter_config_id
    ),
    FOREIGN KEY (cluster_network_id) REFERENCES cluster_networks (
        cluster_network_id
    ),
    FOREIGN KEY (control_plane_config_id) REFERENCES machine_configs (
        machine_config_id
    ),
    FOREIGN KEY (etcd_config_id) REFERENCES machine_configs (machine_config_id),
    FOREIGN KEY (environment_id) REFERENCES environments (
        environment_id
    ) ON DELETE SET NULL
);

-- Worker Node Groups
CREATE TABLE worker_node_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cluster_id UUID,
    machine_config_id UUID,
    name VARCHAR(255),
    count INT,
    FOREIGN KEY (cluster_id) REFERENCES clusters(id),
    FOREIGN KEY (machine_config_id) REFERENCES machine_configs (id)
);

-- ArgoCD Applications
CREATE TABLE argocd_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    namespace VARCHAR(255) NOT NULL,
    cluster_id UUID,
    repo_url VARCHAR(255),
    path VARCHAR(255),
    target_revision VARCHAR(255),
    project VARCHAR(255),
    sync_policy VARCHAR(255),
    FOREIGN KEY (cluster_id) REFERENCES clusters(id) ON DELETE SET NULL
);

-- Tags Table
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(255) NOT NULL,
    value VARCHAR(255) NOT NULL
);

-- Environments Table
CREATE TABLE tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL CHECK (name IN ('dev', 'qa', 'uat', 'prod'))
);

-- Harbor Registry
CREATE TABLE harbor_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(255),
    url VARCHAR(255),
    admin_password VARCHAR(255),
    configuration TEXT
);

-- MinIO
CREATE TABLE minio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(255),
    url VARCHAR(255),
    access_key VARCHAR(255),
    secret_key VARCHAR(255),
    configuration TEXT
);

-- ArgoCD
CREATE TABLE argocd (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(255),
    url VARCHAR(255),
    configuration TEXT
);

-- Application Tier
CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_id UUID NOT NULL,
    s3_backend INT,
    s3_backend_id UUID,
    helm_repository INT,
    container_registry_id UUID,
    container_registry INT,
    container_registry_id UUID,
    gitops_backend INT,
    gitops_backend_id UUID,
    FOREIGN KEY (s3_backend_id) REFERENCES s3_storage_backends (s3_backend_id) ON DELETE SET NULL,
    FOREIGN KEY (container_registry_id) REFERENCES container_registries (id) ON DELETE SET NULL,
    FOREIGN KEY (gitops_backend_id) REFERENCES gitops_backends (id) ON DELETE SET NULL;
    FOREIGN KEY (environment_id) REFERENCES environments (environment_id) ON DELETE CASCADE,
    FOREIGN KEY (argocd_id) REFERENCES argocd (argocd_id) ON DELETE SET NULL,
    FOREIGN KEY (harbor_id) REFERENCES harbor_registry (id) ON DELETE SET NULL,
    FOREIGN KEY (minio_id) REFERENCES minio (id) ON DELETE SET NULL
);

-- Cluster Relationships
CREATE TABLE cluster_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    management_cluster_id UUID,
    worker_cluster_id UUID,
    FOREIGN KEY (management_cluster_id) REFERENCES clusters (id) ON DELETE CASCADE,
    FOREIGN KEY (worker_cluster_id) REFERENCES clusters (id) ON DELETE CASCADE
);

-- S3 Storage Backend
CREATE TABLE s3_storage_backends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    url VARCHAR(255),
    access_key VARCHAR(255),
    secret_key VARCHAR(255),
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);

-- Insert MinIO as the default S3 storage backend
INSERT INTO s3_storage_backends (
    name, version, url, access_key, secret_key, configuration, is_default
)
VALUES (
    'MinIO',
    'DEFAULT_VERSION',
    'DEFAULT_URL',
    'DEFAULT_ACCESS_KEY',
    'DEFAULT_SECRET_KEY',
    '{}',
    TRUE
);

-- Container Registry
CREATE TABLE container_registries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    url VARCHAR(255),
    admin_password VARCHAR(255),
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);

-- Insert Harbor as the default container registry
INSERT INTO container_registries (
    name, version, url, admin_password, configuration, is_default
)
VALUES (
    'Harbor',
    'DEFAULT_VERSION',
    'DEFAULT_URL',
    'DEFAULT_ADMIN_PASSWORD',
    '{}',
    TRUE
);

-- GitOps Backend
CREATE TABLE gitops_backends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    url VARCHAR(255),
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);
-- Insert ArgoCD as the default GitOps backend
INSERT INTO gitops_backends (name, version, url, configuration, is_default)
VALUES ('ArgoCD', 'DEFAULT_VERSION', 'DEFAULT_URL', '{}', TRUE);


-- Optional: Drop the old specific tables if they are no longer needed
-- DROP TABLE IF EXISTS minio;
-- DROP TABLE IF EXISTS harbor_registry;
-- DROP TABLE IF EXISTS argocd;

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- Conser hashing passwords
    email VARCHAR(255) UNIQUE NOT NULL,
    role_id UUID,
    team_id UUID,
    FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE SET NULL,
    FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE SET NULL
);

-- Roles Table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
);

-- Teams Table
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
);

-- Example roles (additional roles can be added as needed)
INSERT INTO roles (name, description) VALUES
('Administrator', 'Full access to all resources.'),
('Developer', 'Access to develop and deploy resources.'),
('Auditor', 'Read-only access.');

-- Auditing Table for tracking changes
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
    user_id UUID NOT NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    entity_id UUID NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    details TEXT, -- JSON or TEXT for change details
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
);


-- Allow tagging of any entity
CREATE TABLE entity_tags (

    -- ENTITY TAGS TABLE: This new table entity_tags is designed to associate tags with various entity types. Each record links a tag (tag_) to an entity (entity_id) and specifies the type of that entity (entity_type). This design allows for the tagging of a wide range of entities within the database without needing a separate tagging table for each entity type.
    -- POLYMORPHIC ASSOCIATION: The entity_type column specifies the type of the entity being tagged, such as 'clusters' or 'argocd_applications', making this a polymorphic association. This approach proves great flexibility, allowing any table/entity to be tagged by simply adding a record to the entity_tags table with the appropriate entity_id, entity_type, and tag_id.
    -- 
    -- Conserations:
    -- 
    -- PERFORMANCE AND INDEXING: As the entity_tags table can grow significantly depending on the usage, conser adding indexes on entity_id, entity_type, and tag_id columns to improve query performance, especially for JOIN operations or when filtering by these columns.
    -- DATA INTEGRITY: The polymorphic association does not enforce referential integrity at the database level for the entity_ and entity_type columns, as foreign keys do. Application logic may need to ensure that entity_id and entity_type references are valid.
    -- 
    -- This modification to the database schema enables a highly flexible and extensible tagging system, allowing for the tagging of various entities across the database without creating separate tables for each entity type's tags.

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
    tag_id UUID NOT NULL,
    entity_id UUID NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Example usage: To tag a cluster, the entity_type would be 'clusters' and entity_ would be the cluster's ID.
-- To tag an application, entity_type would be 'argocd_applications' and entity_ would be the application's ID.

-- Insert a tag and link it to a cluster (assuming tag_ and cluster_id are known)
-- INSERT INTO entity_tags (tag_id, entity_id, entity_type) VALUES (1, 123, 'clusters');

-- Insert a tag and link it to an ArgoCD application (assuming tag_ and application_id are known)
-- INSERT INTO entity_tags (tag_id, entity_id, entity_type) VALUES (2, 456, 'argocd_applications');

-- Note: You might conser adding indexes on the entity_tags table for the entity_id and entity_type columns to improve query performance

-- Kubernetes Provers Table
CREATE TABLE kubernetes_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
    name VARCHAR(255) UNIQUE NOT NULL,
    version VARCHAR(255),
    -- JSON or TEXT to store prover-specific configurations
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);
-- Insert EKS Anywhere as the default Kubernetes prover
INSERT INTO kubernetes_providers (name, version, configuration, is_default)
VALUES ('EKS Anywhere', 'DEFAULT_VERSION', '{}', TRUE);


COMMIT;
