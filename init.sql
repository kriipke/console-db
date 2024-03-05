BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- [[ roles ]]

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
);
INSERT INTO roles (name, description) VALUES
('Administrator', 'Full access to all resources.'),
('Developer', 'Access to develop and deploy resources.'),
('Auditor', 'Read-only access.');


-- [[ teams ]]

CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
);


-- [[ users ]]

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


-- [[ audit_logs ]]

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    entity_id UUID NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
    details TEXT, -- JSON or TEXT for change details
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
);


-- [[ datacenter_configs ]]

CREATE TABLE datacenter_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255),
    datacenter VARCHAR(255),
    network VARCHAR(255),
    server VARCHAR(255),
    insecure BOOLEAN,
    thumbprint TEXT,
    created_by_user_id UUID REFERENCES users (id) ON DELETE SET NULL
);


-- [[ cluster_networks ]]

CREATE TABLE cluster_networks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cni_plugin VARCHAR(255),
    pods_cr_blocks TEXT,
    services_cr_blocks TEXT,
    created_by_user_id UUID REFERENCES users (id) ON DELETE SET NULL
);


-- [[ machine_configs ]]

CREATE TABLE machine_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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


-- [[ kubernetes_providers ]]

CREATE TABLE kubernetes_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    version VARCHAR(255),
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);
INSERT INTO kubernetes_providers (
    name, version, configuration, is_default
) VALUES ('EKS Anywhere', 'DEFAULT_VERSION', '{}', TRUE);


-- [[ s3_storage_backends ]]

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


-- [[ gitops_backends ]]

CREATE TABLE gitops_backends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    url VARCHAR(255),
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);
INSERT INTO gitops_backends (name, version, url, configuration, is_default)
VALUES ('ArgoCD', 'DEFAULT_VERSION', 'DEFAULT_URL', '{}', TRUE);


-- [[ container_registries ]]

CREATE TABLE container_registries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    url VARCHAR(255),
    admin_password VARCHAR(255),
    configuration TEXT,
    is_default BOOLEAN DEFAULT FALSE
);
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


-- [[ tags ]]

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(255) NOT NULL,
    value VARCHAR(255) NOT NULL
);

-- ENTITY TAGS TABLE: This new table entity_tags is designed to associate tags
--  with various entity types. Each record links a tag (tag_) to an entity (en
-- tity_id) and specifies the type of that entity (entity_type). This design a
-- llows for the tagging of a wide range
--
-- POLYMORPHIC ASSOCIATION: The entity_type column specifies the type of the e
-- ntity being tagged, such as 'clusters' or 'argo_applications', making this 
-- a polymorphic association. This approach proves great flexibility, allowing
--  any table/entity to be tagged by si    --
-- Conserations:
--
-- PERFORMANCE AND INDEXING: As the entity_tags table can grow significantly d
-- epending on the usage, conser adding indexes on entity_id, entity_type, and
--  tag_id columns to improve query performance, especially for JOIN operation
-- s or when filtering by these columns.
--
-- DATA INTEGRITY: The polymorphic association does not enforce referential in
-- tegrity at the database level for the entity_ and entity_type columns, as f
-- oreign keys do. Application logic may need to ensure that entity_id and ent
-- ity_type references are valid.
--
-- This modification to the database schema enables a highly flexible and exte
-- nsible tagging system, allowing for the tagging of various entities across 
-- the database without creating separate tables for each entity type's tags.
--
CREATE TABLE entity_tags (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag_id UUID NOT NULL,
    entity_id UUID NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
);


-- [[ tiers ]]

CREATE TABLE tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL CHECK (name IN ('dev', 'qa', 'uat', 'prod'))
);


-- [[ environments ]]

CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_id UUID NOT NULL,
    s3_storage_backend VARCHAR(255),
    s3_storage_backend_id UUID,
    helm_repository INT,
    container_registry_id UUID,
    container_registry INT,
    gitops_backend INT,
    gitops_backend_id UUID,
    FOREIGN KEY (s3_storage_backend_id) REFERENCES s3_storage_backends (
        id
    ) ON DELETE SET NULL,
    FOREIGN KEY (container_registry_id) REFERENCES container_registries (
        id
    ) ON DELETE SET NULL,
    FOREIGN KEY (tier_id) REFERENCES tiers (id) ON DELETE CASCADE,
    FOREIGN KEY (gitops_backend_id) REFERENCES gitops_backends (
        id
    ) ON DELETE SET NULL,
    FOREIGN KEY (container_registry_id) REFERENCES container_registries (
        id
    ) ON DELETE SET NULL
);


-- [[ clusters ]]

CREATE TABLE clusters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255),
    namespace VARCHAR(255),
    eksa_version VARCHAR(255),
    kubernetes_version VARCHAR(255),
    datacenter_config_id UUID,
    cluster_network_id UUID,
    control_plane_config_id UUID,
    etcd_config_id UUID,
    cluster_type VARCHAR(255) CHECK (cluster_type IN ('management', 'worker')),
    environment_id UUID,
    kubernetes_provider_id UUID,
    FOREIGN KEY (kubernetes_provider_id) REFERENCES kubernetes_providers (
        id
    ) ON DELETE SET NULL,
    FOREIGN KEY (datacenter_config_id) REFERENCES datacenter_configs (id),
    FOREIGN KEY (cluster_network_id) REFERENCES cluster_networks (id),
    FOREIGN KEY (control_plane_config_id) REFERENCES machine_configs (id),
    FOREIGN KEY (etcd_config_id) REFERENCES machine_configs (id),
    FOREIGN KEY (environment_id) REFERENCES environments (id) ON DELETE SET NULL
);


-- [[ cluster_relationships ]]

CREATE TABLE cluster_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mgmt_cluster_id UUID,
    worker_cluster_id UUID,
    FOREIGN KEY (mgmt_cluster_id) REFERENCES clusters (id) ON DELETE CASCADE,
    FOREIGN KEY (worker_cluster_id) REFERENCES clusters (id) ON DELETE CASCADE
);


-- [[ argo_applications ]]

CREATE TABLE argo_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    namespace VARCHAR(255) NOT NULL,
    cluster_id UUID,
    repo_url VARCHAR(255),
    path VARCHAR(255),
    target_revision VARCHAR(255),
    project VARCHAR(255),
    sync_policy VARCHAR(255),
    FOREIGN KEY (cluster_id) REFERENCES clusters (id) ON DELETE SET NULL
);


-- [[ harbor_deployments ]]

CREATE TABLE harbor_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(255),
    url VARCHAR(255),
    admin_password VARCHAR(255),
    configuration TEXT
);


-- [[ minio_deployments ]]

CREATE TABLE minio_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(255),
    url VARCHAR(255),
    access_key VARCHAR(255),
    secret_key VARCHAR(255),
    configuration TEXT
);


-- [[ argo_deployments ]]

CREATE TABLE argo_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(255),
    url VARCHAR(255),
    configuration TEXT
);


COMMIT;
