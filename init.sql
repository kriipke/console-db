BEGIN;

-- Datacenter Configurations
CREATE TABLE DatacenterConfigurations (
    DatacenterConfigID SERIAL PRIMARY KEY,
    Name VARCHAR(255),
    Datacenter VARCHAR(255),
    Network VARCHAR(255),
    Server VARCHAR(255),
    Insecure BOOLEAN,
    Thumbprint TEXT
);

-- Cluster Networks
CREATE TABLE ClusterNetworks (
    ClusterNetworkID SERIAL PRIMARY KEY,
    CNIPlugin VARCHAR(255),
    -- Consider using JSON or array type for structured data
    PodsCIDRBlocks TEXT,
    -- Consider using JSON or array type for structured data
    ServicesCIDRBlocks TEXT
);

-- Machine Configurations
CREATE TABLE MachineConfigs (
    MachineConfigID SERIAL PRIMARY KEY,
    Name VARCHAR(255),
    Annotations TEXT, -- Consider using JSON for structured data
    CloneMode VARCHAR(255),
    Datastore VARCHAR(255),
    DiskGiB INT,
    Folder VARCHAR(255),
    MemoryMiB INT,
    NumCPUs INT,
    OSFamily VARCHAR(255),
    ResourcePool VARCHAR(255),
    Template VARCHAR(255),
    MachineRole VARCHAR(255) CHECK (
        MachineRole IN ('control-plane', 'etcd', 'worker')
    )
);

-- Clusters
CREATE TABLE Clusters (
    ClusterID SERIAL PRIMARY KEY,
    Name VARCHAR(255),
    Namespace VARCHAR(255),
    EksaVersion VARCHAR(255),
    KubernetesVersion VARCHAR(255),
    DatacenterConfigID INT,
    ClusterNetworkID INT,
    ControlPlaneConfigID INT,
    EtcdConfigID INT,
    ClusterType VARCHAR(255) CHECK (ClusterType IN ('Management', 'Worker')),
    EnvironmentID INT,
    FOREIGN KEY (DatacenterConfigID) REFERENCES DatacenterConfigurations (
        DatacenterConfigID
    ),
    FOREIGN KEY (ClusterNetworkID) REFERENCES ClusterNetworks (
        ClusterNetworkID
    ),
    FOREIGN KEY (ControlPlaneConfigID) REFERENCES MachineConfigs (
        MachineConfigID
    ),
    FOREIGN KEY (EtcdConfigID) REFERENCES MachineConfigs (MachineConfigID),
    FOREIGN KEY (EnvironmentID) REFERENCES Environments (
        EnvironmentID
    ) ON DELETE SET NULL
);

-- Worker Node Groups
CREATE TABLE WorkerNodeGroups (
    WorkerNodeGroupID SERIAL PRIMARY KEY,
    ClusterID INT,
    Name VARCHAR(255),
    Count INT,
    MachineConfigID INT,
    FOREIGN KEY (ClusterID) REFERENCES Clusters (ClusterID),
    FOREIGN KEY (MachineConfigID) REFERENCES MachineConfigs (MachineConfigID)
);

-- ArgoCD Applications
CREATE TABLE ArgoCDApplications (
    ApplicationID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Namespace VARCHAR(255) NOT NULL,
    ClusterID INT,
    RepoURL VARCHAR(255),
    Path VARCHAR(255),
    TargetRevision VARCHAR(255),
    Project VARCHAR(255),
    SyncPolicy VARCHAR(255), -- Simple text to describe the sync policy; consider JSON for complex structures
    FOREIGN KEY (ClusterID) REFERENCES Clusters (ClusterID) ON DELETE SET NULL
);

-- Tags Table
CREATE TABLE Tags (
    TagID SERIAL PRIMARY KEY,
    Key VARCHAR(255) NOT NULL,
    Value VARCHAR(255) NOT NULL
);

-- Junction table for Clusters and Tags
CREATE TABLE ClusterTags (
    ClusterID INT,
    TagID INT,
    PRIMARY KEY (ClusterID, TagID),
    FOREIGN KEY (ClusterID) REFERENCES Clusters (ClusterID) ON DELETE CASCADE,
    FOREIGN KEY (TagID) REFERENCES Tags (TagID) ON DELETE CASCADE
);

-- Junction table for ArgoCDApplications and Tags
CREATE TABLE ApplicationTags (
    ApplicationID INT,
    TagID INT,
    PRIMARY KEY (ApplicationID, TagID),
    FOREIGN KEY (ApplicationID) REFERENCES ArgoCDApplications (
        ApplicationID
    ) ON DELETE CASCADE,
    FOREIGN KEY (TagID) REFERENCES Tags (TagID) ON DELETE CASCADE
);

-- Environments Table
CREATE TABLE Environments (
    EnvironmentID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL CHECK (Name IN ('DEV', 'QA', 'UAT', 'PROD'))
);


-- Harbor Registry Table
CREATE TABLE HarborRegistry (
    HarborID SERIAL PRIMARY KEY,
    Version VARCHAR(255),
    URL VARCHAR(255),
    -- Consider encrypting this or using a secure reference
    AdminPassword VARCHAR(255),
    Configuration TEXT -- JSON or text to store additional configuration details
);

-- MinIO Table
CREATE TABLE MinIO (
    MinIOID SERIAL PRIMARY KEY,
    Version VARCHAR(255),
    URL VARCHAR(255),
    AccessKey VARCHAR(255),
    -- Consider encrypting this or using a secure reference
    SecretKey VARCHAR(255),
    Configuration TEXT -- JSON or text to store additional configuration details
);

-- ArgoCD Table (if needed, assuming there's more specific info to store)
CREATE TABLE ArgoCD (
    ArgoCDID SERIAL PRIMARY KEY,
    Version VARCHAR(255),
    URL VARCHAR(255),
    Configuration TEXT -- JSON or text to store additional configuration details
);

-- Application Tier Table to represent the state of each environment
CREATE TABLE ApplicationTier (
    ApplicationTierID SERIAL PRIMARY KEY,
    EnvironmentID INT NOT NULL,
    ArgoCDID INT, -- Reference to an ArgoCD instance
    HarborID INT, -- Reference to a Harbor Registry instance
    MinIOID INT, -- Reference to a MinIO instance
    -- Add other fields as necessary for different types of application infrastructure components
    FOREIGN KEY (EnvironmentID) REFERENCES Environments (
        EnvironmentID
    ) ON DELETE CASCADE,
    FOREIGN KEY (ArgoCDID) REFERENCES ArgoCD (ArgoCDID) ON DELETE SET NULL,
    FOREIGN KEY (HarborID) REFERENCES HarborRegistry (
        HarborID
    ) ON DELETE SET NULL,
    FOREIGN KEY (MinIOID) REFERENCES MinIO (MinIOID) ON DELETE SET NULL
    -- Additional FOREIGN KEY constraints for other components
);

COMMIT;
