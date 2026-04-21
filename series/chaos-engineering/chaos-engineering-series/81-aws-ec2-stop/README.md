# 81 — AWS EC2 Stop

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Use LitmusChaos's AWS experiment to stop an EC2 instance, simulating an unplanned compute failure in a cloud production environment.

> **Prerequisites:** AWS account, EKS cluster or EC2-backed K8s nodes, LitmusChaos with AWS secrets configured.

## Step 1: Create AWS credentials secret

```bash
kubectl create secret generic aws-credentials \
  --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  --from-literal=AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \
  -n litmus
```

## Step 2: Install EC2 stop experiment

```bash
kubectl apply -f \
  "https://hub.litmuschaos.io/api/chaos/3.9.0?item=aws/ec2-stop-by-id" \
  -n litmus
```

## Step 3: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: ec2-stop-engine
  namespace: litmus
spec:
  engineState: active
  chaosServiceAccount: litmus-admin
  experiments:
    - name: ec2-stop-by-id
      spec:
        components:
          env:
            - name: EC2_INSTANCE_ID
              value: "i-0abcdef1234567890"   # your staging instance
            - name: REGION
              value: "ap-southeast-1"
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: AWS_SHARED_CREDENTIALS_FILE
              value: "/tmp/cloud_config.yml"
          secrets:
            - name: aws-credentials
              mountPath: /tmp/
        probe:
          - name: service-availability
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "10s"
              retry: 5
              interval: "5s"
            httpProbe/inputs:
              url: "https://your-app.example.com/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 4: Verify cloud-provider metrics

```bash
# AWS CLI — watch instance state
aws ec2 describe-instances \
  --instance-ids i-0abcdef1234567890 \
  --query 'Reservations[].Instances[].State.Name' \
  --output text --region ap-southeast-1

# Output during chaos:
# stopping
# stopped
# (after experiment ends)
# pending
# running
```

## What this experiment validates

- **Auto Scaling Group**: does it launch a replacement instance automatically?
- **Load balancer health checks**: is the stopped instance removed from rotation?
- **Application tier**: can it serve traffic with one fewer EC2 node?
- **Recovery time**: how long until the ASG replaces the instance?

## Multi-AZ resilience test

```yaml
env:
  - name: EC2_INSTANCE_ID
    value: "i-zone-a-001,i-zone-b-001"  # stop one per AZ
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
