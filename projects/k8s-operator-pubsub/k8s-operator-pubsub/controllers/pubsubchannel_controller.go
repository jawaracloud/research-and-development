package controllers

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/tools/record"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	pubsubv1 "github.com/jawaracloud/pubsub-operator/api/v1"
)

// PubSubChannelReconciler reconciles a PubSubChannel object
type PubSubChannelReconciler struct {
	client.Client
	Scheme   *runtime.Scheme
	Recorder record.EventRecorder
}

//+kubebuilder:rbac:groups=pubsub.jawaracloud.io,resources=pubsubchannels,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=pubsub.jawaracloud.io,resources=pubsubchannels/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=pubsub.jawaracloud.io,resources=pubsubchannels/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=events,verbs=create;patch

// Reconcile is part of the main kubernetes reconciliation loop
func (r *PubSubChannelReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// Fetch the PubSubChannel instance
	channel := &pubsubv1.PubSubChannel{}
	if err := r.Get(ctx, req.NamespacedName, channel); err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted
			logger.Info("PubSubChannel resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		// Error reading the object
		logger.Error(err, "Failed to get PubSubChannel")
		return ctrl.Result{}, err
	}

	// Set initial phase if not set
	if channel.Status.Phase == "" {
		channel.Status.Phase = pubsubv1.ChannelPhasePending
		if err := r.Status().Update(ctx, channel); err != nil {
			return ctrl.Result{}, err
		}
	}

	// Handle deletion
	if !channel.DeletionTimestamp.IsZero() {
		return r.reconcileDelete(ctx, channel)
	}

	// Add finalizer if not present
	if !controllerutil.ContainsFinalizer(channel, "pubsubchannel.finalizers.pubsub.jawaracloud.io") {
		controllerutil.AddFinalizer(channel, "pubsubchannel.finalizers.pubsub.jawaracloud.io")
		if err := r.Update(ctx, channel); err != nil {
			return ctrl.Result{}, err
		}
	}

	// Reconcile Deployment
	if err := r.reconcileDeployment(ctx, channel); err != nil {
		logger.Error(err, "Failed to reconcile Deployment")
		r.updateCondition(ctx, channel, pubsubv1.ConditionReady, pubsubv1.ConditionFalse, "DeploymentFailed", err.Error())
		return ctrl.Result{}, err
	}

	// Check auto-scaling
	if channel.Spec.AutoScaling != nil && channel.Spec.AutoScaling.Enabled {
		if err := r.reconcileAutoScaling(ctx, channel); err != nil {
			logger.Error(err, "Failed to reconcile auto-scaling")
			return ctrl.Result{}, err
		}
	}

	// Update status
	if err := r.updateStatus(ctx, channel); err != nil {
		logger.Error(err, "Failed to update status")
		return ctrl.Result{}, err
	}

	// Update conditions
	r.updateCondition(ctx, channel, pubsubv1.ConditionReady, pubsubv1.ConditionTrue, "DeploymentReady", "All resources are ready")

	logger.Info("Successfully reconciled PubSubChannel",
		"name", channel.Name,
		"namespace", channel.Namespace,
		"phase", channel.Status.Phase)

	return ctrl.Result{RequeueAfter: time.Second * 30}, nil
}

func (r *PubSubChannelReconciler) reconcileDeployment(ctx context.Context, channel *pubsubv1.PubSubChannel) error {
	logger := log.FromContext(ctx)

	// Define the deployment
	deployment := &appsv1.Deployment{}
	deploymentName := fmt.Sprintf("%s-subscriber", channel.Name)

	// Check if deployment exists
	found := &appsv1.Deployment{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      deploymentName,
		Namespace: channel.Namespace,
	}, found)

	// Create deployment if it doesn't exist
	if err != nil && errors.IsNotFound(err) {
		// Set deployment properties
		labels := map[string]string{
			"app":                          "pubsub-subscriber",
			"pubsubchannel":                channel.Name,
			"app.kubernetes.io/name":       "subscriber",
			"app.kubernetes.io/instance":   channel.Name,
			"app.kubernetes.io/managed-by": "pubsub-operator",
		}

		replicas := channel.Spec.Replicas
		if replicas == 0 {
			replicas = 1
		}

		image := channel.Spec.Image
		if image == "" {
			image = "jawaracloud/subscriber:latest"
		}

		deployment = &appsv1.Deployment{
			ObjectMeta: metav1.ObjectMeta{
				Name:      deploymentName,
				Namespace: channel.Namespace,
				Labels:    labels,
			},
			Spec: appsv1.DeploymentSpec{
				Replicas: &replicas,
				Selector: &metav1.LabelSelector{
					MatchLabels: map[string]string{
						"app":           "pubsub-subscriber",
						"pubsubchannel": channel.Name,
					},
				},
				Template: corev1.PodTemplateSpec{
					ObjectMeta: metav1.ObjectMeta{
						Labels: labels,
					},
					Spec: corev1.PodSpec{
						Containers: []corev1.Container{{
							Name:      "subscriber",
							Image:     image,
							Env:       r.buildEnvVars(channel),
							Resources: r.buildResourceRequirements(channel),
						}},
					},
				},
			},
		}

		// Set controller reference
		if err := controllerutil.SetControllerReference(channel, deployment, r.Scheme); err != nil {
			return err
		}

		logger.Info("Creating a new Deployment", "Deployment.Namespace", deployment.Namespace, "Deployment.Name", deployment.Name)
		if err := r.Create(ctx, deployment); err != nil {
			return err
		}

		// Record event
		r.Recorder.Eventf(channel, corev1.EventTypeNormal, "Created", "Created Deployment %s", deployment.Name)
		return nil
	} else if err != nil {
		return err
	}

	// Update deployment if needed
	needsUpdate := false

	// Check replicas
	if found.Spec.Replicas != nil && *found.Spec.Replicas != channel.Spec.Replicas {
		if channel.Spec.AutoScaling == nil || !channel.Spec.AutoScaling.Enabled {
			found.Spec.Replicas = &channel.Spec.Replicas
			needsUpdate = true
		}
	}

	// Check image
	if len(found.Spec.Template.Spec.Containers) > 0 && found.Spec.Template.Spec.Containers[0].Image != channel.Spec.Image {
		if channel.Spec.Image != "" {
			found.Spec.Template.Spec.Containers[0].Image = channel.Spec.Image
			needsUpdate = true
		}
	}

	if needsUpdate {
		logger.Info("Updating Deployment", "Deployment.Namespace", found.Namespace, "Deployment.Name", found.Name)
		if err := r.Update(ctx, found); err != nil {
			return err
		}
		r.Recorder.Eventf(channel, corev1.EventTypeNormal, "Updated", "Updated Deployment %s", found.Name)
	}

	return nil
}

func (r *PubSubChannelReconciler) reconcileAutoScaling(ctx context.Context, channel *pubsubv1.PubSubChannel) error {
	logger := log.FromContext(ctx)

	if channel.Spec.AutoScaling == nil || !channel.Spec.AutoScaling.Enabled {
		return nil
	}

	// Check cooldown period
	if channel.Status.LastScaleTime != nil {
		cooldown := time.Duration(channel.Spec.AutoScaling.CooldownPeriod) * time.Second
		if time.Since(channel.Status.LastScaleTime.Time) < cooldown {
			return nil
		}
	}

	currentReplicas := channel.Status.Replicas
	if currentReplicas == 0 {
		currentReplicas = channel.Spec.Replicas
	}
	if currentReplicas == 0 {
		currentReplicas = 1
	}

	queueDepth := channel.Status.QueueDepth
	targetDepth := int64(channel.Spec.AutoScaling.TargetQueueDepth)

	if targetDepth == 0 {
		targetDepth = 100
	}

	scaleUpThreshold := float64(channel.Spec.AutoScaling.ScaleUpThreshold) / 100.0
	scaleDownThreshold := float64(channel.Spec.AutoScaling.ScaleDownThreshold) / 100.0

	if scaleUpThreshold == 0 {
		scaleUpThreshold = 1.5
	}
	if scaleDownThreshold == 0 {
		scaleDownThreshold = 0.5
	}

	var newReplicas int32 = currentReplicas

	// Scale up
	if float64(queueDepth) > float64(targetDepth*int64(currentReplicas))*scaleUpThreshold {
		newReplicas = currentReplicas + 1
		if channel.Spec.AutoScaling.MaxReplicas > 0 && newReplicas > channel.Spec.AutoScaling.MaxReplicas {
			newReplicas = channel.Spec.AutoScaling.MaxReplicas
		}
		logger.Info("Scaling up", "from", currentReplicas, "to", newReplicas, "queueDepth", queueDepth)
	}

	// Scale down
	if float64(queueDepth) < float64(targetDepth*int64(currentReplicas))*scaleDownThreshold {
		newReplicas = currentReplicas - 1
		if channel.Spec.AutoScaling.MinReplicas > 0 && newReplicas < channel.Spec.AutoScaling.MinReplicas {
			newReplicas = channel.Spec.AutoScaling.MinReplicas
		}
		if newReplicas < 1 {
			newReplicas = 1
		}
		logger.Info("Scaling down", "from", currentReplicas, "to", newReplicas, "queueDepth", queueDepth)
	}

	if newReplicas != currentReplicas {
		deployment := &appsv1.Deployment{}
		deploymentName := fmt.Sprintf("%s-subscriber", channel.Name)

		if err := r.Get(ctx, types.NamespacedName{
			Name:      deploymentName,
			Namespace: channel.Namespace,
		}, deployment); err != nil {
			return err
		}

		deployment.Spec.Replicas = &newReplicas
		if err := r.Update(ctx, deployment); err != nil {
			return err
		}

		now := metav1.Now()
		channel.Status.LastScaleTime = &now
		channel.Status.Phase = pubsubv1.ChannelPhaseScaling

		r.Recorder.Eventf(channel, corev1.EventTypeNormal, "Scaled",
			"Scaled from %d to %d replicas (queue depth: %d)", currentReplicas, newReplicas, queueDepth)
	}

	return nil
}

func (r *PubSubChannelReconciler) reconcileDelete(ctx context.Context, channel *pubsubv1.PubSubChannel) (ctrl.Result, error) {
	logger := log.FromContext(ctx)
	logger.Info("Reconciling delete", "name", channel.Name)

	channel.Status.Phase = pubsubv1.ChannelPhaseDeleting
	if err := r.Status().Update(ctx, channel); err != nil {
		return ctrl.Result{}, err
	}

	// Remove finalizer
	controllerutil.RemoveFinalizer(channel, "pubsubchannel.finalizers.pubsub.jawaracloud.io")
	if err := r.Update(ctx, channel); err != nil {
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}

func (r *PubSubChannelReconciler) updateStatus(ctx context.Context, channel *pubsubv1.PubSubChannel) error {
	// Get deployment to check replicas
	deployment := &appsv1.Deployment{}
	deploymentName := fmt.Sprintf("%s-subscriber", channel.Name)

	if err := r.Get(ctx, types.NamespacedName{
		Name:      deploymentName,
		Namespace: channel.Namespace,
	}, deployment); err != nil {
		if !errors.IsNotFound(err) {
			return err
		}
	} else {
		if deployment.Spec.Replicas != nil {
			channel.Status.Replicas = *deployment.Spec.Replicas
		}
		channel.Status.ReadyReplicas = deployment.Status.ReadyReplicas
	}

	// Simulate queue depth and message rate (in real implementation, this would come from metrics)
	// For demo purposes, we'll use placeholder values
	if channel.Status.QueueDepth == 0 {
		channel.Status.QueueDepth = int64(channel.Status.Replicas) * 50 // Simulated
	}
	if channel.Status.MessageRate == 0 {
		channel.Status.MessageRate = float64(channel.Status.Replicas) * 10.5 // Simulated
	}

	// Update phase
	if channel.Status.ReadyReplicas == channel.Status.Replicas && channel.Status.Replicas > 0 {
		if channel.Status.Phase != pubsubv1.ChannelPhaseScaling {
			channel.Status.Phase = pubsubv1.ChannelPhaseRunning
		}
	}

	channel.Status.ObservedGeneration = channel.Generation

	return r.Status().Update(ctx, channel)
}

func (r *PubSubChannelReconciler) updateCondition(ctx context.Context, channel *pubsubv1.PubSubChannel, conditionType pubsubv1.ConditionType, status pubsubv1.ConditionStatus, reason, message string) {
	now := metav1.Now()

	// Find existing condition
	for i := range channel.Status.Conditions {
		if channel.Status.Conditions[i].Type == conditionType {
			channel.Status.Conditions[i].Status = status
			channel.Status.Conditions[i].Reason = reason
			channel.Status.Conditions[i].Message = message
			channel.Status.Conditions[i].LastTransitionTime = now
			return
		}
	}

	// Add new condition
	channel.Status.Conditions = append(channel.Status.Conditions, pubsubv1.Condition{
		Type:               conditionType,
		Status:             status,
		Reason:             reason,
		Message:            message,
		LastTransitionTime: now,
	})
}

func (r *PubSubChannelReconciler) buildEnvVars(channel *pubsubv1.PubSubChannel) []corev1.EnvVar {
	env := []corev1.EnvVar{
		{
			Name:  "REDIS_ADDR",
			Value: channel.Spec.RedisAddress,
		},
		{
			Name:  "CHANNEL",
			Value: channel.Spec.ChannelName,
		},
		{
			Name:  "MESSAGE_TIMEOUT",
			Value: fmt.Sprintf("%d", channel.Spec.MessageTimeout),
		},
	}

	// Add custom env vars
	for _, e := range channel.Spec.Env {
		env = append(env, corev1.EnvVar{
			Name:  e.Name,
			Value: e.Value,
		})
	}

	return env
}

func (r *PubSubChannelReconciler) buildResourceRequirements(channel *pubsubv1.PubSubChannel) corev1.ResourceRequirements {
	if channel.Spec.Resources == nil {
		return corev1.ResourceRequirements{}
	}

	resources := corev1.ResourceRequirements{}

	if channel.Spec.Resources.Limits != nil {
		resources.Limits = make(corev1.ResourceList)
		for k, v := range channel.Spec.Resources.Limits {
			resources.Limits[corev1.ResourceName(k)] = mustParseQuantity(v)
		}
	}

	if channel.Spec.Resources.Requests != nil {
		resources.Requests = make(corev1.ResourceList)
		for k, v := range channel.Spec.Resources.Requests {
			resources.Requests[corev1.ResourceName(k)] = mustParseQuantity(v)
		}
	}

	return resources
}

func mustParseQuantity(s string) resource.Quantity {
	q, err := resource.ParseQuantity(s)
	if err != nil {
		return resource.Quantity{}
	}
	return q
}

// SetupWithManager sets up the controller with the Manager.
func (r *PubSubChannelReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&pubsubv1.PubSubChannel{}).
		Owns(&appsv1.Deployment{}).
		Complete(r)
}
