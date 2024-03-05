package models

import (
	"gorm.io/gorm"
)

type DatacenterConfiguration struct {
	gorm.Model
	DatacenterConfigID uint `gorm:"primaryKey"`
	Name               string
	Datacenter         string
	Network            string
	Server             string
	Insecure           bool
	Thumbprint         string `gorm:"type:text"`
}

type ClusterNetwork struct {
	gorm.Model
	ClusterNetworkID   uint `gorm:"primaryKey"`
	CNIPlugin          string
	PodsCIDRBlocks     string `gorm:"type:text"` // Consider changing to JSON or a slice for structured data
	ServicesCIDRBlocks string `gorm:"type:text"` // Consider changing to JSON or a slice for structured data
}

type MachineConfig struct {
	gorm.Model
	MachineConfigID uint `gorm:"primaryKey"`
	Name            string
	Annotations     string `gorm:"type:text"` // Consider changing to JSON for structured data
	CloneMode       string
	Datastore       string
	DiskGiB         int
	Folder          string
	MemoryMiB       int
	NumCPUs         int
	OSFamily        string
	ResourcePool    string
	Template        string
	MachineRole     string `gorm:"check:machine_role IN ('control-plane', 'etcd', 'worker')"`
}

type Cluster struct {
	gorm.Model
	ClusterID               uint `gorm:"primaryKey"`
	Name                    string
	Namespace               string
	EksaVersion             string
	KubernetesVersion       string
	DatacenterConfigID      uint
	ClusterNetworkID        uint
	ControlPlaneConfigID    uint
	EtcdConfigID            uint
	ClusterType             string `gorm:"check:cluster_type IN ('Management', 'Worker')"`
	EnvironmentID           uint
	DatacenterConfiguration DatacenterConfiguration `gorm:"foreignKey:DatacenterConfigID"`
	ClusterNetwork          ClusterNetwork          `gorm:"foreignKey:ClusterNetworkID"`
	ControlPlaneConfig      MachineConfig           `gorm:"foreignKey:ControlPlaneConfigID"`
	EtcdConfig              MachineConfig           `gorm:"foreignKey:EtcdConfigID"`
}

type WorkerNodeGroup struct {
	gorm.Model
	WorkerNodeGroupID uint `gorm:"primaryKey"`
	ClusterID         uint
	Name              string
	Count             int
	MachineConfigID   uint
	Cluster           Cluster       `gorm:"foreignKey:ClusterID"`
	MachineConfig     MachineConfig `gorm:"foreignKey:MachineConfigID"`
}

type ArgoCDApplication struct {
	gorm.Model
	ApplicationID  uint   `gorm:"primaryKey"`
	Name           string `gorm:"not null"`
	Namespace      string `gorm:"not null"`
	ClusterID      uint
	RepoURL        string
	Path           string
	TargetRevision string
	Project        string
	SyncPolicy     string  `gorm:"type:text"` // Consider changing to JSON for complex structures
	Cluster        Cluster `gorm:"foreignKey:ClusterID"`
}

type Tag struct {
	gorm.Model
	TagID uint   `gorm:"primaryKey"`
	Key   string `gorm:"not null"`
	Value string `gorm:"not null"`
}

type ClusterTag struct {
	ClusterID uint    `gorm:"primaryKey"`
	TagID     uint    `gorm:"primaryKey"`
	Cluster   Cluster `gorm:"foreignKey:ClusterID"`
	Tag       Tag     `gorm:"foreignKey:TagID"`
}

type ApplicationTag struct {
	ApplicationID uint              `gorm:"primaryKey"`
	TagID         uint              `gorm:"primaryKey"`
	Application   ArgoCDApplication `gorm:"foreignKey:ApplicationID"`
	Tag           Tag               `gorm:"foreignKey:TagID"`
}

type Environment struct {
	gorm.Model
	EnvironmentID uint   `gorm:"primaryKey"`
	Name          string `gorm:"check:name IN ('DEV', 'QA', 'UAT', 'PROD')"`
}

type HarborRegistry struct{}

type MinIO struct{}

type ArgoCD struct{}

type ApplicationTier struct{}
