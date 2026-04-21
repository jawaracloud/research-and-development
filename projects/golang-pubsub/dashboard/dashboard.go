package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/redis/go-redis/v9"
)

// Message represents the data structure from pub/sub
type Message struct {
	ID        string    `json:"id"`
	Content   string    `json:"content"`
	Timestamp time.Time `json:"timestamp"`
}

// DashboardMessage wraps a message with metadata
type DashboardMessage struct {
	Message  Message
	Received time.Time
	Latency  time.Duration
}

// Model represents the application state
type model struct {
	client       *redis.Client
	ctx          context.Context
	cancel       context.CancelFunc
	messages     []DashboardMessage
	msgChan      chan DashboardMessage
	spinner      spinner.Model
	connected    bool
	connecting   bool
	channel      string
	redisAddr    string
	messageCount int64
	totalLatency time.Duration
	avgLatency   time.Duration
	msgRate      float64
	lastMsgTime  time.Time
	viewport     int
	width        int
	height       int
	quitting     bool
	filter       string
	showHelp     bool
}

// Custom messages for Bubble Tea
type (
	connectMsg struct {
		success bool
		err     error
	}
	receiveMsg DashboardMessage
	tickMsg    time.Time
)

// Styling with beautiful color palette
var (
	// Title with gradient effect simulation
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#FF6B9D")).
			Background(lipgloss.Color("#1a1a2e")).
			Padding(0, 2).
			MarginBottom(1).
			BorderStyle(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#FF6B9D"))

	// Box styling for panels
	boxStyle = lipgloss.NewStyle().
			BorderStyle(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#4ECDC4")).
			Padding(1, 2)

	// Metric value styling
	metricValueStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(lipgloss.Color("#FFE66D")).
				Padding(0, 1)

	// Metric label styling
	metricLabelStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#95A5A6")).
				Padding(0, 1)

	// Message content
	messageStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#ECF0F1"))

	// Timestamp
	timestampStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#7F8C8D"))

	// ID styling
	idStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("#9B59B6")).
		Bold(true)

	// Latency styling
	latencyStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#3498DB"))

	// Connected status
	connectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#2ECC71")).
			Bold(true).
			SetString(" ● CONNECTED ")

	// Disconnected status
	disconnectedStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#E74C3C")).
				Bold(true).
				SetString(" ● DISCONNECTED ")

	// Connecting status
	connectingStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#F39C12")).
			Bold(true).
			SetString(" ● CONNECTING... ")

	// Help text
	helpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#BDC3C7")).
			Italic(true)

	// Header row styling
	headerStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#4ECDC4")).
			Underline(true)

	// Scrollbar indicator
	scrollIndicatorStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#E67E22"))
)

func initialModel() model {
	// Get configuration from environment
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	channel := os.Getenv("CHANNEL")
	if channel == "" {
		channel = "messages"
	}

	ctx, cancel := context.WithCancel(context.Background())

	// Initialize spinner with cool animation
	s := spinner.New()
	s.Spinner = spinner.Meter
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("#4ECDC4"))

	return model{
		ctx:        ctx,
		cancel:     cancel,
		channel:    channel,
		redisAddr:  redisAddr,
		spinner:    s,
		connected:  false,
		connecting: false,
		messages:   make([]DashboardMessage, 0, 100),
		msgChan:    make(chan DashboardMessage, 100),
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		m.connectCmd(),
		m.spinner.Tick,
		tickCmd(),
		m.receiveCmd(),
	)
}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second/2, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func (m model) connectCmd() tea.Cmd {
	return func() tea.Msg {
		m.connecting = true

		m.client = redis.NewClient(&redis.Options{
			Addr:     m.redisAddr,
			Password: "",
			DB:       0,
		})

		// Test connection
		_, err := m.client.Ping(m.ctx).Result()
		if err != nil {
			return connectMsg{success: false, err: err}
		}

		// Start subscriber in background
		go m.subscribe()

		return connectMsg{success: true}
	}
}

func (m *model) subscribe() {
	pubsub := m.client.Subscribe(m.ctx, m.channel)
	defer pubsub.Close()

	ch := pubsub.Channel()

	for {
		select {
		case <-m.ctx.Done():
			return
		case msg := <-ch:
			var message Message
			if err := json.Unmarshal([]byte(msg.Payload), &message); err != nil {
				continue
			}

			received := time.Now()
			latency := received.Sub(message.Timestamp)

			dm := DashboardMessage{
				Message:  message,
				Received: received,
				Latency:  latency,
			}

			// Send to channel (non-blocking)
			select {
			case m.msgChan <- dm:
			default:
				// Channel full, drop oldest
			}
		}
	}
}

func (m model) receiveCmd() tea.Cmd {
	return func() tea.Msg {
		select {
		case msg := <-m.msgChan:
			return receiveMsg(msg)
		case <-m.ctx.Done():
			return nil
		}
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.quitting = true
			m.cancel()
			if m.client != nil {
				m.client.Close()
			}
			return m, tea.Quit

		case "h", "?":
			m.showHelp = !m.showHelp

		case "up", "k":
			if m.viewport > 0 {
				m.viewport--
			}

		case "down", "j":
			maxViewport := len(m.messages) - m.height + 20
			if maxViewport < 0 {
				maxViewport = 0
			}
			if m.viewport < maxViewport {
				m.viewport++
			}

		case "home", "g":
			m.viewport = 0

		case "end", "G":
			m.viewport = len(m.messages) - m.height + 20
			if m.viewport < 0 {
				m.viewport = 0
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case connectMsg:
		m.connecting = false
		m.connected = msg.success
		if !msg.success {
			// Retry connection after delay
			return m, tea.Tick(time.Second*3, func(time.Time) tea.Msg {
				return connectMsg{}
			})
		}
		return m, nil

	case receiveMsg:
		dm := DashboardMessage(msg)

		// Add to beginning (newest first)
		m.messages = append([]DashboardMessage{dm}, m.messages...)

		// Keep only last 100 messages
		if len(m.messages) > 100 {
			m.messages = m.messages[:100]
		}

		m.messageCount++
		m.totalLatency += dm.Latency
		m.avgLatency = m.totalLatency / time.Duration(m.messageCount)

		// Calculate message rate (messages per second)
		now := time.Now()
		if !m.lastMsgTime.IsZero() {
			interval := now.Sub(m.lastMsgTime).Seconds()
			if interval > 0 {
				// Smooth rate with exponential moving average
				instantRate := 1.0 / interval
				m.msgRate = 0.7*m.msgRate + 0.3*instantRate
			}
		}
		m.lastMsgTime = now

		return m, m.receiveCmd()

	case tickMsg:
		return m, tickCmd()
	}

	return m, nil
}

func (m model) View() string {
	if m.showHelp {
		return m.helpView()
	}

	var s strings.Builder

	// Title banner
	title := titleStyle.Render(" 🐲 DragonFlyDB Pub/Sub Dashboard ")
	s.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center, title))
	s.WriteString("\n\n")

	// Connection status bar
	statusBar := m.renderStatusBar()
	s.WriteString(statusBar)
	s.WriteString("\n")

	// Metrics row
	metrics := m.renderMetrics()
	s.WriteString(metrics)
	s.WriteString("\n")

	// Messages panel with header
	messages := m.renderMessages()
	s.WriteString(messages)
	s.WriteString("\n")

	// Footer with controls
	footer := m.renderFooter()
	s.WriteString(footer)

	return s.String()
}

func (m model) renderStatusBar() string {
	var status string
	if m.connecting {
		status = fmt.Sprintf("%s %s", connectingStyle.String(), m.spinner.View())
	} else if m.connected {
		status = connectedStyle.String()
	} else {
		status = disconnectedStyle.String()
	}

	info := fmt.Sprintf(" %s | Channel: %s | Messages: %d",
		m.redisAddr,
		m.channel,
		m.messageCount)

	content := fmt.Sprintf("%s%s", status, metricLabelStyle.Render(info))

	return boxStyle.Width(m.width - 4).Render(content)
}

func (m model) renderMetrics() string {
	// Messages count box
	countBox := lipgloss.JoinVertical(lipgloss.Center,
		metricLabelStyle.Render("Total Messages"),
		metricValueStyle.Render(fmt.Sprintf("%d", m.messageCount)),
	)

	// Average latency box
	var latencyStr string
	if m.avgLatency > 0 {
		latencyStr = fmt.Sprintf("%v", m.avgLatency.Round(time.Microsecond))
	} else {
		latencyStr = "-"
	}
	latencyBox := lipgloss.JoinVertical(lipgloss.Center,
		metricLabelStyle.Render("Avg Latency"),
		metricValueStyle.Render(latencyStr),
	)

	// Message rate box
	var rateStr string
	if m.msgRate > 0 {
		rateStr = fmt.Sprintf("%.1f msg/s", m.msgRate)
	} else {
		rateStr = "-"
	}
	rateBox := lipgloss.JoinVertical(lipgloss.Center,
		metricLabelStyle.Render("Current Rate"),
		metricValueStyle.Render(rateStr),
	)

	// Memory box (simulated - in real app would query actual memory)
	memBox := lipgloss.JoinVertical(lipgloss.Center,
		metricLabelStyle.Render("Queue Depth"),
		metricValueStyle.Render(fmt.Sprintf("%d", len(m.messages))),
	)

	metrics := lipgloss.JoinHorizontal(lipgloss.Top,
		boxStyle.Width(m.width/4-2).Render(countBox),
		boxStyle.Width(m.width/4-2).Render(latencyBox),
		boxStyle.Width(m.width/4-2).Render(rateBox),
		boxStyle.Width(m.width/4-2).Render(memBox),
	)

	return metrics
}

func (m model) renderMessages() string {
	var msgList strings.Builder

	// Calculate visible range
	maxVisible := m.height - 18
	if maxVisible < 5 {
		maxVisible = 5
	}

	start := m.viewport

	// Header
	header := lipgloss.JoinHorizontal(lipgloss.Top,
		headerStyle.Width(12).Render("Time"),
		headerStyle.Width(10).Render("ID"),
		headerStyle.Width(m.width-55).Render("Content"),
		headerStyle.Width(12).Render("Latency"),
		headerStyle.Width(19).Render("Timestamp"),
	)
	msgList.WriteString(header)
	msgList.WriteString("\n")
	msgList.WriteString(strings.Repeat("─", m.width-8))
	msgList.WriteString("\n")

	// Messages
	visibleCount := 0
	for i := start; i < len(m.messages) && visibleCount < maxVisible; i++ {
		msg := m.messages[i]

		timeStr := msg.Received.Format("15:04:05")
		idStr := truncateMiddle(msg.Message.ID, 8)
		content := truncate(msg.Message.Content, m.width-58)
		latency := msg.Latency.Round(time.Microsecond).String()
		originalTime := msg.Message.Timestamp.Format("15:04:05")

		line := lipgloss.JoinHorizontal(lipgloss.Top,
			timestampStyle.Width(12).Render(timeStr),
			idStyle.Width(10).Render(idStr),
			messageStyle.Width(m.width-55).Render(content),
			latencyStyle.Width(12).Render(latency),
			timestampStyle.Width(19).Render(originalTime),
		)

		msgList.WriteString(line)
		msgList.WriteString("\n")
		visibleCount++
	}

	// Fill empty rows to keep consistent height
	for visibleCount < maxVisible {
		msgList.WriteString("\n")
		visibleCount++
	}

	// Scroll indicator
	if len(m.messages) > maxVisible {
		scrollInfo := fmt.Sprintf(" %d/%d ", m.viewport+1, len(m.messages))
		indicator := scrollIndicatorStyle.Render(scrollInfo)
		msgList.WriteString("\n")
		msgList.WriteString(lipgloss.PlaceHorizontal(m.width-8, lipgloss.Right, indicator))
	}

	return boxStyle.Width(m.width - 4).Render(msgList.String())
}

func (m model) renderFooter() string {
	controls := []string{
		"? help",
		"q quit",
		"↑/k up",
		"↓/j down",
		"home/g top",
		"end/G bottom",
	}

	footer := helpStyle.Render(strings.Join(controls, " • "))
	return lipgloss.PlaceHorizontal(m.width, lipgloss.Center, footer)
}

func (m model) helpView() string {
	help := fmt.Sprintf(`
%s

%s

    q, ctrl+c    Quit the dashboard
    ↑, k         Scroll up in message list
    ↓, j         Scroll down in message list
    home, g      Jump to top of messages
    end, G       Jump to bottom of messages
    h, ?         Toggle this help screen

%s

    DragonFlyDB Pub/Sub Dashboard v1.0
    Real-time message stream visualization
    
    Environment Variables:
      REDIS_ADDR    DragonFlyDB address (default: localhost:6379)
      CHANNEL       Pub/sub channel name (default: messages)

%s
`,
		headerStyle.Render("Keyboard Shortcuts"),
		metricLabelStyle.Render("Navigation"),
		metricLabelStyle.Render("About"),
		helpStyle.Render("Press any key to return..."),
	)

	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, boxStyle.Render(help))
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}

func truncateMiddle(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	half := (maxLen - 3) / 2
	return s[:half] + "..." + s[len(s)-half:]
}

func main() {
	// Clear screen and print welcome
	fmt.Print("\033[H\033[2J")
	fmt.Println("🐲 DragonFlyDB Pub/Sub Dashboard")
	fmt.Println()
	fmt.Println("Connecting to DragonFlyDB...")
	fmt.Println()

	// Small delay for dramatic effect
	time.Sleep(500 * time.Millisecond)

	p := tea.NewProgram(initialModel(),
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}
