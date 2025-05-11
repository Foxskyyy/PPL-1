package utils

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type OllamaRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
}

type OllamaResponse struct {
	Response string `json:"response"`
	Done     bool   `json:"done"`
}

func cleanResponse(input string) string {

	endTag := "\u003c/think\u003e\n\n"
	endIndex := strings.Index(input, endTag)

	if endIndex != -1 {
		return input[endIndex+len(endTag):]
	}
	return ""
}

func AnalyzeUsageData(input string) (string, error) {

	godotenv.Load()

	host := os.Getenv("OLLAMA_HOST")
	port := os.Getenv("OLLAMA_PORT")
	if host == "" {
		host = "localhost"
	}
	if port == "" {
		port = "11434"
	}

	url := fmt.Sprintf("http://%s:%s/api/generate", host, port)

	requestBody, _ := json.Marshal(OllamaRequest{
		Model:  "deepseek-r1:8b",
		Prompt: "Analyze the water usage data extracted from the provided database and deliver detailed insights. Begin by summarizing the key statistics such as total consumption, average daily usage, peak usage periods, and any noticeable trends over time. Then, identify patterns or anomalies, and provide actionable recommendations for optimizing water usage based on the analyzed data. # Steps 1. Review the water usage data from the database. 2. Calculate total, average, and peak usage metrics. 3. Detect trends, seasonal variances, or irregularities. 4. Generate insights that help understand usage behavior. 5. Suggest practical recommendations to improve water efficiency. # Output Format Provide a comprehensive analytical report in clear, structured paragraphs including: - Summary statistics with numeric details - Interpretations of patterns and anomalies - Practical recommendations or possible actions Use clear language suitable for stakeholders without technical expertise. " + input})

	resp, err := http.Post(url, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("error calling DeepSeek API: %v", err)
	}
	defer resp.Body.Close()

	scanner := bufio.NewScanner(resp.Body)
	var finalResponse string

	for scanner.Scan() {
		line := scanner.Text()

		var response OllamaResponse
		err := json.Unmarshal([]byte(line), &response)
		if err != nil {
			return "", fmt.Errorf("error parsing Ollama response: %v. Raw line: %s", err, line)
		}

		finalResponse += response.Response

		if response.Done {
			break
		}
	}

	if err := scanner.Err(); err != nil {
		return "", fmt.Errorf("error reading Ollama response: %v", err)
	}

	finalResponse = cleanResponse(finalResponse)

	return finalResponse, nil
}
