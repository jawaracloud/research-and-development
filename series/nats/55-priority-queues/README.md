# 55 — Priority Queues

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

NATS doesn't natively support message prioritisation, but this lesson shows three patterns for implementing priority queues on top of NATS JetStream.

## Pattern 1: Separate Streams per Priority

```go
// Create 3 priority streams
for _, priority := range []string{"high", "normal", "low"} {
    js.AddStream(&nats.StreamConfig{
        Name:     "TASKS-" + strings.ToUpper(priority),
        Subjects: []string{"tasks." + priority + ".>"},
    })
}

// Publisher — route based on priority
func publishTask(js nats.JetStreamContext, task Task, priority string) {
    subject := fmt.Sprintf("tasks.%s.%s", priority, task.Type)
    js.Publish(subject, mustJSON(task))
}

// Consumer — drain high → normal → low
func priorityConsumer(js nats.JetStreamContext) {
    streams := []string{"TASKS-HIGH", "TASKS-NORMAL", "TASKS-LOW"}
    subs := make([]*nats.Subscription, len(streams))
    for i, s := range streams {
        subs[i], _ = js.PullSubscribe(">", "priority-worker-"+strconv.Itoa(i),
            nats.BindStream(s))
    }

    for {
        for _, sub := range subs {
            msgs, _ := sub.FetchNoWait(10)
            if len(msgs) > 0 {
                for _, msg := range msgs {
                    process(msg)
                    msg.Ack()
                }
                // Break after processing highest available priority
                break
            }
        }
        time.Sleep(10 * time.Millisecond)
    }
}
```

## Pattern 2: Priority Header + Consumer Sorting

```go
// Publisher sets priority header
func publishWithPriority(js nats.JetStreamContext, task Task, priority int) {
    msg := &nats.Msg{
        Subject: "tasks.all",
        Data:    mustJSON(task),
        Header:  nats.Header{},
    }
    msg.Header.Set("X-Priority", strconv.Itoa(priority))
    js.PublishMsg(msg)
}

// Consumer sorts local buffer by priority
func prioritySortingConsumer(js nats.JetStreamContext) {
    sub, _ := js.PullSubscribe("tasks.all", "sorter")

    for {
        msgs, _ := sub.Fetch(100, nats.MaxWait(time.Second))

        // Sort by priority header
        sort.Slice(msgs, func(i, j int) bool {
            pi, _ := strconv.Atoi(msgs[i].Header.Get("X-Priority"))
            pj, _ := strconv.Atoi(msgs[j].Header.Get("X-Priority"))
            return pi > pj  // higher = higher priority
        })

        for _, msg := range msgs {
            process(msg)
            msg.Ack()
        }
    }
}
```

## Pattern 3: Multi-Subject Consumer with Priority

```go
// Publish to priority-specific subjects
js.Publish("tasks.urgent", data)
js.Publish("tasks.normal", data)

// One consumer, check urgent first
urgentSub, _ := js.PullSubscribe("tasks.urgent", "worker-urgent")
normalSub, _ := js.PullSubscribe("tasks.normal", "worker-normal")

for {
    msgs, _ := urgentSub.FetchNoWait(10)
    if len(msgs) == 0 {
        msgs, _ = normalSub.FetchNoWait(10)
    }
    for _, msg := range msgs {
        process(msg); msg.Ack()
    }
}
```

---
*Part of the 100-Lesson NATS Series.*
