package main

import (
	"encoding/json"
	"encoding/xml"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"time"
)

const Version = "0.1.0"

// RSS feed structures
type RSS struct {
	Channel Channel `xml:"channel"`
}

type Channel struct {
	Items []Item `xml:"item"`
}

type Item struct {
	Title string `xml:"title"`
	Link  string `xml:"link"`
}

type healthResponse struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}

func main() {
	domain := flag.String("domain", "", "Domain to verify (e.g. stage.eastbayforeveryone.org)")
	version := flag.Bool("version", false, "Print version and exit")
	flag.Parse()

	if *version {
		fmt.Fprintf(os.Stdout, "verify-deploy version %s\n", Version)
		os.Exit(0)
	}

	if *domain == "" {
		slog.Error("--domain is required")
		flag.Usage()
		os.Exit(1)
	}

	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	ok := true

	// Check homepage
	if !checkHomepage(client, *domain) {
		ok = false
	}

	// Check RSS feed and article URLs
	if !checkFeed(client, *domain) {
		ok = false
	}

	// Check database read/write via healthcheck endpoint
	if !checkHealth(client, *domain) {
		ok = false
	}

	if ok {
		slog.Info("all checks passed", "domain", *domain)
	} else {
		slog.Error("some checks failed", "domain", *domain)
		os.Exit(1)
	}
}

func checkHomepage(client *http.Client, domain string) bool {
	url := "https://" + domain + "/"
	slog.Info("checking homepage", "url", url)

	resp, err := client.Get(url)
	if err != nil {
		slog.Error("homepage request failed", "url", url, "error", err)
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		slog.Error("homepage returned non-200 status", "url", url, "status", resp.StatusCode)
		return false
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		slog.Error("failed to read homepage body", "url", url, "error", err)
		return false
	}

	bodyStr := string(body)
	if !strings.Contains(bodyStr, "<html") {
		slog.Error("homepage does not contain <html tag", "url", url)
		return false
	}
	if !strings.Contains(bodyStr, "East Bay for Everyone") {
		slog.Error("homepage does not contain expected content 'East Bay for Everyone'", "url", url)
		return false
	}

	slog.Info("homepage OK", "url", url, "status", resp.StatusCode)
	return true
}

func checkFeed(client *http.Client, domain string) bool {
	feedURL := "https://" + domain + "/feed/"
	slog.Info("checking RSS feed", "url", feedURL)

	resp, err := client.Get(feedURL)
	if err != nil {
		slog.Error("feed request failed", "url", feedURL, "error", err)
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		slog.Error("feed returned non-200 status", "url", feedURL, "status", resp.StatusCode)
		return false
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		slog.Error("failed to read feed body", "url", feedURL, "error", err)
		return false
	}

	var rss RSS
	if err := xml.Unmarshal(body, &rss); err != nil {
		slog.Error("failed to parse RSS XML", "url", feedURL, "error", err)
		return false
	}

	items := rss.Channel.Items
	if len(items) == 0 {
		slog.Error("RSS feed has no items", "url", feedURL)
		return false
	}

	slog.Info("RSS feed parsed", "url", feedURL, "itemCount", len(items))

	// Check first 3 article URLs
	checkCount := min(3, len(items))

	allOK := true
	for i := range checkCount {
		if !checkArticle(client, items[i]) {
			allOK = false
		}
	}

	return allOK
}

func checkArticle(client *http.Client, item Item) bool {
	slog.Info("checking article", "title", item.Title, "url", item.Link)

	resp, err := client.Get(item.Link)
	if err != nil {
		slog.Error("article request failed", "title", item.Title, "url", item.Link, "error", err)
		return false
	}
	defer resp.Body.Close()
	// Drain body so the connection can be reused
	io.Copy(io.Discard, resp.Body)

	if resp.StatusCode != http.StatusOK {
		slog.Error("article returned non-200 status", "title", item.Title, "url", item.Link, "status", resp.StatusCode)
		return false
	}

	slog.Info("article OK", "title", item.Title, "url", item.Link, "status", resp.StatusCode)
	return true
}

func checkHealth(client *http.Client, domain string) bool {
	healthURL := "https://" + domain + "/healthcheck.php"
	slog.Info("checking database health", "url", healthURL)

	resp, err := client.Get(healthURL)
	if err != nil {
		slog.Error("healthcheck request failed", "url", healthURL, "error", err)
		return false
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		slog.Error("failed to read healthcheck body", "url", healthURL, "error", err)
		return false
	}

	if resp.StatusCode != http.StatusOK {
		slog.Error("healthcheck returned non-200 status", "url", healthURL, "status", resp.StatusCode, "body", string(body))
		return false
	}

	var hr healthResponse
	if err := json.Unmarshal(body, &hr); err != nil {
		slog.Error("failed to parse healthcheck JSON", "url", healthURL, "error", err, "body", string(body))
		return false
	}

	if hr.Status != "ok" {
		slog.Error("healthcheck reported failure", "url", healthURL, "status", hr.Status, "message", hr.Message)
		return false
	}

	slog.Info("database health OK (read/write verified)", "url", healthURL)
	return true
}
