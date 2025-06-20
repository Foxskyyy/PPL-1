package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

type OpenRouterRequest struct {
	Model    string              `json:"model"`
	Messages []OpenRouterMessage `json:"messages"`
	Stream   bool                `json:"stream"`
}

type OpenRouterMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenRouterResponse struct {
	Choices []struct {
		Delta struct {
			Content string `json:"content"`
		} `json:"delta"`
		FinishReason string `json:"finish_reason"`
	} `json:"choices"`
}

func AnalyzeUsageData(input string) (string, error) {
	godotenv.Load()

	apiKey := os.Getenv("OPENROUTER_SECRET")
	if apiKey == "" {
		return "", fmt.Errorf("OPENROUTER_SECRET environment variable not set")
	}

	url := "https://openrouter.ai/api/v1/chat/completions"

	prompt := `Buat laporan penggunaan air dalam 3 kalimat (termasuk: total konsumsi, rata-rata harian, puncak pemakaian, pola/anomali, dan saran efisiensi). Gunakan satuan liter dan bahasa sehari-hari. Jika tidak ada data yang diambil (tidak ada penggunaan water usage) jangan pernah memberikan contoh data penggunaan.` + input

	requestBody, _ := json.Marshal(OpenRouterRequest{
		Model: "deepseek/deepseek-chat-v3-0324:free",
		Messages: []OpenRouterMessage{
			{Role: "user", Content: prompt},
		},
		Stream: false,
	})

	client := &http.Client{}
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("error creating request: %v", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("HTTP-Referer", "https://api.interphaselabs.com")
	req.Header.Set("X-Title", "Water Usage Analyzer")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("error calling OpenRouter API: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("openrouter API error [%d]: %s", resp.StatusCode, body)
	}

	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("error reading response body: %v", err)
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("error unmarshalling OpenRouter response: %v", err)
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("no response choices received")
	}

	finalStr := result.Choices[0].Message.Content

	return finalStr, nil
}
