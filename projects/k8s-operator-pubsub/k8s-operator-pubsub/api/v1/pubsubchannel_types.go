// Package v1 contains API Schema definitions for the pubsub v1 API group
// +kubebuilder:object:generate=true
// +groupName=pubsub.jawaracloud.io
package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// PubSubChannelSpec defines the desired state of PubSubChannel
type PubSubChannelSpec struct {
	// ChannelName is the name of the pub/sub channel
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:MinLength=1
	ChannelName string `json:"channelName"`

	// RedisAddress is the address of the Redis/DragonFlyDB server
	// +kubebuilder:validation:Required
	// +kubebuilder:default="dragonfly:6379"
	RedisAddress string `json:"redisAddress,omitempty"`

	// Replicas is the number of subscriber replicas to run
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=100
	// +kubebuilder:default=1
	Replicas int32 `json:"replicas,omitempty"`

	// AutoScaling configuration for dynamic replica scaling
	// +optional
	AutoScaling *AutoScalingConfig `json:"autoScaling,omitempty"`

	// MessageTimeout is the timeout for message processing in seconds
	// +kubebuilder:default=30
	MessageTimeout int32 `json:"messageTimeout,omitempty"`

	// Image is the container image for the subscriber
	// +kubebuilder:default="jawaracloud/subscriber:latest"
	Image string `json:"image,omitempty"`

	// Resources defines the resource requirements for subscriber pods
	// +optional
	Resources *ResourceRequirements `json:"resources,omitempty"`

	// Env defines environment variables for subscriber containers
	// +optional
	Env []EnvVar `json:"env,omitempty"`
}

// AutoScalingConfig defines auto-scaling parameters
type AutoScalingConfig struct {
	// Enabled determines if auto-scaling is active
	// +kubebuilder:default=false
	Enabled bool `json:"enabled,omitempty"`

	// MinReplicas is the minimum number of replicas
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:default=1
	MinReplicas int32 `json:"minReplicas,omitempty"`

	// MaxReplicas is the maximum number of replicas
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:default=10
	MaxReplicas int32 `json:"maxReplicas,omitempty"`

	// TargetQueueDepth is the target queue depth per replica
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:default=100
	TargetQueueDepth int32 `json:"targetQueueDepth,omitempty"`

	// ScaleUpThreshold is the percentage above target to trigger scale up
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=1000
	// +kubebuilder:default=150
	ScaleUpThreshold int32 `json:"scaleUpThreshold,omitempty"`

	// ScaleDownThreshold is the percentage below target to trigger scale down
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=100
	// +kubebuilder:default=50
	ScaleDownThreshold int32 `json:"scaleDownThreshold,omitempty"`

	// CooldownPeriod is the time between scaling operations in seconds
	// +kubebuilder:default=60
	CooldownPeriod int32 `json:"cooldownPeriod,omitempty"`
}

// ResourceRequirements defines CPU and memory requirements
type ResourceRequirements struct {
	// Limits defines the maximum resources
	// +optional
	Limits map[string]string `json:"limits,omitempty"`

	// Requests defines the minimum resources
	// +optional
	Requests map[string]string `json:"requests,omitempty"`
}

// EnvVar defines an environment variable
type EnvVar struct {
	Name  string `json:"name"`
	Value string `json:"value,omitempty"`
}

// PubSubChannelStatus defines the observed state of PubSubChannel
type PubSubChannelStatus struct {
	// Conditions represent the latest available observations
	// +optional
	Conditions []Condition `json:"conditions,omitempty"`

	// Replicas is the current number of active replicas
	// +optional
	Replicas int32 `json:"replicas,omitempty"`

	// ReadyReplicas is the number of ready replicas
	// +optional
	ReadyReplicas int32 `json:"readyReplicas,omitempty"`

	// QueueDepth is the current queue depth
	// +optional
	QueueDepth int64 `json:"queueDepth,omitempty"`

	// MessageRate is the current message rate (messages per second)
	// +optional
	MessageRate float64 `json:"messageRate,omitempty"`

	// LastScaleTime is the last time scaling occurred
	// +optional
	LastScaleTime *metav1.Time `json:"lastScaleTime,omitempty"`

	// Phase represents the current phase of the channel
	// +optional
	Phase ChannelPhase `json:"phase,omitempty"`

	// ObservedGeneration is the last observed generation
	// +optional
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`
}

// ChannelPhase represents the phase of a PubSubChannel
type ChannelPhase string

const (
	// ChannelPhasePending means the channel is being created
	ChannelPhasePending ChannelPhase = "Pending"
	// ChannelPhaseRunning means the channel is active
	ChannelPhaseRunning ChannelPhase = "Running"
	// ChannelPhaseScaling means the channel is scaling
	ChannelPhaseScaling ChannelPhase = "Scaling"
	// ChannelPhaseFailed means the channel has failed
	ChannelPhaseFailed ChannelPhase = "Failed"
	// ChannelPhaseDeleting means the channel is being deleted
	ChannelPhaseDeleting ChannelPhase = "Deleting"
)

// Condition represents a condition of a PubSubChannel
type Condition struct {
	// Type of condition
	Type ConditionType `json:"type"`
	// Status of the condition
	Status ConditionStatus `json:"status"`
	// Last time the condition transitioned
	LastTransitionTime metav1.Time `json:"lastTransitionTime,omitempty"`
	// Reason for the condition's last transition
	Reason string `json:"reason,omitempty"`
	// Message about the transition
	Message string `json:"message,omitempty"`
}

// ConditionType represents a condition type
type ConditionType string

const (
	// ConditionReady means the channel is ready
	ConditionReady ConditionType = "Ready"
	// ConditionScaled means the channel is properly scaled
	ConditionScaled ConditionType = "Scaled"
	// ConditionConnected means the channel is connected to Redis
	ConditionConnected ConditionType = "Connected"
)

// ConditionStatus represents a condition status
type ConditionStatus string

const (
	// ConditionTrue means the condition is true
	ConditionTrue ConditionStatus = "True"
	// ConditionFalse means the condition is false
	ConditionFalse ConditionStatus = "False"
	// ConditionUnknown means the condition status is unknown
	ConditionUnknown ConditionStatus = "Unknown"
)

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:subresource:scale:specpath=.spec.replicas,statuspath=.status.replicas,selectorpath=.status.selector
// +kubebuilder:resource:scope=Namespaced,shortName=psc
// +kubebuilder:printcolumn:name="Channel",type=string,JSONPath=`.spec.channelName`
// +kubebuilder:printcolumn:name="Phase",type=string,JSONPath=`.status.phase`
// +kubebuilder:printcolumn:name="Replicas",type=integer,JSONPath=`.status.replicas`
// +kubebuilder:printcolumn:name="Queue",type=integer,JSONPath=`.status.queueDepth`
// +kubebuilder:printcolumn:name="Age",type=date,JSONPath=`.metadata.creationTimestamp`

// PubSubChannel is the Schema for the pubsubchannels API
type PubSubChannel struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PubSubChannelSpec   `json:"spec,omitempty"`
	Status PubSubChannelStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// PubSubChannelList contains a list of PubSubChannel
type PubSubChannelList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PubSubChannel `json:"items"`
}

func init() {
	SchemeBuilder.Register(&PubSubChannel{}, &PubSubChannelList{})
}
